# P4-E — Unified Monitoring Dashboard, Alert Review & Reports (Design v1)

Status: IMPLEMENTATION CONTRACT — 2026-11-17. Baseline: post-P4-D mains
(System `e03a69a`, Backend `72446a6`, Frontend `09bbc75`). ADR-010 governs decisions.

## 1. Scope split

|Slice|Deliverable|
|---|---|
|E1 Backend|`/monitoring/overview`, `/monitoring/participants` (cursor), review events in the unified timeline|
|E1 Frontend|`MonitoringDashboard` section (KPIs + participants table + camera grid merge + attempt drilldown), filters, reload/reconnect backfill|
|E2 Backend|`POST/GET /api/monitoring/alerts/{alertId}/reviews` (append-only, idempotent, optimistic version), alert feed review fields/filter|
|E2 Frontend|Review controls + history in the alert card; attempt monitoring report view + printable route|
|Report Backend|`GET /api/attempts/{attemptId}/monitoring/report` — read-time aggregation|

## 2. Data model (V42__alert_review_and_dashboard.sql)

```sql
CREATE TABLE monitoring_alert_reviews (
    id                       BIGSERIAL PRIMARY KEY,
    alert_id                 BIGINT NOT NULL REFERENCES monitoring_ai_alerts(id) ON DELETE CASCADE,
    reviewer_user_id         BIGINT NOT NULL REFERENCES users(id),
    action                   VARCHAR(24) NOT NULL,          -- MARK_VIEWED | FALSE_POSITIVE | NEEDS_FOLLOW_UP | NOTED | REVIEWED_NO_CONCLUSION
    note                     VARCHAR(1000),                 -- NULL or <=1000 chars
    review_version           INT NOT NULL,                  -- 1-based per alert
    previous_action          VARCHAR(24),
    previous_review_version  INT,
    idempotency_key          UUID NOT NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_alert_reviews_idem UNIQUE (idempotency_key),
    CONSTRAINT uk_alert_reviews_version UNIQUE (alert_id, review_version),
    CONSTRAINT chk_review_action CHECK (action IN ('MARK_VIEWED','FALSE_POSITIVE','NEEDS_FOLLOW_UP','NOTED','REVIEWED_NO_CONCLUSION')),
    CONSTRAINT chk_review_note CHECK (note IS NULL OR char_length(note) <= 1000)
);
ALTER TABLE monitoring_ai_alerts
    ADD COLUMN review_status VARCHAR(24) NOT NULL DEFAULT 'UNREVIEWED'
        CHECK (review_status IN ('UNREVIEWED','VIEWED','FALSE_POSITIVE','NEEDS_FOLLOW_UP','NOTED','REVIEWED_NO_CONCLUSION')),
    ADD COLUMN review_version INT NOT NULL DEFAULT 0,
    ADD COLUMN reviewed_by BIGINT REFERENCES users(id),
    ADD COLUMN reviewed_at TIMESTAMPTZ;
-- attempt_activity_events: + 'ALERT_REVIEW_RECORDED' in the type CHECK (V40 precedent).
-- permissions: + MONITORING_ALERT_REVIEW (TEACHER only).
```

`ALERT_REVIEW_RECORDED` metadata: `{alertId, reviewId, action, reviewVersion}` — drilldown
refs only, no note content in the timeline (notes are review-surface data).

## 3. API contracts (exact DTO field names)

Auth for all: effective-permission check + `exam_sessions.created_by == userId`
(`MONITORING_ACCESS_DENIED` otherwise, identical message for missing/foreign).

### 3.1 `GET /api/exam-sessions/{sessionId}/monitoring/overview`
`AI_ALERTS_READ`. →
```json
{"sessionId":1,"asOf":"…","monitoringEnabled":true,
 "attempts":{"total":3,"inProgress":2,"submitted":1,"graded":0},
 "camera":{"policyRequired":true,"connected":2,"reconnecting":0,"idle":1,"revoked":0},
 "ai":{"enabled":true,"openAlerts":2,"closedAlerts":1,"unreviewedAlerts":3,"lastDetectionAt":"…|null"},
 "recording":{"fullRecordingEnabled":false,"rollingBufferActive":true,"activeJobs":1,"completeJobs":2,"failedJobs":0},
 "evidence":{"available":5,"partial":1,"pending":0,"failed":0,"expired":0}}
```

### 3.2 `GET /api/exam-sessions/{sessionId}/monitoring/participants?cursor&limit&status&cameraState&reviewStatus`
`AI_ALERTS_READ`. limit clamp 10..100 (default 50); cursor = opaque numeric (last attemptId,
DESC like the alert feed). →
```json
{"sessionId":1,"items":[{
  "attemptId":7,"userId":42,"displayName":"An","attemptNumber":1,"attemptStatus":"IN_PROGRESS",
  "startedAt":"…","deadlineAt":"…","submittedAt":null,"lastActivityAt":"…|null",
  "camera":{"state":"CONNECTED","connectedSince":"…","lastVerifiedAt":"…","mediaIdentity":"…"},
  "ai":{"lastDetectionAt":"…|null","openAlerts":1,"totalAlerts":2,"unreviewedAlerts":2},
  "recording":{"mode":"ROLLING","activeJobs":1,"completeJobs":2,"failedJobs":0},
  "evidence":{"snapshots":1,"clips":1}},
  "reviewStatus":"UNREVIEWED"}],
 "nextCursor":"…|null"}
```
Filters: `status` (attempt status), `cameraState` (CONNECTED|RECONNECTING|IDLE|REVOKED|NONE),
`reviewStatus` (UNREVIEWED|VIEWED|FALSE_POSITIVE|NEEDS_FOLLOW_UP|NOTED|REVIEWED_NO_CONCLUSION —
matched against the student's worst/unreviewed alert presence; implemented as a HAVING-style
post-filter on the page query, deterministic under cursor).
`camera.state=NONE` = no binding at all (never connected) — honest absence, distinct from IDLE.

### 3.3 Review — `POST /api/monitoring/alerts/{alertId}/reviews` (`Idempotency-Key: <uuid>` header)
`MONITORING_ALERT_REVIEW`. Body `{"expectedVersion":0,"action":"FALSE_POSITIVE","note":"…?"}`
(note ≤1000 chars, optional; action enum above). →
```json
{"alertId":9,"reviewVersion":1,"reviewStatus":"FALSE_POSITIVE","action":"FALSE_POSITIVE",
 "note":"…","reviewerUserId":5,"reviewedAt":"…","idempotentReplay":false}
```
Rules: same key ⇒ replay stored outcome (`idempotentReplay:true`), even after later reviews;
`expectedVersion != alert.reviewVersion` ⇒ 409 `MONITORING_REVIEW_VERSION_CONFLICT` (message
includes current version); review append + denormalized alert update + `ALERT_REVIEW_RECORDED`
activity event in ONE transaction (recorder is MANDATORY-tx ⇒ service method is the tx).
Never mutates detection/alert detector fields, grades, attempt or session status.

### 3.4 `GET /api/monitoring/alerts/{alertId}/reviews`
`AI_ALERTS_READ` + owner. →
```json
{"alertId":9,"currentReview":{"status":"FALSE_POSITIVE","version":1,"reviewedAt":"…","reviewerName":"Te"},
 "history":[{"version":1,"action":"FALSE_POSITIVE","note":"…","reviewerName":"Te","reviewedAt":"…"}]}
```
(currentReview null-shaped `{status:"UNREVIEWED",version:0,…}` when none.)

### 3.5 Alert feed extension (existing `GET /api/exam-sessions/{id}/ai-alerts`)
`Item` += `reviewStatus`, `reviewVersion`, `reviewedAt`; `review` filter param added.
Additive; page stays newest-first by alertId.

### 3.6 `GET /api/attempts/{attemptId}/monitoring/report`
`AI_ALERTS_READ` + attempt's session owner. Works for IN_PROGRESS/SUBMITTED/GRADED, any
session status. →
```json
{"attempt":{…identity+window…},"policy":{…P4-D MediaPolicy fields…},
 "monitoringWindow":{"from":"…","to":"…","minutes":42},
 "activity":{"totalEvents":120,"answerAccepted":18,"distinctQuestionsAnswered":9,
   "browser":{"tabHidden":2,"tabVisible":2,"focusLost":3,"focusGained":3,"pageReload":1,"connectionLost":1},
   "byType":{"TAB_HIDDEN":2,…}},
 "camera":{"neverConnected":false,"connectedPeriods":[{"from":"…","to":"…"}],
   "disconnectPeriods":[{"from":"…","to":"…"}],"monitoringGaps":1,"lastEvent":"CAMERA_RECONNECTED"},
 "recording":{"mode":"ROLLING","segments":[{"jobId":"…","status":"COMPLETE","startedAt":"…","endedAt":"…","bytes":936000,"durationMs":30000,"objectDeleted":false,"expiresAt":"…"}],
   "gaps":[{"from":"…","to":"…","seconds":12.4}],"coverageRatio":0.97},
 "ai":{"rawDetections":41,"quarantined":2,"groupedAlerts":3,"openAlerts":0,"closedAlerts":3,
   "reviewedAlerts":2,"unreviewedAlerts":1,"falsePositives":1,
   "models":[{"modelId":"yolo26s","modelVersion":"8.4.64-onnx","provenance":"CLIENT_MODEL","runtime":"ORT_WEB_WASM","detections":41}],
   "limitsNote":"Browser-side ONNX inference, thresholds 0.5; observations only — never a verdict."},
 "evidence":[{"evidenceId":"…","kind":"SNAPSHOT","status":"AVAILABLE","provenance":"CLIENT_CAPTURE",
   "capturedAt":"…","windowStart":null,"windowEnd":null,"bytes":123,"sha256":"…","expiresAt":"…","alertId":9,
   "playbackRef":"/api/exam-sessions/1/evidence/<id>/url"}],
 "reviews":[{"reviewId":1,"alertId":9,"action":"FALSE_POSITIVE","note":"…","reviewerName":"Te","reviewedAt":"…","version":1}],
 "retention":{"mediaRetentionDays":30,"activityRetentionDays":90,"asOf":"…"},
 "disclaimer":"Monitoring observations only. No automated misconduct verdict; human review required."}
```
Invariants: rawDetections = non-quarantined detection rows; groupedAlerts = alert windows;
reviewedAlerts = DISTINCT alerts having ≥1 review (≠ review rows); never joins
`grades`/`grade_items`; EXPIRED/FAILED evidence listed with status, `playbackRef` omitted for
unplayable states; recording gaps = >2s holes between COMPLETE non-deleted segments
(P4-D UI rule).

## 4. Frontend composition

Session detail gains `MonitoringDashboard` (monitored sessions only), inserted above
CameraGridCard; LiveMonitor stays for unmonitored. All new components live under
`components/teacher/monitoring/`; existing cards are reused, not forked.

- **KPI row**: MetricCards from overview; `aria-live` asOf; STOMP ping invalidation adds
  `monitoring-overview`/`monitoring-participants` keys (existing `onAttemptActivity` router).
- **ParticipantsTable**: one row per attempt — status chips (attempt, camera state, AI
  unreviewed count, recording, review); row click selects the attempt for the drilldown;
  filters (status/camera/review) drive the query key; loading/empty/failed/disconnected
  visual states distinct.
- **Attempt drilldown**: existing `TeacherActivityPanel` picker is driven by the same
  selection; timeline filters already exist (source/type-group); add review-status filter via
  `types=ALERT_REVIEW_RECORDED` toggle. Alert→evidence drilldown stays in EvidenceSection
  (alert chip already exists); AiAlertCard gains review controls + history disclosure +
  provenance distinction chips: "AI phát hiện" (detector fields) vs "Giảng viên đánh giá"
  (review fields) vs "Chưa được xác minh" (UNREVIEWED).
- **Review form**: action SegmentedControl + note textarea (maxLength 1000, counter),
  optimistic-version taken from the alert row; 409 surfaces current version with retry;
  idempotency key per submit intent (uuid regenerated after success/conflict-ack).
- **Report**: `MonitoringReportCard` (attempt picker → fetch) on session detail + dedicated
  printable route `app/(teacher)/exams/[examId]/sessions/[sessionId]/monitoring-report/[attemptId]/page.tsx`
  (server-light client page, `@media print` rules, no nav chrome, section page-breaks,
  browser print button). Counts render as three clearly separated stat groups
  (detections / alerts / reviews). Evidence rows show status chips; EXPIRED rows render
  metadata only, no play button.
- **Shared util**: `lib/utils/format.ts` (`formatTime`, `formatDateTime`) — new components
  only, no mass refactor.
- **Query keys**: `["exam-sessions",id,"monitoring-overview"]`,
  `["exam-sessions",id,"monitoring-participants",filters]`, `["alerts",alertId,"reviews"]`,
  `["attempts",id,"monitoring-report"]`. Review mutations invalidate alerts feed +
  participants + overview + selected timeline.

## 5. Test matrix (gates)

Backend (Testcontainers): review happy/409/idempotent-replay/IDOR (student, foreign
teacher)/note-length; review events in timeline; overview/participants counts vs fixtures;
participants cursor determinism + filters; report aggregation exactness (no double counting,
camera periods, gaps, EXPIRED honesty, no grade fields in payload — asserted by JSON scan);
migration matrix V42. Frontend: vitest for new components/api builders/report formatting.
E2E (real browser, synthetic cameras — 5 real WebRTC transports): dashboard render from
persisted data, review + history, report after session close, reload backfill, IDOR negative,
printable route.

## 6. Non-goals

No automated verdicts/scores, no new STOMP topics, no cross-session dashboard, no
virtualization (caps suffice), no physical-webcam claims (P4-F #98), no retention changes.

## 7. Pre-merge hardening amendments (2026-11-17 gate)

- **F01**: the review append runs in a REQUIRES_NEW transaction (orchestrator
  method holds no outer tx); a lost unique race rolls back atomically and the
  idempotency probe runs on the caller's clean connection. Real-concurrency
  regression: `AlertReviewConcurrencyIntegrationTests`.
- **F02**: camera connected/disconnected periods are clamped to
  `[startedAt, submittedAt|now]`; degenerate (tied) ranges are dropped.
- **F03**: ALL participant filters (status/cameraState/reviewStatus incl. the
  per-state review aggregate and the REVIEWED wildcard) execute inside the
  attemptId-DESC keyset SQL — filtered pagination is complete; one lateral
  query per page (no per-row N+1).
- **F04**: signals are separated — `camera.online` (transport) vs
  `camera.publishing` (verified track) vs state; `ai.enabled/detections/
  quarantined` distinct from alert rollups; `teacherSubscriptionState` is
  honestly `NOT_AVAILABLE` (the backend cannot observe the teacher's LiveKit
  subscription; the teacher UI uses its own room handle).
- **F06**: `coverageRatio` = union of COMPLETE-segment intervals clamped to
  the monitoring window ÷ window length; the gap list includes leading and
  trailing window holes. Exact-value tests.
- **F07**: overview/participants resolve each user's LATEST binding only
  (`DISTINCT ON ... active_from DESC, id DESC`); historical REVOKED bindings
  never override newer state.
- **F08**: timeline gains server-side time-range filters (from/to inputs in
  the UI, part of the query key so a range change restarts pagination).
  Provenance = the existing source dimension (CLIENT/SERVER). Severity is
  NOT recorded anywhere in the event schema — deliberately not invented.
- **F09**: review mutations and evidence/recording/review STOMP pings (and
  reconnect backfill) also invalidate `["attempts", id, "monitoring-report"]`;
  an already-open report refreshes without loops (mutation/ping-driven only).
- **Report hardening**: legacy sessions without a policy row read all-OFF
  (never 500); evidence listing bounded to newest 100 rows, reviews to 200
  (chronological display preserved); the AI limits note cites the client
  hook's threshold policy as its source.
- **F05**: report segments with a `playbackRef` render an on-demand Play
  control minting the audited P4-D recording URL when clicked (no pre-mint,
  no dead links for non-playable rows).
- **Retention verification**: media 30d + access-log 90d are enforced by
  `EvidenceRetentionJob`. Activity events and review metadata currently have
  NO automated sweep — a pre-existing P4-A scope gap, NOT introduced or
  widened by P4-E; enforcing deletion there is a product decision handed to
  P4-F (deleting unified-timeline history has durability implications this
  phase must not decide).
