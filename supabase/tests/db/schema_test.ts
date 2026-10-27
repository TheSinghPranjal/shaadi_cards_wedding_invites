import {
  assert,
  assertEquals,
  assertRejects,
} from "jsr:@std/assert@1";
import { as, createTestDb, createUser, profile } from "./harness.ts";

const db = await createTestDb();

const spend = (u: string, ref: string, mode = "free_first", reason = "generation") =>
  db.query<{ was_free: boolean; balance: number }>(
    "select * from public.spend_credit($1, $2, $3, $4)",
    [u, ref, reason, mode],
  ).then((r) => r.rows[0]);

const refund = (u: string, ref: string, reason = "generation") =>
  db.query<{ refund_credit: number }>(
    "select public.refund_credit($1, $2, $3)",
    [u, ref, reason],
  ).then((r) => r.rows[0].refund_credit);

const grant = (u: string, amount: number, reason: string, ref: string, isFree = false) =>
  db.query<{ grant_credits: number }>(
    "select public.grant_credits($1, $2, $3, $4, $5)",
    [u, amount, reason, ref, isFree],
  ).then((r) => r.rows[0].grant_credits);

Deno.test("signing up creates an empty profile", async () => {
  const u = await createUser(db);
  assertEquals(await profile(db, u), {
    credits: 0,
    free_credits: 0,
    has_purchased: false,
    free_credits_granted: false,
  });
});

Deno.test("free trial grant is idempotent per ref", async () => {
  const u = await createUser(db);
  assertEquals(await grant(u, 2, "free_trial", u, true), 2);
  assertEquals(await grant(u, 2, "free_trial", u, true), 2);
  const p = await profile(db, u);
  assertEquals([p.credits, p.free_credits, p.free_credits_granted], [2, 2, true]);
});

Deno.test("purchase grant is idempotent per event id and sets has_purchased", async () => {
  const u = await createUser(db);
  assertEquals(await grant(u, 5, "purchase", "evt_1"), 5);
  assertEquals(await grant(u, 5, "purchase", "evt_1"), 5);
  assertEquals(await grant(u, 15, "purchase", "evt_2"), 20);
  const p = await profile(db, u);
  assertEquals([p.credits, p.free_credits, p.has_purchased], [20, 0, true]);
});

Deno.test("free_first spends free credits before paid", async () => {
  const u = await createUser(db);
  await grant(u, 2, "free_trial", u, true);
  await grant(u, 5, "purchase", `evt_${u}`);
  const r = await spend(u, crypto.randomUUID());
  assertEquals(r, { was_free: true, balance: 6 });
  assertEquals((await profile(db, u)).free_credits, 1);
});

Deno.test("paid_first spends paid, then falls back to free", async () => {
  const u = await createUser(db);
  await grant(u, 1, "free_trial", u, true);
  await grant(u, 1, "purchase", `evt_${u}`);
  assertEquals((await spend(u, crypto.randomUUID(), "paid_first")).was_free, false);
  assertEquals((await spend(u, crypto.randomUUID(), "paid_first")).was_free, true);
});

Deno.test("paid_only refuses free credits (used by unlock-hd)", async () => {
  const u = await createUser(db);
  await grant(u, 2, "free_trial", u, true);
  await assertRejects(
    () => spend(u, crypto.randomUUID(), "paid_only", "hd_unlock"),
    Error,
    "insufficient_credits",
  );
});

Deno.test("spending with zero balance fails and leaves balance untouched", async () => {
  const u = await createUser(db);
  await assertRejects(() => spend(u, crypto.randomUUID()), Error, "insufficient_credits");
  assertEquals((await profile(db, u)).credits, 0);
});

Deno.test("the same generation can only be charged once", async () => {
  const u = await createUser(db);
  await grant(u, 5, "purchase", `evt_${u}`);
  const gen = crypto.randomUUID();
  await spend(u, gen);
  await assertRejects(() => spend(u, gen), Error, "already_spent");
  assertEquals((await profile(db, u)).credits, 4);
});

Deno.test("refund restores the same kind of credit, exactly once", async () => {
  const u = await createUser(db);
  await grant(u, 1, "free_trial", u, true);
  await grant(u, 1, "purchase", `evt_${u}`);
  const freeGen = crypto.randomUUID();
  const paidGen = crypto.randomUUID();
  await spend(u, freeGen);
  await spend(u, paidGen);
  assertEquals(await profile(db, u).then((p) => [p.credits, p.free_credits]), [0, 0]);

  assertEquals(await refund(u, freeGen), 1);
  assertEquals(await refund(u, freeGen), 1);
  assertEquals((await profile(db, u)).free_credits, 1);

  assertEquals(await refund(u, paidGen), 2);
  assertEquals((await profile(db, u)).free_credits, 1);
});

Deno.test("refunding something never charged is a no-op", async () => {
  const u = await createUser(db);
  assertEquals(await refund(u, crypto.randomUUID()), 0);
});

Deno.test("RLS: users read only their own profile and generations", async () => {
  const a = await createUser(db);
  const b = await createUser(db);
  await db.query(
    "insert into public.generations (user_id, theme_id, status, is_watermarked, input_paths) values ($1,'goa_beach','queued',true,'{}'), ($2,'goa_beach','queued',true,'{}')",
    [a, b],
  );
  await as(db, "authenticated", a, async () => {
    const profiles = await db.query<{ id: string }>("select id from public.profiles");
    assertEquals(profiles.rows.map((r) => r.id), [a]);
    const gens = await db.query<{ user_id: string }>(
      "select user_id from public.generations",
    );
    assertEquals(gens.rows.map((r) => r.user_id), [a]);
  });
  await as(db, "anon", null, async () => {
    assertEquals((await db.query("select id from public.profiles")).rows.length, 0);
  });
});

Deno.test("RLS: clients cannot write credits or call credit functions", async () => {
  const u = await createUser(db);
  await as(db, "authenticated", u, async () => {
    await assertRejects(
      () => db.query("update public.profiles set credits = 999 where id = $1", [u]),
      Error,
      "permission denied",
    );
    await assertRejects(
      () => db.query("insert into public.credit_ledger (user_id, delta, reason, ref) values ($1, 100, 'purchase', 'x')", [u]),
      Error,
      "permission denied",
    );
    await assertRejects(
      () => db.query("select public.grant_credits($1, 100, 'purchase', 'hack')", [u]),
      Error,
      "permission denied",
    );
  });
  assertEquals((await profile(db, u)).credits, 0);
});

Deno.test("service role can call credit functions", async () => {
  const u = await createUser(db);
  await as(db, "service_role", null, async () => {
    assertEquals(await grant(u, 5, "purchase", `svc_${u}`), 5);
    assert((await spend(u, crypto.randomUUID())).balance === 4);
  });
});

Deno.test("storage: users upload only into their own uploads folder", async () => {
  const a = await createUser(db);
  const b = await createUser(db);
  const gen = crypto.randomUUID();
  await as(db, "authenticated", a, async () => {
    await db.query(
      "insert into storage.objects (bucket_id, name) values ('uploads', $1)",
      [`${a}/${gen}/photo_0.jpg`],
    );
    await assertRejects(
      () => db.query("insert into storage.objects (bucket_id, name) values ('uploads', $1)", [`${b}/${gen}/x.jpg`]),
      Error,
      "row-level security",
    );
    await assertRejects(
      () => db.query("insert into storage.objects (bucket_id, name) values ('outputs', $1)", [`${a}/${gen}/0.png`]),
      Error,
      "row-level security",
    );
  });
});

Deno.test("storage: private originals are hidden from the owner", async () => {
  const a = await createUser(db);
  const gen = crypto.randomUUID();
  await db.query(
    "insert into storage.objects (bucket_id, name) values ('outputs', $1), ('outputs', $2)",
    [`${a}/${gen}/0.png`, `${a}/${gen}/original/0.png`],
  );
  await as(db, "authenticated", a, async () => {
    const rows = await db.query<{ name: string }>(
      "select name from storage.objects where bucket_id = 'outputs'",
    );
    assertEquals(rows.rows.map((r) => r.name), [`${a}/${gen}/0.png`]);
  });
});
