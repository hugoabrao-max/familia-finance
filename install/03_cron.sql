-- Family Finance — agendamentos (rodar depois de publicar a Edge Function pluggy-sync).
-- Troque {{PROJECT_REF}} pelo código do projeto Supabase (o que aparece em https://<código>.supabase.co).
-- Horários em UTC: 01:15, 03:15, 10:15 e 22:15 (21:15, 23:15, 06:15 e 18:15 em Cuiabá). Não forçar mais vezes: a Pluggy atualiza o banco ~1x/dia.
select cron.schedule('pluggy-sync-diario', '15 1,3,10,22 * * *', $cmd$ select net.http_post(
       url := 'https://{{PROJECT_REF}}.supabase.co/functions/v1/pluggy-sync',
       headers := jsonb_build_object('Content-Type','application/json','x-sync-token',(select value from app_settings where key='sync_token')),
       body := '{"trigger":"cron"}'::jsonb,
       timeout_milliseconds := 150000) $cmd$);

select cron.schedule('pos-sync', '25 1,3,10,22 * * *', $cmd$ select post_sync() $cmd$);
