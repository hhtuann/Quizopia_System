# P4 — API, Events & Data Contracts (Proposed v1)

**Status:** CONTRACT DRAFT, not implemented; 2026-11-13. Routes are illustrative, subject to API review and current backend conventions. No endpoint, schema or migration has been created by this document.

## 1. Common rules

- REST under `/api/...`, authenticated via existing Quizopia auth; teacher monitoring requires current DB permission `EXAM_SESSION_MONITOR` and exact `exam_sessions.created_by` owner match (or a separately approved scoped proctor grant in the future). Student endpoints bind session/attempt to authenticated `userId` server-side. Never trust userId, room, attempt association or role sent by caller.
- `schemaVersion: 1` on new monitoring configurations and all out-of-process events. JSON timestamps ISO-8601 UTC; DB server `TIMESTAMPTZ` authoritative for receipt and ordering. Pagination cursor opaque. No full answer payloads, raw frames or signed URLs in STOMP events/logs.
- `Idempotency-Key` header (UUID) for POST that can be retried (preflight start, clip request, review if requested); student activity uses event IDs. Rate limits, maximum body lengths, and safe error codes. Updates use `expectedVersion` / optimistic concurrency.
- Existing `POST /api/exam-sessions/{sessionId}/attempts` must keep legacy semantics for unmonitored Sessions and may accept optional `monitoringReadinessLease` in `StartAttemptRequest`. Do not break old clients. Backwards compatibility of `ATTEMPT_*` and `SERVER_TIME_SYNC` messages is required.
- No media service or AI callback may start/submit/grade an Attempt. Media control stays outside an open DB transaction.

## 2. Monitoring config

`POST /api/exams/{examId}/sessions` accepts optional monitoring object at creation (proposed extension to `CreateExamSessionRequest`); omitted means OFF. `PUT /api/exam-sessions/{sessionId}/monitoring/config` only when mutable. `GET /api/exam-sessions/{sessionId}/monitoring/config` for owner. `GET /api/exam-sessions/{sessionId}/monitoring/policy` for eligible learner (privacy notice and feature flags only, no storage secrets, teacher tokens or other learner identities).

```json
{
  "schemaVersion": 1,
  "expectedVersion": 4,
  "monitoringEnabled": true,
  "activityTrackingEnabled": true,
  "aiDetectionEnabled": true,
  "snapshotEvidenceEnabled": true,
  "fullRecordingEnabled": false,
  "clipEvidenceEnabled": true,
  "rollingBufferEnabled": true
}
```

**Response** includes `policyVersion`, `frozenAt`, `cameraRequired: true` derived from `monitoringEnabled`, `retention: { evidenceDays: 30, activityDays: 90 }`, `privacyNoticeVersion`. User-specified retention override is **not** allowed in v1 without a new approved policy. `PUBLIC`, no valid classes, false camera with Monitoring ON, AI-off/clip-on, or buffer-off/clip-on/full-off are invalid. All code paths editing class assignments or Session visibility must enforce constraints.

## 3. Student preflight (NEW Attempt)

### `POST /api/exam-sessions/{sessionId}/monitoring/preflights`
Request: `{ "schemaVersion": 1, "noticeVersionAcknowledged": "p4-notice-v1", "deviceCategory": "DESKTOP_BROWSER" }` (no device serial numbers). Backend verifies eligible class membership, monitoring policy and account; returns:

```json
{
  "preflightId": "d95a6fd0-eec3-4681-952a-6644589abf7a",
  "livekitWsUrl": "wss://media.example.invalid",
  "mediaToken": "<short-lived-opaque-token>",
  "mediaTokenExpiresAt": "2026-11-13T10:00:00Z",
  "cameraRequired": true,
  "roomScope": "opaque-session-room",
  "privacyNoticeVersion": "p4-notice-v1"
}
```

**Security:** Token is issued only server-side; no `canSubscribe`, mic or screen-share rights for learners; HTTPS and `Cache-Control: no-store`; avoid logging any raw token. Client does **not** choose media identity, room or Attempt.

### `POST /api/exam-sessions/{sessionId}/monitoring/preflights/{preflightId}/verify`

Request `{ "schemaVersion": 1 }`. Backend consults LiveKit RoomService and recent signed webhook/reconciliation for participant and active video track, maps to server-created preflight media epoch. If full recording enabled, recording coordinator must receive true started/running acknowledgement tied to the correct track (not final success). Returns:

```json
{
  "state": "READY",
  "readinessLease": "<one-time-random-token>",
  "readinessExpiresAt": "2026-11-13T10:01:00Z",
  "verifiedCameraTrackSid": "opaque-track-sid",
  "recordingState": "NOT_REQUESTED"
}
```

No raw server-signed lease in persistent logs; store hash, expiry, `policyVersion`, user and session binding. TTL **configured from tests** (design hypothesis ≤90s). If start transaction fails, lease remains usable or invalidates atomically according to idempotency; preflight objects must be disposed on expiry. Double-click/concurrent start must not allocate duplicate Attempts.

### `POST /api/exam-sessions/{sessionId}/attempts`

Existing `StartAttemptRequest` takes an **optional** `monitoringReadinessLease` beside `clientInstanceId`. For unmonitored Sessions, legacy payload unchanged. For new monitored Attempt, server locks Session, validates and atomically consumes fresh readiness lease, rechecks policy/track, creates Attempt and associates binding. If valid active Attempt already exists, use current resume path; do not block answer access while camera is reconnecting. Return existing `StartAttemptResponse` plus optional read-only monitoring status.

```json
{
  "clientInstanceId": "70714d10-4fd5-4f39-baad-51ba81e93e2d",
  "monitoringReadinessLease": "<one-time-random-token>"
}
```

**Errors**: `MONITORING_PREFLIGHT_REQUIRED` (409), `MONITORING_PREFLIGHT_EXPIRED` (409), `MONITORING_CAMERA_UNAVAILABLE` (409/503 according to cause), `MONITORING_POLICY_CHANGED` (409), `MONITORING_INFRA_UNAVAILABLE` (503), with sanitized user messages. Public/unauthorized user receives existing eligibility failure without leaking whether Session has camera monitoring.

## 4. Student activity ingestion

`POST /api/attempts/{attemptId}/monitoring/activity-events:batch` (a colon route must be approved per existing API style; alternative `/activity-events/batch` is acceptable and perhaps preferable). Design uses the latter for simplicity:

**`POST /api/attempts/{attemptId}/monitoring/activity-events/batch`**

```json
{
  "schemaVersion": 1,
  "clientBatchId": "c7c0c643-e552-4fc6-9f19-4ee61755fdb4",
  "clientInstanceId": "opaque-client-uuid",
  "events": [
    {
      "eventId": "0ee965b5-dd56-4e86-b572-2925a9b96f8d",
      "sequence": 43,
      "type": "TAB_HIDDEN",
      "clientOccurredAt": "2026-11-13T10:00:04.136Z",
      "meta": { "documentVisibility": "hidden" }
    },
    {
      "eventId": "2f81db2a-7802-4b56-a2a0-f3be676801fd",
      "sequence": 44,
      "type": "QUESTION_NAVIGATED",
      "clientOccurredAt": "2026-11-13T10:00:05.136Z",
      "meta": { "attemptQuestionId": 123 }
    }
  ]
}
```

Server binds to authenticated Attempt owner, validates allowed event type, `meta` shape per type, max 50 events and ≤32 KiB per batch (starting policy, load-test before final), rate-limits (starting policy e.g. ≤60 batches/min/Attempt), stamps `serverReceivedAt`, marks `source=BROWSER`/`trustLevel=CLIENT_OBSERVED`, and dedupes `(attemptId, clientInstanceId, eventId)` or globally unique eventId with ownership validation. Some late events after submission may be accepted within a bounded grace window as *observed late* but must never mutate Attempt/answers. Response:

```json
{"accepted": 2, "duplicates": 0, "rejected": 0, "serverReceivedAt": "2026-11-13T10:00:06Z"}
```

**Browser activity enum** (candidate): `ANSWER_SELECTED`, `ANSWER_CHANGED`, `ANSWER_CLEARED`, `QUESTION_NAVIGATED`, `QUESTION_FLAGGED`, `QUESTION_UNFLAGGED`, `TAB_HIDDEN`, `TAB_VISIBLE`, `WINDOW_BLURRED`, `WINDOW_FOCUSED`, `FULLSCREEN_ENTERED`, `FULLSCREEN_EXITED`, `PAGE_RELOADED`, `NETWORK_OFFLINE`, `NETWORK_ONLINE`, `AUTOSAVE_REQUEST_FAILED`. No essay text per keystroke. `ANSWER_SELECTED/CHANGED` stores question ID + answer type/metadata/hash if approved; not the full sensitive contents by default. Event capture must come from actual user intent/store transitions, never render or effect loop. Delivery best-effort; queue gaps are explicit.

## 5. Server accepted answer history

No new externally callable endpoint writes accepted answer history. Under `AttemptAutosaveService.saveAnswer` transaction: after `upsertIfNewer` returns affected=1, persist `accepted_sequence`, question ID, `accepted_at`, server-canonical value **hash** and optional approved data snapshot. Affected=0 does not write history. Preserve server sequence response, lock ordering, strict deadline, stale write semantics and atomicity. If history insert errors, **entire transaction rolls back**, preserving consistent answer and history. Unique index `(attempt_id, attempt_question_id, accepted_sequence)` and tests.

Teacher read: `GET /api/attempts/{attemptId}/monitoring/answer-history?cursor=...&limit=...` — requires explicit owner monitoring read + answer-history permission and time-appropriate answer disclosure. For essay questions default metadata/length/hash only; actual version content requires separately approved retention/security policy. Student may retrieve own history where product permits, never another student's.

## 6. Teacher REST read APIs

| Method & path | Proposed result | Authorization |
|---|---|---|
| `GET /api/exam-sessions/{id}/monitoring/overview` | `participantsStarted`, `attemptsInProgress`, `cameraConnected`, `cameraDisconnected`, `aiCoverageAvailable`, `alertsUnreviewed` + `asOf` | Owner + monitor permission |
| `GET /api/exam-sessions/{id}/monitoring/participants?cursor&limit&filter` | Server-paged participants with attempt/camera/alerts/status, no answer payload | Owner + monitor permission |
| `GET /api/attempts/{id}/monitoring/detail` | Current Attempt monitoring summary and recording availability | Owner + monitor permission, Attempt belongs to owned Session |
| `GET /api/attempts/{id}/monitoring/timeline?cursor&limit&kind&since&until` | Unified durable events (metadata), stable cursor + clock provenance | Owner + monitoring history permission |
| `GET /api/exam-sessions/{id}/monitoring/alerts?status&type&cursor&limit` | Aggregated alerts list | Owner + monitor permission |
| `GET /api/attempts/{id}/monitoring/recordings` | Logical recording and segment status; never raw private storage credentials | Owner + recording permission |
| `GET /api/monitoring/evidence/{assetId}/access` | Authorized short-lived MP4/snapshot access descriptor; for HLS playback use segment-aware gateway/session | Owner + evidence permission, audited |
| `GET /api/attempts/{id}/monitoring/report` | Counts by *raw detection*, *aggregate alert* and *teacher confirmed*, gaps, review status and retention info | Owner + report permission |

**Pagination example:**

```json
{
  "items": [
    {
      "eventId": "b575167c-b4f4-4e3f-af18-a25961fa80cb",
      "attemptId": 777,
      "type": "CAMERA_DISCONNECTED",
      "source": "MEDIA_VERIFIED",
      "trustLevel": "SERVER_VERIFIED",
      "displayOccurredAt": "2026-11-13T10:01:00Z",
      "serverReceivedAt": "2026-11-13T10:01:01Z",
      "late": false,
      "severity": "INFO",
      "evidenceAvailable": false
    }
  ],
  "nextCursor": "<opaque-cursor-or-null>",
  "serverAsOf": "2026-11-13T10:02:00Z"
}
```

Cursor must be stable under simultaneous writes and ordered by `(serverReceivedAt,id)`; `limit` clamped. Query and response must avoid revealing correct answers, grades before results access, or student emails. The frontend merges notifications by stable event ID; REST is authority on reconnect.

## 7. Teacher alert review

`POST /api/monitoring/alerts/{alertId}/reviews` with user-supplied reason only, authenticated teacher. Append to `monitoring_alert_reviews` and atomically update alert's current review status/version; preserve full history. Allowed actions: `MARK_VIEWED`, `FALSE_POSITIVE`, `NEEDS_FOLLOW_UP`, `NOTED`, `REVIEWED_NO_CONCLUSION`. Do not expose `CHEATED` or create any automated academic penalty transition.

```json
{
  "expectedVersion": 3,
  "action": "FALSE_POSITIVE",
  "note": "Lighting artefact; no visible phone in evidence."
}
```

Response: new `reviewVersion`, `reviewStatus`, `reviewedAt`. Repeated idempotency key returns same result; conflicting version returns 409.

## 8. Monitoring STOMP envelope (separate from existing frozen session envelope)

Propose new strictly allowlisted teacher destination `/topic/monitoring/sessions/{sessionId}` (and optional student-targeted `/user/queue/monitoring`). Existing `StompSubscribeInterceptor` currently only permits session topic and personal attempt queue, so must **explicitly add route patterns and owner checks**; preserve `StompSendGuardInterceptor` rejecting all inbound SEND/MESSAGE. No PII or evidence URL in realtime payload.

```json
{
  "schemaVersion": 1,
  "eventId": "09bb24e9-c569-48d8-a5c8-fc7d43f7e996",
  "eventType": "MONITORING_ALERT_CREATED",
  "sessionId": 15,
  "attemptId": 777,
  "aggregateId": "7dba1ca8-d647-401e-b5d9-1cdbebdcc890",
  "occurredAt": "2026-11-13T10:01:04Z",
  "serverTime": "2026-11-13T10:01:05Z",
  "cursorHint": "<opaque-watermark>"
}
```

Other candidate types: `MONITORING_CAMERA_STATE_CHANGED`, `MONITORING_AI_COVERAGE_CHANGED`, `MONITORING_RECORDING_STATE_CHANGED`, `MONITORING_ALERT_UPDATED`, `MONITORING_REVIEW_RECORDED`, `MONITORING_ACTIVITY_ADDED`. **Outbox**: create durable notification intent in same transaction as alert, dispatch after commit/retry. On lost STOMP, client fetches timeline/list since cursor (idempotent). Existing event enum must be backward-compatible: no surprise answer payloads in legacy envelope.

## 9. AI internal callback

`POST /internal/monitoring/v1/detections` — network-restricted and authenticated service identity; request contains model claim, opaque media identity, track/epoch/time and detection. Backend verifies worker signature/mTLS, event replay guard, allowed model/version, room/participant binding, Attempt coverage period and idempotency. **Do not accept arbitrary userId/attemptId from AI.**

```json
{
  "schemaVersion": 1,
  "eventId": "2535d6ee-9ee2-48e6-9114-5cf29abfac43",
  "workerId": "ai-worker-01",
  "modelId": "phone-detector",
  "modelVersion": "UNVERIFIED",
  "thresholdProfileVersion": "pilot-v1",
  "roomIdentity": "opaque-session-room",
  "mediaParticipantIdentity": "opaque-media-identity",
  "trackSid": "opaque-track-sid",
  "mediaEpoch": 2,
  "type": "PHONE_DETECTED",
  "observedAt": "2026-11-13T10:01:03Z",
  "confidence": 0.91,
  "durationMs": 2200,
  "boxes": [],
  "snapshotObjectRef": "private-object-ref-or-null"
}
```

**Important:** `modelVersion`, `confidence`, observedAt in the example are **test fixture values, not real-model findings**. `snapshotObjectRef` is accepted only if object metadata/service identity/checksum matches authorized evidence storage. A callback lacking a valid historical media/Attempt binding → reject or quarantine, never attribute to latest Attempt. Duplicate returns 200 idempotently; transient 5xx retry with bounded exponential backoff, non-retryable 4xx quarantined. Rate limits/size caps and service `outbox` required.

**Event aggregation:** a raw frame detection can update one active alert window. `MONITORING_ALERT_CREATED` only for newly opened window; subsequent qualifying samples update existing alert with count/duration/peak confidence. Thresholds/timing config is versioned **after** model evaluation. For late arrival, sort within bounded window using observed time, never reorder authoritative Attempt lifecycle. Provide explicit gaps when AI off.

## 10. LiveKit signed webhook ingress

`POST /internal/media/v1/livekit/webhooks` — validate official signed webhook format using raw body and signature; process `participant_joined`, `participant_left`, `participant_connection_aborted`, `track_published`, `track_unpublished`, `egress_started`, `egress_updated`, `egress_ended`. Check idempotency `(webhookId)`. Signed callbacks are **hints**, not infallible authoritative full state: webhook delivery/retry is not guaranteed; reconcile via RoomService/Egress API/Storage HEAD on timer and startup. Never derive real Attempt identity from unverified participant name. Generate camera incidents and recording state transitions with bounded lateness.

## 11. Evidence capture + playback contract

`monitoring_evidence_assets.kind`: `SNAPSHOT`, `ALERT_CLIP`, `RECORDING_SEGMENT`. States `PENDING_UPLOAD`, `AVAILABLE`, `FAILED`, `EXPIRED`, `HELD` (future dispute/legal-hold extension). Record `sha256`, byte size, content type, approximate resolution, createdAt, expiresAt, capture observation event, model version (when appropriate). Never store S3 root secrets in DB.

`GET /api/monitoring/evidence/{assetId}/access` returns either `{ mode: "SIGNED_OBJECT", url, expiresAt }` for a single object **after** audit or `{ mode: "PLAYBACK_SESSION", playbackUrl, expiresAt }` for multi-segment HLS requiring segment-scoped auth. A signed playlist URL that contains unsigned segment URLs is forbidden. On expired media, return state `EXPIRED` with metadata and no presigned URLs.

## 12. Recording coordinator contract

Internal lifecycle actions: `startAttemptRecording(preflightId, mediaBinding)`, `bindRecordingToAttempt(egressId, attemptId)`, `startSegment(mediaBinding)`, `finalizeRecording(attemptId)`, `reconcileEgress(egressId)`, `expireOrphanPreflightRecording(preflightId)`. These are application methods and jobs **not necessarily public endpoints**. Each has idempotency key and durable state. Reconcile Egress webhook status with S3 `HEAD`; expose `PENDING/STARTING/RECORDING/FINALIZING/AVAILABLE/PARTIAL/FAILED/EXPIRED` to teacher. `FILE AVAILABLE` requires confirmed actual object. Video-only. A lost connection produces a new segment + explicit coverage gap. Never keep an open JDBC transaction while waiting for Egress.

## 13. Security and status code contract

| Condition | Proposed code | HTTP | Note |
|---|---|---:|---|
| Monitoring on PUBLIC | `MONITORING_NOT_ALLOWED_FOR_PUBLIC` | 422 | Backend check |
| No eligible assigned class | `MONITORING_REQUIRES_CLASS` | 422 | Also deny last-class removal |
| Invalid option combination | `MONITORING_INVALID_CONFIGURATION` | 422 | Stable validation details |
| Policy frozen | `MONITORING_POLICY_FROZEN` | 409 | Session time/start/Attempt |
| Missing readiness | `MONITORING_PREFLIGHT_REQUIRED` | 409 | For new monitored Attempt only |
| Lease expired/replayed | `MONITORING_PREFLIGHT_EXPIRED` | 409 | No implicit bypass |
| Camera currently disconnected | `MONITORING_CAMERA_NOT_READY` | 409 | Learner actionable message |
| Media infra unavailable | `MONITORING_MEDIA_UNAVAILABLE` | 503 | Attempt not created if new required preflight unavailable |
| Cross-session/cross-user evidence | `MONITORING_ACCESS_DENIED` | 403 or 404 | Match existing anti-enumeration policy |
| AI event no valid binding | `MONITORING_EVENT_UNATTRIBUTABLE` | 422 | Do not mis-attribute |
| Evidence physically expired | `MONITORING_EVIDENCE_EXPIRED` | 410 | Metadata may remain |
| Conflict in alert review | `MONITORING_REVIEW_CONFLICT` | 409 | expectedVersion mismatch |

Only allowed/error-safe detail messages; no storage URL/token/secret leak. Existing Attempt error and response contracts preserved for unmonitored Sessions.

## 14. Version compatibility and data migration

Use additive migration only; latest baseline Flyway V32; implementation must check current latest and choose unused next version. Backend new optional fields default OFF; frontends on older release must still start PUBLIC and nonmonitored CLASS_RESTRICTED attempts. When monitoring required, an old client must be **fail-closed at the new start gate**, with a clear unsupported-client error, not silent bypass. Rolling upgrade matrix: old FE/new BE, new FE/old BE and compatible policy fallback. Version all internal AI and STOMP envelopes, reject unknown critical versions rather than silently accepting partial detections. Test migrations fresh/upgrade and rollback-by-forward-fix; never edit past migration.

## 15. Security & review tests tied to contracts

- Forged `attemptId`, `userId`, `room`, trackSid, cross-session `assetId`, teacher ownership and revoked role.
- Student publishes camera only; attempts subscribe or publish microphone/screen via malicious token are denied.
- Expired/replayed readiness lease, two simultaneous starts, media room replacement, preflight no actual video, egress-before-start failed.
- Duplicate/late/reordered AI and LiveKit callbacks, wrong epoch, stale tokens in self-host after RemoveParticipant, signed webhook spoof.
- Answer concurrency: accepted history once; stale saves ignored; submit/autosave race; DB error in history rolls back answer.
- Camera disconnected: Attempt continues; grade matches monitoring-OFF behavior; truthful recording/AI gap.
- MP4 Range and multi-segment HLS playback authorization; audit and deletion/tombstone lifecycle.
- STOMP spoof and forged monitoring subscription blocked; reconnect via REST recovers complete timeline.

## 16. Explicitly open issues / thresholds (not silently decided)

Model inference FPS, dynamic frame budgets, confidence/temporal rules, GPU type, actual room capacity, low-level LiveKit API versions and exact TTL/retry limits require P4-0/P4-C/P4-F evidence. Formal regulatory/minor workflows and production storage provider are deferred for a course demo; see ADR-008 for future-use restrictions. Example IDs/times/thresholds in this file are demonstrations, not deployed settings.

**Supporting refs:** https://docs.livekit.io/frontends/reference/tokens-grants/ ; https://docs.livekit.io/transport/media/ingress-egress/egress/ ; https://docs.livekit.io/transport/media/ingress-egress/egress/outputs/ ; https://docs.livekit.io/intro/basics/rooms-participants-tracks/webhooks-events/ .


## Academic demo contract profile (2026-11-14)

No REST, WebRTC, STOMP or AI callback contract is weakened for a course demo. Demo mode is a documented **fixture/environment policy**, not an authorization bypass. All camera/media/answer/evidence access rules remain server-enforced.

The acceptance target for this profile is **5 real publishers, target 10**; no 30/50/100 throughput SLA is implied. Synthetic camera feeds are permitted for deterministic integration tests if explicitly distinguished from physical webcams; AI stub detections cannot be presented as real-model output. Cross-service callback authentication and object storage private access are still mandatory.
