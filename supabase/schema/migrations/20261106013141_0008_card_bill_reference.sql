create table if not exists public.card_bill_reference_lines (
  id bigserial primary key,
  closing_date date not null,
  tx_date date not null,
  amount_cents bigint not null,
  card_last4 text not null,
  inst_n int, inst_t int,
  kind text not null,
  matched_tx uuid,
  source text not null default 'pdf_v18'
);
alter table public.card_bill_reference_lines enable row level security;
create policy cbrl_read on public.card_bill_reference_lines for select to authenticated using (true);
comment on table public.card_bill_reference_lines is 'Lançamentos das faturas PDF (v18) usados só como referência de conciliação do cartão Pluggy; não entram nos totais.';
