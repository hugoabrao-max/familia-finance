
create table if not exists public.financing_contracts(
  id text primary key, nome text not null, banco text, contrato text, commitment_id uuid references commitments(id),
  data_contrato date, valor_financiado numeric(14,2), sistema text, indexador text, taxa_efetiva_aa numeric(8,4), taxa_nominal_aa numeric(8,4),
  prazo_total int, dia_vencimento int, saldo_devedor numeric(14,2), saldo_em date, parcelas_pagas int, parcelas_restantes int,
  ultima_parcela date, amortizacao_mensal numeric(14,2), total_a_pagar numeric(14,2), juros_a_pagar numeric(14,2), seguros_tarifas_a_pagar numeric(14,2),
  participacao jsonb, fonte text, updated_at timestamptz not null default now());
create table if not exists public.financing_installments(
  contract_id text not null references financing_contracts(id), n int not null, due_date date not null, valor numeric(14,2) not null,
  saldo_apos numeric(14,2), pago boolean not null default false, primary key(contract_id,n));
alter table financing_contracts enable row level security; alter table financing_installments enable row level security;
create policy fc_read on financing_contracts for select to authenticated using (true);
create policy fc_write on financing_contracts for all to authenticated using (can_edit()) with check (can_edit());
create policy fi2_read on financing_installments for select to authenticated using (true);
create policy fi2_write on financing_installments for all to authenticated using (can_edit()) with check (can_edit());
create or replace view public.v_financing with (security_invoker=on) as
select c.*, (select i.valor from financing_installments i where i.contract_id=c.id and not i.pago order by n limit 1) as proxima_parcela,
  (select i.due_date from financing_installments i where i.contract_id=c.id and not i.pago order by n limit 1) as proximo_vencimento,
  (select coalesce(sum(i.valor),0) from financing_installments i where i.contract_id=c.id and not i.pago and i.due_date < (date_trunc('year',current_date)+interval '2 years')::date and i.due_date>=(date_trunc('year',current_date)+interval '1 year')::date) as total_proximo_ano
from financing_contracts c;

