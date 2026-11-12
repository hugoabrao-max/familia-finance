CREATE OR REPLACE FUNCTION public.post_sync()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform refresh_card_cycles();
  perform assign_card_competence();
  perform classify_transactions(true);
  perform reconcile_all();
  perform detect_duplicates();
end $function$
;
