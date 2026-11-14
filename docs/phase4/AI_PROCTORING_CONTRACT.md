# P4-C AI Proctoring — Architecture Decision & Shared Contract

Status: DECIDED (2026-11-15). This file is the single source of truth for the
P4-C implementation contract. Backend and frontend MUST build against it.

## 1. Model audit facts (measured, not assumed)

Artifact `D:\Developer\quizopia-ai-assets\yolo26s.onnx` (19,215,911 bytes):

| Item | Fact |
|---|---|
| Architecture | Ultralytics **YOLO26s** (ultralytics 8.4.64, exported pytorch 2.12.0) |
| IR / opset | ONNX IR 8, opset `ai.onnx:17` |
| License | **AGPL-3.0** (Ultralytics) — academic demo use; documented in model card |
| Input | `images` `[1,3,640,640]` float32, RGB, `/255` normalized (Ultralytics convention), letterbox pad 114 |
| Output | `output0` `[1,300,6]` float32 = rows `[x1,y1,x2,y2,score,classId]` in **640-letterbox pixel coords**, end-to-end NMS built in (no NMS step needed) |
| Classes | COCO 80. Relevant: `0=person`, `62=tv`, `63=laptop`, `67=cell phone` |
| CPU latency (Python ORT 1.32, this workstation) | p50 50.1ms / p95 56.6ms (≈20 FPS single stream) |

Consequences:
- **PHONE and SCREEN and PERSON detection are genuinely supported** by the real
  model (`cell phone`=67, `tv`=62, `laptop`=63, `person`=0). MULTIPLE_PERSONS =
  count of `person` boxes. No fake detection needed.
- **Gaze is NOT supported** (COCO has no gaze/head-pose). Gaze adapter stays a
  disabled contract only.

## 2. Architecture decision: Hybrid — browser-side ONNX Runtime Web now, worker-ready contract

Chosen: **Browser-side inference (ONNX Runtime Web) on the student's own camera
track as the initial real-model path**, with a **transport-agnostic versioned
ingestion contract** that a future independent AI worker (SERVER provenance)
plugs into without schema change.

Why (evaluated against the alternatives):

| Criterion | Browser ORT-Web | Independent worker (LiveKit subscribe) | Hybrid (chosen) |
|---|---|---|---|
| FPS/latency for 5–10 cams | Each student's machine runs 1.5–3 FPS on its own stream; WebGPU 10–30ms, WASM 100–300ms/frame | Server CPU: 5–10 × 1.5FPS × ~50ms ≈ 1 core busy; headless WebRTC decode is heavy (chromium dep or Egress→files) | Browser now; worker additive later |
| Deploy cost | None (static 19MB asset, cached) | New service + registry + compose + health | None now |
| Blockers | None | Creating an AI repo/submodule requires separate owner approval (issue #88 DoD) | None now |
| Provenance trust | CLIENT_AI_OBSERVED (ADR-008 D8 explicitly allows browser observations as non-verified) | SERVER_VERIFIED | Both, distinguished by `provenance` column |
| Reuse of model | Direct (ort-web runs the same artifact) | Direct (ort-node/python) | Same artifact both paths |

ADR-008 D8 already states "Browser-side events are observations, not verified
misconduct" — the amendment records browser inference as the initial real-model
runtime and keeps the worker contract ready. **CLIENT detections are never
labeled SERVER_VERIFIED / never auto-conclude cheating.**

## 3. Detection event contract (v1)

### 3.1 Student path (implemented now)

`POST /api/attempts/{attemptId}/ai-detections` — student JWT (`Authorization: Bearer`),
attempt owner only, permission `AI_DETECTION_INGEST` (learner role, seeded like
ATTEMPT_ACTIVITY_INGEST), fixed-window rate limit (own limiter domain
`monitoring:ai-ingest`, default 6 requests/min/user), batch ≤ 8 items.

Request item fields (all validated):
- `eventId` UUID — **idempotency identity** (unique index; `ON CONFLICT DO NOTHING`,
  duplicates return `DUPLICATE`, never re-alert)
- `eventType` enum: `PHONE_OBSERVED` | `SCREEN_OBSERVED` | `MULTIPLE_PERSONS_OBSERVED` | `PERSON_NOT_OBSERVED`
  (client-observation naming; the word DETECTED is reserved for server-aggregated alerts)
- `observedAt` Instant (frame capture time, client clock, stored verbatim; sanity window 2000..2200)
- `sequence` Long (monotonic per attempt+client)
- `modelId` string (≤40) — e.g. `yolo26s`
- `modelVersion` string (≤40) — e.g. `8.4.64-onnx`
- `runtime` enum: `ORT_WEB_WASM` | `ORT_WEB_WEBGPU` | `WORKER_ORT` (worker path only uses WORKER_ORT)
- `frameWidth`/`frameHeight` int (source frame dims at capture)
- `processingMs` int ≥0 (inference+pre/post ms, honest telemetry)
- `detections` array ≤ 8 of `{classId int, label string ≤32, confidence double 0..1, bbox [x1,y1,x2,y2] doubles normalized 0..1 to frameWidth/Height}`
  (only detections that drove the event; e.g. for MULTIPLE_PERSONS: the ≥2 person boxes)

Response mirrors P4-A: `{results:[{eventId, status: ACCEPTED|DUPLICATE|QUARANTINED_LATE|REJECTED, reason?}]}`.
Atomic validation: one invalid item rejects the whole batch (400) before inserts.

### 3.2 Time binding & quarantine (both paths)

At receipt (server clock):
- Attempt must exist and be owned by caller (student) → else 404/403.
- Attempt status must be `IN_PROGRESS` → else every item `QUARANTINED_LATE` (stored, flagged, NEVER alerts).
- An **active media binding** must exist for (attempt, user) (P4-B `monitoring_media_bindings`) → else `REJECTED` `NO_ACTIVE_MEDIA` (409-ish item status; binding ties detections to the media identity — issue #88 "media-session-to-Attempt validation").
- `observedAt` must be within `[attempt.startedAt − 5s, now + 5s]` → else `QUARANTINED_LATE` (late/out-of-order events bind the ORIGINAL attempt via attemptId but never alert).

### 3.3 Internal worker path (contract-ready; service auth now)

`POST /internal/ai/v1/detections` — header `X-Api-Key: <QUIZOPIA_AI_INGEST_KEY>`
(deny-all when the property is unset — same posture as LiveKit webhook config).
Identical validation/aggregation core, `provenance = WORKER_VERIFIED`, items
carry `attemptId` + `userId` explicitly (worker has no student JWT).
No worker is deployed in P4-C (repo/submodule pending owner approval); the
endpoint exists, is tested with a real key in Testcontainers, and is the
documented integration point.

## 4. Persistence (Flyway V38) — tables

1. `monitoring_ai_detections`: id BIGSERIAL PK, attempt_id FK attempts, exam_session_id FK,
   user_id FK, media_binding_id FK monitoring_media_bindings NULL, event_id UUID UNIQUE NOT NULL,
   provenance VARCHAR(20) CHECK (CLIENT_MODEL|WORKER_VERIFIED), event_type VARCHAR(40) CHECK (4 types),
   model_id VARCHAR(40), model_version VARCHAR(40), runtime VARCHAR(20),
   observed_at TIMESTAMPTZ, server_received_at TIMESTAMPTZ, quarantined BOOLEAN NOT NULL DEFAULT false,
   quarantine_reason VARCHAR(40) NULL, frame_width INT, frame_height INT, processing_ms INT,
   payload JSONB (detections array), late_ms BIGINT NULL.
   Indexes: (attempt_id, observed_at), (exam_session_id, server_received_at), partial (quarantined) etc.
2. `monitoring_ai_alerts`: id BIGSERIAL PK, attempt_id FK, exam_session_id FK, user_id FK,
   alert_type VARCHAR(40) CHECK (PHONE_DETECTED|SCREEN_DETECTED|MULTIPLE_PERSONS_DETECTED|PERSON_NOT_VISIBLE),
   status VARCHAR(12) CHECK (OPEN) DEFAULT 'OPEN', first_detected_at TIMESTAMPTZ, last_detected_at TIMESTAMPTZ,
   detection_count INT NOT NULL DEFAULT 1, max_confidence DOUBLE PRECISION, latest_payload JSONB,
   model_id, model_version, provenance, created_at, updated_at.
   Partial UNIQUE index: one OPEN alert per (attempt_id, alert_type) WHERE status='OPEN'.
3. Permission seed: `AI_DETECTION_INGEST` → role LEARNER (+TEACHER keeps learner role set — follow V37 pattern),
   `AI_ALERTS_READ` → TEACHER only.
4. **No FK or write path to grade/penalty tables** — enforced by design; tests assert.

## 5. Temporal aggregation (issue #90) — server-side

For each ACCEPTED detection, within the SAME transaction (order: insert detection → aggregate → record activity → publish after-commit events):

- Find OPEN alert for (attempt_id, alert_type). None → INSERT new alert (count=1) → activity event `AI_ALERT_RAISED` (source SERVER, metadata: alertId, alertType, maxConfidence, modelVersion, provenance, detection eventId).
- OPEN exists → if `observedAt <= last_detected_at + cooldown` (PHONE/SCREEN/MULTIPLE_PERSONS: **20s**; PERSON_NOT_VISIBLE: **45s**) → EXTEND: last_detected_at=observedAt, count+1, max_confidence=MAX, latest_payload=payload, updated_at — one `AI_ALERT_UPDATED` activity event ONLY when count is a power of two or the alert re-opens after a stretch (cap notification spam: emit updates at count ∈ {2,4,8,16,32,64} only).
- Gap > cooldown → close old (status stays OPEN semantics: simply start a NEW alert row; old row remains as its own incident window) → `AI_ALERT_RAISED` for the new row.
- Dedup: duplicate eventId (idempotent insert 0 rows) NEVER reaches aggregation.
- Quarantined detections NEVER aggregate.

Realtime: reuse P4-A machinery exactly — alerts are recorded as attempt
activity events (`AI_ALERT_RAISED`/`AI_ALERT_UPDATED`, source SERVER) via the
existing `ActivityEventRecorder`; the existing AFTER_COMMIT
`AttemptActivityBroadcaster` pings `/topic/exam-sessions/{sessionId}` (teacher
topic, existing STOMP auth) — no new destination, no new envelope type needed;
the durable REST is the source of truth on reconnect.

Alert REST (teacher): `GET /api/exam-sessions/{sessionId}/ai-alerts?cursor&limit&status`
→ `{items:[{alertId, attemptId, studentUserId, studentName, alertType, status, firstDetectedAt,
lastDetectedAt, detectionCount, maxConfidence, modelId, modelVersion, provenance, latestDetections}]}`,
cursor = last alertId DESC (newest first). Teacher only (`AI_ALERTS_READ` +
session owner). Students CANNOT read alerts (no endpoint for them; 403).

## 6. Frontend runtime contract

Package `frontend/lib/ai/`:

- `model-adapter.ts` — static import of onnxruntime-web (`ort`), env.wasm.wasmPaths='/ort/' (wasm files copied to public/ort), model URL `/models/yolo26s.onnx`, model card constant `MODEL = {id:'yolo26s', version:'8.4.64-onnx', inputSize:640, classes:{0:'person',62:'tv',63:'laptop',67:'cell phone'}, license:'AGPL-3.0'}`. `createDetector(video: HTMLVideoElement)` → `{detect(): Promise<DetectionFrame|null>, status, release()}`.
  - preprocess: own 640×640 offscreen canvas; letterbox scale = min(640/w, 640/h), center, pad fill rgb(114,114,114); getImageData → Float32Array RGB /255 CHW.
  - postprocess: rows score ≥ MIN_SCORE (0.5 phone/screen/person, 0.4 person-absence check), map classIds, un-letterbox bbox to source coords, normalize 0..1, clamp.
  - runtime pick: `navigator.gpu` → `ORT_WEB_WEBGPU` session `{executionProviders:['webgpu','wasm']}`; else `ORT_WEB_WASM`. Session create failure → status 'unavailable' (honest).
- `detection-scheduler.ts` — single-slot queue (new frame replaces pending; droppedFrames++), budget default 1.5 FPS analysis (adaptive: p95 processingMs > 1500ms → 0.75 FPS floor 0.5; <300ms sustained → 3 FPS cap), `stop()` releases everything. NEVER on the autosave/submit path; failures degrade status only.
- `use-attempt-ai-detection.ts` — binds to the attempt's ACTIVE published video (own hidden feeder `<video>` with the published camera track — works identically for the canvas-fallback portrait track of P4-B), runs scheduler, decides events client-side:
  - phone: any cell-phone box ≥0.5 → `PHONE_OBSERVED`
  - screen: any tv/laptop box ≥0.5 → `SCREEN_OBSERVED`
  - multi: ≥2 person boxes ≥0.5 → `MULTIPLE_PERSONS_OBSERVED` (payload = the person boxes)
  - person absent: 0 person boxes ≥0.4 on **3 consecutive analyzed frames** → `PERSON_NOT_OBSERVED` (reset on any person)
  - sends batches (≤8) via `lib/api/ai-detections.ts`; each event eventId=crypto.randomUUID(); eventId duplicate-safe retry ×1; failure → status 'degraded', NEVER propagates.
  - cleanup on unmount/attempt end: scheduler.stop(), feeder released. Autoplay/permission issues → 'unavailable'.
- `gaze-adapter.ts` — contract stub: `GAZE_SUPPORT = {supported:false, reason:'model yolo26s (COCO) has no gaze/head-pose output'}`; no event can be produced; UI never shows gaze warnings.
- Student UI: neutral AI status pill near the camera pill (Component in attempt page): `AI giám sát: đang chạy (yolo26s, ~1.5FPS, WebGPU)` / `đang tải mô hình…` / `không khả dụng (không ảnh hưởng bài làm)`. NO detections shown to student.
- Teacher UI (`components/teacher/`): AI alert feed panel in LiveMonitor area — subscribes existing session topic (activity ping with activityType AI_ALERT_* triggers refetch/backfill merge), REST backfill `GET .../ai-alerts` on mount + reconnect; card shows: student name, alert type (VN label), confidence, count, first→last window, model id+version, provenance chip (CLIENT MODEL / WORKER), timestamp; bbox mini-render: neutral dark canvas with boxes drawn from latestDetections (labeled "bbox từ khung phân tích — không lưu ảnh (P4-D)"); disclaimer line: "Quan sát bằng AI — không tự động kết luận vi phạm."

## 7. Test matrix (must-have)

Backend (Testcontainers): happy path; duplicate eventId idempotent (no second alert);
batch bound; rate limit 429; wrong owner 404/403; finished attempt → QUARANTINED_LATE (stored, no alert);
no active binding → REJECTED NO_ACTIVE_MEDIA; observedAt outside window → quarantine;
10 detections in 20s window → ONE alert count=10 (aggregation);
gap > cooldown → second alert row; quarantined never aggregates;
teacher backfill REST + auth (other teacher 403, student 403);
no grade-table writes (schema assert + no grade repo call path);
internal worker endpoint: valid key accepted (WORKER_VERIFIED), missing/wrong key 401, unset key → 404/deny.
Migration pin updates: existing tests pinned to V37 head must pin V38.

Frontend (vitest, jsdom): letterbox math (portrait/landscape/square, unletterbox roundtrip),
[300,6] postprocess parse + class mapping + normalization, scheduler (drop-old, fps budget adapt, stop cleanup),
hook honest states (model load fail → unavailable; api fail → degraded; never throws to attempt UI),
event decision (phone/screen/multi/person-absent 3-frame), teacher feed render + bbox math, gaze stub unsupported.

e2e (Playwright, deterministic, FAKE adapter labeled): scenario H — monitored session,
attempt with camera, inject fake model adapter via test hook (test-hooks pattern),
fake detects phone 3 frames → ONE aggregated alert visible in teacher feed realtime;
duplicate eventId replay → no new alert; finished attempt ingest → quarantined, no alert;
teacher reload → alerts persist; autosave+submit still work with AI active.
Real-model tests (separately reported, never "PASS" claims from fakes):
benchmark page/script measuring p50/p95 latency + effective FPS (WASM vs WebGPU) on synthetic frames,
plus real webcam headed run (P4-B realcam flow extended with AI on) — evidence screenshots + JSON.

## 8. Honesty rules (hard)

- Fake adapter output is labeled SIMULATED everywhere it appears (test names, UI when force-enabled, reports).
- Real-model capability claims only from the real benchmark runs.
- PERSON_NOT_OBSERVED is an observation of the model, not proof of absence.
- No auto cheating verdict, no score impact, no teacher auto-action. Evidence media is P4-D.
