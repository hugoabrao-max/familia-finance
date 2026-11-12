alter table transactions add column if not exists original_amount numeric, add column if not exists original_currency text;
comment on column transactions.amount is 'Valor em BRL (moeda da conta); compras no exterior usam amountInAccountCurrency da Pluggy';
comment on column transactions.original_amount is 'Valor na moeda original da compra (só quando diferente de BRL)';
update transactions t set
  original_amount = t.amount,
  original_currency = t.currency,
  amount = case when t.amount < 0 then -abs((r.payload->>'amountInAccountCurrency')::numeric) else abs((r.payload->>'amountInAccountCurrency')::numeric) end,
  currency = 'BRL'
from raw_transactions r
where r.id = t.raw_transaction_id and t.currency <> 'BRL' and r.payload ? 'amountInAccountCurrency';
