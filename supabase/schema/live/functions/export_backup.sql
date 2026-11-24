CREATE OR REPLACE FUNCTION public.export_backup()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t text; out jsonb := '{}'::jsonb; part jsonb;
begin
  -- v10 (24/11/2026): sem segredos — fora sync_token, backup_token, a chave privada das notificações (vapid_private_jwk)
  -- e os aparelhos inscritos (push_subscriptions: chaves de cada aparelho; basta ligar de novo no app).
  -- v9: todas as tabelas do esquema public (novas tabelas entram automaticamente)
  for t in select table_name from information_schema.tables
           where table_schema='public' and table_type='BASE TABLE' and table_name not in ('app_settings', 'push_subscriptions') order by 1
  loop
    execute format('select coalesce(jsonb_agg(to_jsonb(x)), ''[]''::jsonb) from public.%I x', t) into part;
    out := out || jsonb_build_object(t, part);
  end loop;
  select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb) into part from app_settings s where key not in ('sync_token','backup_token','vapid_private_jwk');
  out := out || jsonb_build_object('app_settings', part);
  return jsonb_build_object('schema_version', 10, 'exported_at', now(), 'tables', out);
end $function$
;
