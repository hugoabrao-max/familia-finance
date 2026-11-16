-- Notificações no celular (Web Push): um registro por aparelho que pediu aviso.
-- Gravação/remoção pela Edge Function push (service role); cada membro lê e apaga só os próprios aparelhos.
create table public.push_subscriptions (
  id uuid not null default gen_random_uuid(),
  member_id uuid not null references public.household_members(id) on delete cascade,
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  kinds text[] not null default array['revisao'],
  user_agent text,
  created_at timestamptz not null default now(),
  last_sent_at timestamptz,
  last_status int,
  active boolean not null default true,
  constraint push_subscriptions_pkey primary key (id),
  constraint push_subscriptions_endpoint_key unique (endpoint)
);
create index push_subscriptions_member_idx on public.push_subscriptions(member_id);
alter table public.push_subscriptions enable row level security;
create policy push_read_own on public.push_subscriptions for select to authenticated
  using (member_id = (select (current_member()).id));
create policy push_delete_own on public.push_subscriptions for delete to authenticated
  using (member_id = (select (current_member()).id));
revoke all on public.push_subscriptions from anon;
