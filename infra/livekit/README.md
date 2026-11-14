# Quizopia Media Infrastructure (P4-B1, issue #84)

Self-hosted [LiveKit](https://livekit.io) SFU for monitored exam sessions — one
opaque room per Exam Session (ADR-008 D2/D3). This stack is deliberately
**separate** from the owner's `docker-compose.yml`; nothing in it modifies the
existing Quizopia services, volumes or networks.

## Layout

| File | Purpose |
|---|---|
| `docker-compose.livekit.yml` (System root) | `livekit` + dedicated `livekit-redis`; `egress` behind the `egress` profile (P4-D placeholder) |
| `infra/livekit/livekit.yaml` | SFU config: ports, redis, webhook, TURN. `${LIVEKIT_API_SECRET}` is rendered from container env at launch (livekit does NOT expand `${...}` itself) |
| `infra/livekit/egress.yaml` | Egress wiring for P4-D (S3/MinIO section commented — activated then) |
| `.env.livekit` (gitignored) | `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` — generated once with `openssl rand -hex 24` |

## Start / stop

```bash
# from the System repo root
docker compose --env-file .env.livekit -f docker-compose.livekit.yml up -d
docker logs -f quizopia_livekit        # "starting LiveKit server ... portHttp: 7880"
curl http://localhost:7880             # -> "OK"

# stop (keeps nothing — redis runs in-memory; room state is rebuilt from Postgres bindings)
docker compose --env-file .env.livekit -f docker-compose.livekit.yml down
```

Backend wiring (dev/E2E, backend runs on the host):

```
QUIZOPIA_LIVEKIT_ENABLED=true
QUIZOPIA_LIVEKIT_API_KEY=devquizopia          # must match .env.livekit
QUIZOPIA_LIVEKIT_API_SECRET=<same secret>
QUIZOPIA_LIVEKIT_HTTP_URL=http://localhost:7880   # Twirp RoomService (server→SFU)
QUIZOPIA_LIVEKIT_WS_URL=ws://localhost:7880       # handed to browsers
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

- `getUserMedia` requires a secure context: `http://localhost` qualifies; any
  LAN deployment needs TLS (documented deployment step, out of local scope).
- Webhook delivery: SFU → `http://host.docker.internal:8080/internal/media/v1/livekit/webhooks`
  (backend on the Docker host). If the backend ever runs inside compose, change
  this URL to the backend service name.

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

## Egress (prepared, NOT active — P4-D)

```bash
docker compose --env-file .env.livekit -f docker-compose.livekit.yml --profile egress up -d
```

`egress.yaml` pre-wires redis + API credentials and documents the private
MinIO/S3 output buckets (`monitoring/recordings` etc.). P4-D fills storage
credentials and starts the service; P4-B ships no recording features.

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
   Scaling to 10 = 10 contexts; widen `rtc.port_range` if needed.

## Security notes

- API secret only in `.env.livekit` + backend env; never in the frontend
  bundle or Git (`git check-ignore .env.livekit` confirms).
- Webhook ingress verifies HS256 signature + body sha256 + freshness
  (`media/webhook/LiveKitWebhookVerifier`); rejects with 401 and no detail.
- No media frames transit the backend (Spring only issues tokens and reads
  RoomService state).
