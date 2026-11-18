# Compose Consolidation Migration Guide

One-time migration from the split stacks
(`docker-compose.yml` + `docker-compose.livekit.yml`) to the single
authoritative root `docker-compose.yml` with profiles:

| Profile | Services |
|---|---|
| *(none)* | frontend, backend, postgres-db, redis-cache, minio, mailpit |
| `monitoring` | + livekit, livekit-redis |
| `recording` | + egress (implies monitoring: LiveKit services are in both profiles) |

## Why this is safe

- The root compose pins `name: quizopia-system`, the SAME project name the
  directory-based default produced before. Existing volumes
  (`quizopia-system_postgres_data`, `_redis_data`, `_minio_data`,
  `_maven_cache`) and the network (`quizopia-system_quizopia_network`) keep
  their identity — no volume migration, no data copy, no recreation of the
  database.
- Container names are unchanged (`quizopia_postgres`, `quizopia_backend`,
  `quizopia_livekit`, `quizopia_livekit_redis`, `quizopia_livekit_egress`, …).
- The legacy media stack held NO persistent data: `livekit-redis` ran
  in-memory (`--save "" --appendonly no`) and room bindings live in Postgres.
  Its only volume (`quizopia-media_livekit-tmp`) was a Windows-override
  scratch space for the rendered config.
- Secrets are unchanged — only MOVED: `LIVEKIT_API_KEY`/`LIVEKIT_API_SECRET`
  from `.env.livekit` became `QUIZOPIA_LIVEKIT_API_KEY`/`_API_SECRET` in the
  root `.env` (same values; no rotation). MinIO credentials moved from the
  compose file into `QUIZOPIA_MINIO_ROOT_USER`/`_ROOT_PASSWORD`
  (+ `QUIZOPIA_EVIDENCE_MINIO_*`) in `.env` with the same values.

## Migration steps

Run from the System repo root. NEVER use `docker compose down -v` at any point.

1. **Back up your `.env`** (it is gitignored): `Copy-Item .env .env.pre-consolidation.bak`

2. **Merge the LiveKit secrets into the root `.env`** — copy the VALUES from
   `.env.livekit` (if you still have one):

   ```
   QUIZOPIA_LIVEKIT_API_KEY=<LIVEKIT_API_KEY value, e.g. devquizopia>
   QUIZOPIA_LIVEKIT_API_SECRET=<LIVEKIT_API_SECRET value>
   ```

   and add/verify the in-stack URLs:

   ```
   QUIZOPIA_LIVEKIT_HTTP_URL=http://livekit:7880
   QUIZOPIA_EVIDENCE_MINIO_EGRESS_ENDPOINT=http://minio:9000
   ```

3. **Stop the legacy media stack** (keeps everything; removes only containers
   and its network):

   ```powershell
   docker compose -p quizopia-media --env-file .env.livekit -f docker-compose.livekit.yml down
   # If you used the local Windows ICE overrides, also:
   docker compose -p quizopia-media --env-file .env.livekit -f docker-compose.livekit.yml `
     -f docker-compose.livekit.windows-override.yml --profile egress down
   docker ps -a --filter name=quizopia_livekit   # must list nothing
   ```

4. **Validate + start the consolidated stack**:

   ```powershell
   docker compose --profile monitoring --profile recording config --quiet
   docker compose --profile monitoring --profile recording up -d --build
   docker compose --profile monitoring --profile recording ps
   ```

5. **Verify data retention**: `docker volume ls --filter label=com.docker.compose.project=quizopia-system`
   must still list the four volumes; the frontend must still log users in
   (Postgres data) and the MinIO console (`http://localhost:9001`) must still
   show the `quizopia-evidence` bucket.

6. **Retire the legacy files** (after step 5 passes):
   - `docker-compose.livekit.yml` — deleted from the repository by this
     consolidation.
   - `.env.livekit` — gitignored; safe to delete once the values live in the
     root `.env`. Keep a private backup if you want a rollback path.
   - `docker-compose.livekit.windows-override*.yml` — untracked local files;
     obsolete because the ICE port range is now configurable via
     `LIVEKIT_RTC_PORT_START`/`_END` in `.env`. Delete them.

## Conflict detection (both stacks active)

Container names collide: `quizopia_livekit`, `quizopia_livekit_redis`,
`quizopia_livekit_egress` and the host ports 7880/7881/3478 (+ ICE UDP range)
exist in both stacks. If the legacy stack is still running, `docker compose
up` on the consolidated stack fails with `port is already allocated` or
`Conflict. The container name ... is already in use`. Fix: run step 3.

`scripts/start-demo.ps1` preflights this and fails with instructions.

## Rollback

```powershell
docker compose --profile monitoring --profile recording down   # no -v!
git checkout <pre-consolidation-commit> -- docker-compose.yml infra/livekit
docker compose up -d
docker compose --env-file .env.livekit -f docker-compose.livekit.yml up -d
```

Volumes were never touched, so both directions are lossless.

## Known Windows caveat: Hyper-V UDP exclusions

Windows can dynamically reserve UDP ranges that overlap the default ICE range
50100–50200; the reservation window moves across reboots. If binding fails,
set a free range in `.env` (both values together):

```
LIVEKIT_RTC_PORT_START=52000
LIVEKIT_RTC_PORT_END=52100
```

Check current exclusions with
`netsh interface ipv4 show excludedportrange protocol=udp`.
