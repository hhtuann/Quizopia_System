# Quizopia Media Infrastructure (Phase 4)

Self-hosted [LiveKit](https://livekit.io) SFU for monitored exam sessions — one
opaque room per Exam Session (ADR-008 D2/D3). LiveKit now runs in the **root
`docker-compose.yml`** as the `monitoring` profile (Egress behind the
`recording` profile). The former standalone `docker-compose.livekit.yml` stack
was retired; migration notes live in
[docs/infra/COMPOSE_MIGRATION.md](../../docs/infra/COMPOSE_MIGRATION.md).

## Layout

| File | Purpose |
|---|---|
| `docker-compose.yml` (System root) | `livekit` + dedicated `livekit-redis` (`monitoring` profile) and `egress` (`recording` profile) on the shared `quizopia_network` |
| `infra/livekit/livekit.yaml` | SFU config: ports, redis, webhook, TURN. `${...}` placeholders are rendered from container env at launch (livekit does NOT expand them itself) |
| `infra/livekit/egress.yaml` | Egress wiring: redis + SFU + LiveKit credentials. Recording storage is passed per request by the backend (MinIO/S3) |
| `.env` (System root, gitignored) | `QUIZOPIA_LIVEKIT_API_KEY` / `QUIZOPIA_LIVEKIT_API_SECRET` — the single credential pair shared by backend, SFU and Egress (was `.env.livekit`, retired) |

## Start / stop

```powershell
# monitoring (LiveKit + livekit-redis)
docker compose --profile monitoring up -d --build

# monitoring + recording (Egress)
docker compose --profile monitoring --profile recording up -d --build

# status / stop (never deletes volumes)
.\scripts\status-demo.ps1
.\scripts\stop-demo.ps1
```

Backend wiring (backend container, root `.env`):

```
QUIZOPIA_LIVEKIT_ENABLED=true
QUIZOPIA_LIVEKIT_API_KEY=devquizopia          # must match SFU keys entry
QUIZOPIA_LIVEKIT_API_SECRET=<same secret>     # single pair for backend+SFU+egress
QUIZOPIA_LIVEKIT_HTTP_URL=http://livekit:7880 # Twirp RoomService (service DNS)
QUIZOPIA_LIVEKIT_WS_URL=ws://localhost:7880   # handed to browsers (host-reachable)
```

`quizopia.media.livekit.enabled=false` (default) keeps the whole camera path
dormant — preflight endpoints answer 503 and schedulers idle.

## Ports / networking (local profile)

| Port | Protocol | Purpose |
|---|---|---|
| 7880 | HTTP/WSS | signaling + Twirp RoomService (browsers and backend) |
| 7881 | TCP | WebRTC-over-TCP fallback (UDP blocked networks) |
| 3478 | UDP | embedded TURN relay |
| 50100–50200 | UDP | WebRTC ICE media range (sized for ≤10 publishers; widen for scale tests) |

All container-to-container traffic uses Compose service DNS on
`quizopia_network`:

- Backend → SFU RoomService: `http://livekit:7880`
- SFU → backend webhooks: `http://backend:8080/internal/media/v1/livekit/webhooks`
  (signed; override with `LIVEKIT_WEBHOOK_URL` for host-run backends)
- Egress → SFU `ws://livekit:7880`, Redis `livekit-redis:6379`, MinIO `http://minio:9000`

`getUserMedia` requires a secure context: `http://localhost` qualifies; any
LAN deployment needs TLS (documented in the README "LAN demo" section — a
deployment step, out of local scope).

### Windows note: dynamic UDP exclusions

Hyper-V/WSL can reserve parts of the dynamic UDP range
(`netsh interface ipv4 show excludedportrange protocol=udp`), and the reserved
window MOVES after reboots. If `docker compose up` fails to bind the ICE
range, override BOTH values in `.env` to a free range, e.g.:

```
LIVEKIT_RTC_PORT_START=52000
LIVEKIT_RTC_PORT_END=52100
```

The compose file moves the published host ports and the `rtc.port_range`
config together. `scripts/start-demo.ps1` warns when the configured range
overlaps a current exclusion window.

## ICE / TURN behaviour and test

- Default path: ICE over UDP 50100–50200 direct to the SFU.
- UDP blocked → TCP 7881 fallback (automatic).
- Both blocked → TURN relay on UDP 3478 (`turn.enabled: true`). TLS TURN
  (`turns:`) needs a real domain + certificate — a production deployment step,
  not required for the local demo; noted here per ADR-08 operational notes.
- Forced-relay test (verify TURN actually works):
  connect a browser via livekit-client with
  `rtcConfig: { iceTransportPolicy: "relay" }` — the P4-B browser suite runs
  this as scenario G's network-restriction check.

## Rooms, tokens, permissions

- Room per session: opaque slug `s-<uuid>` in `monitoring_media_rooms`; never
  derived from user data; not exposed in any public URL.
- Tokens minted by the backend (never by browsers), TTL 120 s:
  - student: `roomJoin`, one fixed room, `canPublish` camera-only
    (`canPublishSources: ["camera"]`), **no** subscribe, **no** data, no mic.
  - teacher: same room, subscribe-only.
  - server admin token (room management) never leaves the backend process.
- Known self-host limitation (ADR-08 D14): a removed participant can rejoin
  with an unexpired token. Mitigation: 120 s TTL, app-layer revocation
  (renewal denied + RemoveParticipant), rejoin exposure window measured in
  the P4-B tests; do not claim absolute revocation.

## Egress (recording profile)

```powershell
docker compose --profile monitoring --profile recording up -d --build
```

`egress.yaml` wires redis + the SFU connection + the LiveKit credential pair
(rendered at launch). Recording destinations are NOT in this file: the Quizopia
backend passes the private MinIO/S3 destination (endpoint + credentials +
bucket, `quizopia.media.storage.egress-endpoint` → `http://minio:9000` inside
the shared network) inside every Start/Stop request. Recording stays OFF by
default; it is enabled per Exam Session recording configuration.

## 5-publisher demo environment

Hardware used for the P4-B local run: single Windows workstation, Docker
Desktop, Chromium publishers with synthetic cameras
(`--use-fake-device-for-media-stream`) — clearly labeled simulated media; the
number of real webcams available is recorded per test run instead of assumed.

To reproduce the 5-publisher demo:

1. Start this stack and the Quizopia backend with `QUIZOPIA_LIVEKIT_ENABLED=true`.
2. Seed a monitored CLASS_RESTRICTED session (the e2e global setup does this).
3. Launch 5 Chromium contexts with the fake-device flags, each student
   completes preflight → publish → start attempt.
4. Teacher opens the session detail page → Camera grid shows 5 tiles at LOW
   layer; open one fullscreen (HIGH layer).
   Scaling to 10 = 10 contexts; widen `LIVEKIT_RTC_PORT_START/END` if needed.

## Security notes

- API secret only in the System root `.env` + backend env; never in the
  frontend bundle or Git (`git check-ignore .env` confirms; `.env.*` ignored,
  `!.env.example` whitelisted).
- Webhook ingress verifies HS256 signature + body sha256 + freshness
  (`media/webhook/LiveKitWebhookVerifier`); rejects with 401 and no detail.
- No media frames transit the backend (Spring only issues tokens and reads
  RoomService state).
- Egress recordings land only in the private evidence bucket; playback via
  short-lived, teacher-scoped presigned URLs issued by the backend.
