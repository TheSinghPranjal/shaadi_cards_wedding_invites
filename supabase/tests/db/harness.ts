// Runs the real migrations against an in-process Postgres (PGlite) with
// minimal stand-ins for the Supabase-managed `auth` and `storage` schemas.
// No Docker or Supabase CLI needed: `deno test -A supabase/tests`.
import { PGlite } from "npm:@electric-sql/pglite@0.3.14";

const SUPABASE_STUBS = `
  create role anon nologin;
  create role authenticated nologin;
  create role service_role nologin bypassrls;
  grant usage on schema public to anon, authenticated, service_role;

  -- Supabase grants broad table/function privileges by default and relies
  -- on RLS + explicit revokes. Mirror that so the revokes are exercised.
  alter default privileges in schema public
    grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public
    grant all on sequences to anon, authenticated, service_role;
  alter default privileges in schema public
    grant execute on functions to anon, authenticated, service_role;

  create schema auth;
  grant usage on schema auth to anon, authenticated, service_role;
  create table auth.users (
    id uuid primary key,
    is_anonymous boolean default true,
    created_at timestamptz default now()
  );
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
  $$;

  create schema storage;
  grant usage on schema storage to anon, authenticated, service_role;
  create table storage.buckets (
    id text primary key,
    name text not null,
    public boolean default false,
    file_size_limit bigint,
    allowed_mime_types text[]
  );
  create table storage.objects (
    id uuid primary key default gen_random_uuid(),
    bucket_id text references storage.buckets(id),
    name text not null,
    created_at timestamptz default now()
  );
  alter table storage.objects enable row level security;
  grant all on storage.objects to anon, authenticated, service_role;
  create function storage.foldername(name text) returns text[]
  language sql immutable as $$
    select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
  $$;

  create publication supabase_realtime;
`;

const migrationsDir = new URL("../../migrations/", import.meta.url);

export async function createTestDb(): Promise<PGlite> {
  const db = new PGlite();
  await db.exec(SUPABASE_STUBS);

  const files = [];
  for await (const entry of Deno.readDir(migrationsDir)) {
    if (entry.isFile && entry.name.endsWith(".sql")) files.push(entry.name);
  }
  files.sort();
  for (const file of files) {
    const sql = await Deno.readTextFile(new URL(file, migrationsDir));
    try {
      await db.exec(sql);
    } catch (e) {
      throw new Error(`Migration ${file} failed: ${(e as Error).message}`);
    }
  }
  return db;
}

export async function createUser(db: PGlite): Promise<string> {
  const id = crypto.randomUUID();
  await db.query("insert into auth.users (id) values ($1)", [id]);
  return id;
}

/** Runs `fn` as the given role, optionally as a signed-in user. */
export async function as<T>(
  db: PGlite,
  role: "anon" | "authenticated" | "service_role",
  userId: string | null,
  fn: () => Promise<T>,
): Promise<T> {
  await db.exec(`set role ${role}`);
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [
    userId ?? "",
  ]);
  try {
    return await fn();
  } finally {
    await db.exec("reset role");
    await db.query("select set_config('request.jwt.claim.sub', '', false)");
  }
}

export async function profile(db: PGlite, userId: string) {
  const res = await db.query<{
    credits: number;
    free_credits: number;
    has_purchased: boolean;
    free_credits_granted: boolean;
  }>(
    "select credits, free_credits, has_purchased, free_credits_granted from public.profiles where id = $1",
    [userId],
  );
  return res.rows[0];
}
