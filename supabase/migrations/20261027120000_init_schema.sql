-- Shaadi Cards: core schema, RLS, credit functions, storage buckets.
-- Clients only ever SELECT their own rows. All writes go through Edge
-- Functions using the service role, or through the SECURITY DEFINER
-- functions below (which are not executable by clients).

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  -- Total spendable balance (free + paid).
  credits int not null default 0 check (credits >= 0),
  -- How many of `credits` are free-trial credits (watermarked output).
  free_credits int not null default 0
    check (free_credits >= 0 and free_credits <= credits),
  free_credits_granted boolean not null default false,
  has_purchased boolean not null default false,
  device_hash text,
  created_at timestamptz default now()
);

create table public.credit_ledger (
  id bigserial primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  delta int not null,
  reason text not null
    check (reason in ('free_trial', 'purchase', 'generation', 'refund', 'hd_unlock')),
  ref text,
  is_free boolean not null default false,
  created_at timestamptz default now(),
  unique (reason, ref)
);
create index credit_ledger_user_idx on public.credit_ledger (user_id, created_at desc);

create table public.device_trials (
  device_hash text primary key,
  user_id uuid,
  created_at timestamptz default now()
);

create table public.generations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  theme_id text not null,
  status text not null
    check (status in ('queued', 'running', 'done', 'failed', 'blocked')),
  is_watermarked boolean not null,
  input_paths text[] not null,
  output_paths text[],
  -- Free results also keep an unwatermarked full-res copy at
  -- outputs/{user_id}/{id}/original/{i}.png (hidden by storage policy) so
  -- unlock-hd never needs a second AI call.
  hd_unlocked boolean not null default false,
  error text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  expires_at timestamptz not null default now() + interval '48 hours'
);
create index generations_user_created_idx on public.generations (user_id, created_at desc);
create index generations_expires_idx on public.generations (expires_at);

create table public.reports (
  id bigserial primary key,
  user_id uuid,
  generation_id uuid,
  image_path text,
  reason text,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.credit_ledger enable row level security;
alter table public.device_trials enable row level security;
alter table public.generations enable row level security;
alter table public.reports enable row level security;

create policy "profiles: read own" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);

create policy "generations: read own" on public.generations
  for select to authenticated using ((select auth.uid()) = user_id);

-- Belt and braces: clients never write these tables directly.
revoke insert, update, delete on public.profiles, public.credit_ledger,
  public.device_trials, public.generations, public.reports
  from anon, authenticated;

-- ---------------------------------------------------------------------------
-- New auth user -> profile row
-- ---------------------------------------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger generations_touch_updated_at
  before update on public.generations
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Credit functions (service role only)
-- ---------------------------------------------------------------------------

-- Spends exactly one credit for `p_ref` (a generation id).
--   p_mode = 'free_first' (default) | 'paid_first' | 'paid_only'
-- Raises 'insufficient_credits' when nothing suitable is left and
-- 'already_spent' when this (reason, ref) pair was already charged.
create function public.spend_credit(
  p_user_id uuid,
  p_ref uuid,
  p_reason text default 'generation',
  p_mode text default 'free_first'
)
returns table (was_free boolean, balance int)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_credits int;
  v_free int;
  v_paid int;
  v_use_free boolean;
begin
  if p_reason not in ('generation', 'hd_unlock') then
    raise exception 'invalid_reason';
  end if;

  select p.credits, p.free_credits into v_credits, v_free
  from public.profiles p where p.id = p_user_id
  for update;

  if not found then
    raise exception 'profile_not_found';
  end if;

  v_paid := v_credits - v_free;

  v_use_free := case p_mode
    when 'free_first' then v_free > 0
    when 'paid_first' then v_paid = 0 and v_free > 0
    when 'paid_only' then false
    else null
  end;

  if v_use_free is null then
    raise exception 'invalid_mode';
  end if;

  if (v_use_free and v_free < 1) or (not v_use_free and v_paid < 1) then
    raise exception 'insufficient_credits';
  end if;

  begin
    insert into public.credit_ledger (user_id, delta, reason, ref, is_free)
    values (p_user_id, -1, p_reason, p_ref::text, v_use_free);
  exception when unique_violation then
    raise exception 'already_spent';
  end;

  update public.profiles p
  set credits = p.credits - 1,
      free_credits = p.free_credits - (case when v_use_free then 1 else 0 end)
  where p.id = p_user_id
  returning p.credits into v_credits;

  return query select v_use_free, v_credits;
end;
$$;

-- Refunds the credit spent for (p_reason, p_ref), restoring the same kind
-- (free or paid). Idempotent; returns the balance after the call.
create function public.refund_credit(
  p_user_id uuid,
  p_ref uuid,
  p_reason text default 'generation'
)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_spent_free boolean;
  v_inserted bigint;
  v_balance int;
begin
  select l.is_free into v_spent_free
  from public.credit_ledger l
  where l.user_id = p_user_id and l.reason = p_reason and l.ref = p_ref::text
    and l.delta < 0;

  if found then
    insert into public.credit_ledger (user_id, delta, reason, ref, is_free)
    values (p_user_id, 1, 'refund', p_reason || ':' || p_ref::text, v_spent_free)
    on conflict (reason, ref) do nothing
    returning id into v_inserted;

    if v_inserted is not null then
      update public.profiles p
      set credits = p.credits + 1,
          free_credits = p.free_credits + (case when v_spent_free then 1 else 0 end)
      where p.id = p_user_id;
    end if;
  end if;

  select p.credits into v_balance from public.profiles p where p.id = p_user_id;
  return v_balance;
end;
$$;

-- Grants credits once per (reason, ref). Returns the resulting balance.
-- A 'purchase' grant also flips has_purchased (unlocks premium templates).
create function public.grant_credits(
  p_user_id uuid,
  p_amount int,
  p_reason text,
  p_ref text,
  p_is_free boolean default false
)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_inserted bigint;
  v_balance int;
begin
  if p_amount <= 0 then
    raise exception 'invalid_amount';
  end if;
  if p_reason not in ('free_trial', 'purchase') then
    raise exception 'invalid_reason';
  end if;

  -- Lock the profile first so concurrent grants serialize.
  perform 1 from public.profiles p where p.id = p_user_id for update;
  if not found then
    raise exception 'profile_not_found';
  end if;

  insert into public.credit_ledger (user_id, delta, reason, ref, is_free)
  values (p_user_id, p_amount, p_reason, p_ref, p_is_free)
  on conflict (reason, ref) do nothing
  returning id into v_inserted;

  if v_inserted is not null then
    update public.profiles p
    set credits = p.credits + p_amount,
        free_credits = p.free_credits + (case when p_is_free then p_amount else 0 end),
        has_purchased = p.has_purchased or p_reason = 'purchase',
        free_credits_granted = p.free_credits_granted or p_reason = 'free_trial'
    where p.id = p_user_id;
  end if;

  select p.credits into v_balance from public.profiles p where p.id = p_user_id;
  return v_balance;
end;
$$;

revoke all on function public.spend_credit(uuid, uuid, text, text) from public, anon, authenticated;
revoke all on function public.refund_credit(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.grant_credits(uuid, int, text, text, boolean) from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.spend_credit(uuid, uuid, text, text) to service_role;
grant execute on function public.refund_credit(uuid, uuid, text) to service_role;
grant execute on function public.grant_credits(uuid, int, text, text, boolean) to service_role;

-- ---------------------------------------------------------------------------
-- Realtime: the app watches its own profile (balance) and generations.
-- RLS above limits each subscriber to their own rows.
-- ---------------------------------------------------------------------------

alter publication supabase_realtime add table public.generations, public.profiles;

-- ---------------------------------------------------------------------------
-- Storage (private buckets; clients read through signed URLs only)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('uploads', 'uploads', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('outputs', 'outputs', false, 26214400, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do nothing;

-- uploads/{user_id}/{generation_id}/...: owner may upload, read and delete.
create policy "uploads: insert own folder" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "uploads: read own folder" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "uploads: delete own folder" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'uploads'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- outputs/{user_id}/{generation_id}/...: read-only for the owner (signed
-- URLs need SELECT). Only Edge Functions write here. Private originals live
-- under outputs/{user_id}/{generation_id}/original/ and are denied.
create policy "outputs: read own folder" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'outputs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and coalesce((storage.foldername(name))[3], '') <> 'original'
  );
