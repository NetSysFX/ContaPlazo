create table if not exists public.clients (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  nit text not null,
  name text not null,
  due_date timestamptz not null,
  fee numeric(14,2) not null default 0,
  paid integer not null default 0 check (paid in (0, 1)),
  document_count integer not null default 0,
  tax_status integer not null default 0 check (tax_status between 0 and 2),
  updated_at timestamptz not null default now(),
  unique (user_id, nit)
);

create table if not exists public.accountant_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  professional_id text not null default '',
  phone text not null default '',
  email text not null default '',
  firm text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.clients enable row level security;
alter table public.accountant_profiles enable row level security;

revoke all on public.clients from anon;
revoke all on public.accountant_profiles from anon;
grant select, insert, update, delete on public.clients to authenticated;
grant select, insert, update, delete on public.accountant_profiles to authenticated;
grant usage, select on sequence public.clients_id_seq to authenticated;

create policy "accountants_manage_own_clients" on public.clients
for all to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "accountants_manage_own_profile" on public.accountant_profiles
for all to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('client-documents', 'client-documents', false, 10485760, array[
  'application/pdf', 'image/jpeg', 'image/png', 'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
]) on conflict (id) do nothing;

create policy "accountants_read_own_documents" on storage.objects
for select to authenticated
using (bucket_id = 'client-documents' and (storage.foldername(name))[1] = (select auth.uid()::text));

create policy "accountants_upload_own_documents" on storage.objects
for insert to authenticated
with check (bucket_id = 'client-documents' and (storage.foldername(name))[1] = (select auth.uid()::text));

create policy "accountants_update_own_documents" on storage.objects
for update to authenticated
using (bucket_id = 'client-documents' and owner_id = (select auth.uid()::text))
with check (bucket_id = 'client-documents' and (storage.foldername(name))[1] = (select auth.uid()::text));

create policy "accountants_delete_own_documents" on storage.objects
for delete to authenticated
using (bucket_id = 'client-documents' and owner_id = (select auth.uid()::text));
