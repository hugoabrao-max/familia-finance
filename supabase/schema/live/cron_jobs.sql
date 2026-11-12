select cron.schedule('pluggy-sync-diario', '15 1,3,10,22 * * *', $cmd$ select net.http_post(
       url := 'https://hrsinekxrfiphlhpoewp.supabase.co/functions/v1/pluggy-sync',
       headers := jsonb_build_object('Content-Type','application/json','x-sync-token',(select value from app_settings where key='sync_token')),
       body := '{"trigger":"cron"}'::jsonb,
       timeout_milliseconds := 150000) $cmd$);

select cron.schedule('pos-sync', '25 1,3,10,22 * * *', $cmd$ select post_sync() $cmd$);
