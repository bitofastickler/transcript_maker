-- Supabase schema for Homeschool Transcript Maker
-- Run this file in the Supabase SQL editor or via `supabase db push`.

-- Ensure required extensions exist.
create extension if not exists "pgcrypto";

-- Utility function to keep `updated_at` timestamps in sync.
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$ language plpgsql;

-- Optional profile table for per-user metadata & Stripe linkage.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  stripe_customer_id text,
  subscription_status text,
  subscription_tier text,
  current_period_end timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger profiles_handle_updated_at
before update on public.profiles
for each row execute procedure public.handle_updated_at();

-- Automatically create a profile row whenever a Supabase user registers.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Students table -----------------------------------------------------------------
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  first_name text not null,
  last_name text not null,
  date_of_birth date not null,
  target_grad_year integer not null,
  email text,
  phone text,
  address text,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_students_owner on public.students (owner_id);

create trigger students_handle_updated_at
before update on public.students
for each row execute procedure public.handle_updated_at();

alter table public.students enable row level security;

create policy "Students are viewable by owner"
on public.students
for select
using (auth.uid() = owner_id);

create policy "Students are insertable by owner"
on public.students
for insert
with check (auth.uid() = owner_id);

create policy "Students are updatable by owner"
on public.students
for update
using (auth.uid() = owner_id);

create policy "Students are deletable by owner"
on public.students
for delete
using (auth.uid() = owner_id);

-- Enrollments (course records) ----------------------------------------------------
create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  grade_level integer not null,
  year_label text not null,
  term_start_date date,
  term_end_date date,
  completed_on date,
  course_title text not null,
  subject_category text not null,
  description text,
  credit_hours numeric(4,2) not null default 1.0,
  grade_letter text not null,
  is_pass_fail boolean not null default false,
  is_weighted boolean not null default false,
  weight_multiplier numeric(4,2) not null default 1.0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_enrollments_student on public.enrollments (student_id);
create index if not exists idx_enrollments_owner on public.enrollments (owner_id);

create trigger enrollments_handle_updated_at
before update on public.enrollments
for each row execute procedure public.handle_updated_at();

alter table public.enrollments enable row level security;

create policy "Enrollments viewable by owner"
on public.enrollments
for select
using (auth.uid() = owner_id);

create policy "Enrollments insertable by owner"
on public.enrollments
for insert
with check (auth.uid() = owner_id);

create policy "Enrollments updatable by owner"
on public.enrollments
for update
using (auth.uid() = owner_id);

create policy "Enrollments deletable by owner"
on public.enrollments
for delete
using (auth.uid() = owner_id);

-- Awards --------------------------------------------------------------------------
create table if not exists public.awards (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  name text not null,
  description text,
  organization text,
  category text,
  year_label text not null,
  awarded_on date,
  grade_level integer,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_awards_student on public.awards (student_id);
create index if not exists idx_awards_owner on public.awards (owner_id);

create trigger awards_handle_updated_at
before update on public.awards
for each row execute procedure public.handle_updated_at();

alter table public.awards enable row level security;

create policy "Awards viewable by owner"
on public.awards
for select
using (auth.uid() = owner_id);

create policy "Awards insertable by owner"
on public.awards
for insert
with check (auth.uid() = owner_id);

create policy "Awards updatable by owner"
on public.awards
for update
using (auth.uid() = owner_id);

create policy "Awards deletable by owner"
on public.awards
for delete
using (auth.uid() = owner_id);

-- Activities ----------------------------------------------------------------------
create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  type text not null,
  title text not null,
  description text,
  organization text,
  hours numeric(6,2),
  year_label text not null,
  start_date date,
  end_date date,
  grade_level integer,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_activities_student on public.activities (student_id);
create index if not exists idx_activities_owner on public.activities (owner_id);

create trigger activities_handle_updated_at
before update on public.activities
for each row execute procedure public.handle_updated_at();

alter table public.activities enable row level security;

create policy "Activities viewable by owner"
on public.activities
for select
using (auth.uid() = owner_id);

create policy "Activities insertable by owner"
on public.activities
for insert
with check (auth.uid() = owner_id);

create policy "Activities updatable by owner"
on public.activities
for update
using (auth.uid() = owner_id);

create policy "Activities deletable by owner"
on public.activities
for delete
using (auth.uid() = owner_id);
