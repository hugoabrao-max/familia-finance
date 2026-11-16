-- Aviso diário no celular quando há lançamentos pendentes: 23:07 UTC = 19:07 em Cuiabá.
-- A função push só envia se houver pendentes e só para aparelhos que ativaram as notificações.
select cron.schedule('push-revisao-diario', '7 23 * * *', $cmd$ select net.http_post(
       url := 'https://hrsinekxrfiphlhpoewp.supabase.co/functions/v1/push',
       headers := jsonb_build_object('Content-Type','application/json','x-sync-token',(select value from app_settings where key='sync_token')),
       body := '{"op":"digest"}'::jsonb,
       timeout_milliseconds := 60000) $cmd$);
