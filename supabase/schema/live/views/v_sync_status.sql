create or replace view public.v_sync_status with (security_invoker = on) as
 SELECT connector_name,
    status,
    execution_status,
    provider_updated_at,
    last_sync_at,
    consent_expires_at,
    ((consent_expires_at - now()) < '30 days'::interval) AS consent_warning,
    ( SELECT max(sync_jobs.finished_at) AS max
           FROM sync_jobs
          WHERE (sync_jobs.status = ANY (ARRAY['SUCCESS'::text, 'PARTIAL'::text]))) AS last_ok_sync,
    ( SELECT sync_jobs.status
           FROM sync_jobs
          ORDER BY sync_jobs.started_at DESC
         LIMIT 1) AS last_job_status,
    ( SELECT count(*) AS count
           FROM (sync_errors e
             JOIN sync_jobs j ON ((j.id = e.sync_job_id)))
          WHERE (j.started_at > (now() - '7 days'::interval))) AS errors_7d
   FROM connections c
  WHERE is_active;
