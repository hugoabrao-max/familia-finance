CREATE OR REPLACE FUNCTION public.assign_card_competence()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  with x as (
    select t.id,
      coalesce(t.installment_number,1) inst,
      coalesce((r.payload->'creditCardMetadata'->>'billPostDate')::date, t.event_date) pd,
      r.payload->'creditCardMetadata'->>'cardNumber' card,
      nullif(r.payload->'creditCardMetadata'->>'billForecastDate','0001-01') bf,
      t.account_id
    from transactions t join accounts a on a.id=t.account_id and a.type='CREDIT'
    left join raw_transactions r on r.id=t.raw_transaction_id
  ), y as (
    select x.*, (select min(cc.closing_date) from card_bill_cycles cc where cc.account_id=x.account_id and not cc.superseded
                  and ((x.inst>=2 and cc.closing_date>x.pd) or (x.inst<2 and cc.closing_date>=x.pd))) fech,
           (select h.holder_name from card_holders h where h.card_last4=x.card) holder
    from x)
  update transactions t set
    bill_closing_date = y.fech,
    competence_month = date_trunc('month', coalesce(y.fech, y.pd))::date,
    bill_forecast_date = case when y.bf ~ '^\d{4}-\d{2}$' then (y.bf||'-01')::date else t.bill_forecast_date end,
    card_last4 = coalesce(y.card, t.card_last4),
    holder_name = coalesce(y.holder, t.holder_name)
  from y where t.id=y.id and (
    t.bill_closing_date is distinct from y.fech
    or t.competence_month is distinct from date_trunc('month', coalesce(y.fech, y.pd))::date
    or t.card_last4 is distinct from coalesce(y.card, t.card_last4)
    or t.holder_name is distinct from coalesce(y.holder, t.holder_name));
  get diagnostics n = row_count;
  return n;
end $function$
;
