CREATE TRIGGER trg_accounts_updated BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_card_statements_updated BEFORE UPDATE ON public.card_statements FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_classification_rules_updated BEFORE UPDATE ON public.classification_rules FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_connections_updated BEFORE UPDATE ON public.connections FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_transactions_updated BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
