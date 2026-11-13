# Railway Functions — familia-finance

Project `familia-finance` (`9e62e7a6-4137-4a19-b6f6-8a0ab822dcc0`), environment `production` (`f79eeeae-5238-4de5-a761-97746d6b3a13`).
The two services below are Railway Functions (the old `app` Function was deleted on 13/11/2026; the frontend runs on the `web` service, built from GitHub — see `../docs/DEPLOYMENT.md`) (Bun), image `ghcr.io/railwayapp/function-bun:1.4.4`, region `iad`, 1 replica.

| Service | Service id | Local source | Schedule | Restart policy |
|---|---|---|---|---|
| `web` | `58aaaa85-4999-4153-a676-9bd9ccc60aef` | built from GitHub `app/` (`app/Dockerfile`) | none (HTTP server, domain `familia-finance.up.railway.app`; deploys on push to `main` touching `app/**`) | ON_FAILURE (5) |
| `backup` | `4d7ec7db-f037-4859-8af7-693de947c69c` | `backup.ts` | cron `0 9 * * *` (UTC) | NEVER |
| `restore-check` | `6e7fa322-bc40-451b-9bdf-f4a49e9311c3` | `restore-check.ts` | cron `0 10 * * 0` (UTC, domingo 06:00 Cuiabá; desde 12/11/2026) e também a cada deploy/redeploy | NEVER |

## app
Bun.serve SPA. Routes: `/` (HTML), `/manifest.json`, `/sw.js`, `/icon.png`, `/health` (`{"ok":true,"version":APP_VERSION}`); anything else redirects to `/`.
Version constant `APP_VERSION` (0.14.0 at the time of download). The Supabase URL and publishable key are embedded in the source (intentionally public).
Variables: none.

## backup
Fetches the Supabase export from `BACKUP_URL`, gzips it, writes `familia-finance/<timestamp>.json.gz` to the Railway S3 bucket, reads it back to verify the sha256, and reports the result to `BACKUP_URL + "/report"`.

## restore-check
Downloads the most recent backup from the bucket, decompresses it, POSTs it to `BACKUP_URL + "/restore"` (restores into the isolated `restore_test` schema and compares with production). Reports failures to `/report`.

## Variables (names only — never commit values)
`backup` and `restore-check` both use:
`BACKUP_URL`, `BACKUP_TOKEN`, `S3_ENDPOINT`, `S3_BUCKET`, `S3_REGION`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`.

## How the source is stored and deployed
- Railway Functions keep the source inside the service's start command: `./run.sh <base64 of the whole file>`.
  Read it with the Railway MCP `get-function-source-code` (fields `code` / `deployedCode`), or decode the start command from `get-service-config` (`sed 's#^\./run\.sh ##' | base64 -d`).
- Deploy with `update-function-source-code`, which **replaces the whole file** — always send the complete, tested file.
- After deploying: read the source back with `get-function-source-code`, diff it against the tested local file (byte-identical), and for `app` check `https://familia-finance.up.railway.app/health` reports the new `APP_VERSION`.
- `restore-check` runs weekly (Sunday 10:00 UTC, after the 09:00 backup and before the 10:15 sync, so no sync changes production in between) and on every deploy. Since migration 0028 the comparator checks the restored data against the backup itself (rows per table and transaction sum); production counts are informational, with an alarm if production has fewer transactions/raw_transactions than the backup (nothing may be deleted).
