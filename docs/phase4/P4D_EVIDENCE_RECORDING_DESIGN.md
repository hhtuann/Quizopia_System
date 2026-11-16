# P4-D — Evidence & Recording: Technical Design (issues #91–#94)

Companion to `backend/docs/adr/ADR-009-phase4-evidence-and-recording.md` (decision
record). This file is the working contract: API surface, tables, lifecycle
rules, frontend surfaces, and the acceptance test matrix.

## 1. Provenance & honesty rules (binding)

- `CLIENT_CAPTURE` = a JPEG the student's browser grabbed from the same
  `MediaStream` the detector ran on. Server verifies ownership, policy,
  bounds, JPEG magic, SHA-256 — **not** frame content. UI labels it
  "Ảnh do máy thí sinh gửi" (browser-captured), never "verified".
- `FULL_RECORDING` / `ROLLING_BUFFER` = MP4 written by LiveKit Egress
  (video-only; `audio_track_id` omitted at the request level). Metadata from
  authoritative `EgressInfo.FileInfo` (name/size/duration/start/end).
- A clip is **never** fabricated: `ROLLING_BUFFER` pulses run from camera
  connect (before any alert); coverage math decides `AVAILABLE` / `PARTIAL` /
  `FAILED(NO_COVERAGE|FFMPEG_*)`; gaps are stored in `coverage_json`.
- Bounding boxes/JSON are **not** evidence. `AVAILABLE` requires a HEAD-able
  object (egress-written files: FileInfo size>0 + HEAD; backend-written:
  SHA-256 re-verified after PUT).

## 2. Data model (V40)

```
monitoring_recording_jobs   one row per egress run (FULL continuous or ROLLING pulse)
  id UUID PK, exam_session_id, attempt_id, binding_id FK, kind('FULL'|'ROLLING'),
  egress_id UNIQUE, room_name, track_sid, status('STARTING'|'ACTIVE'|'ENDING'|
  'COMPLETE'|'FAILED'|'ABORTED'), pulse_index INT, started_at, ended_at,
  object_key, bytes, duration_ms, error TEXT, object_deleted BOOL,
  created_at, updated_at
monitoring_evidence         snapshots + clips
  id UUID PK, exam_session_id, attempt_id, alert_id NULL FK, binding_id NULL,
  kind('SNAPSHOT'|'CLIP'), status('PENDING'|'AVAILABLE'|'PARTIAL'|'FAILED'|'EXPIRED'),
  provenance('CLIENT_CAPTURE'|'FULL_RECORDING'|'ROLLING_BUFFER'),
  idempotency_key UNIQUE NULL, object_key, content_type, sha256 CHAR(64),
  bytes, width, height, captured_at, window_start, window_end,
  coverage_json JSONB, error TEXT, created_at, updated_at, expires_at
monitoring_evidence_access  audit: evidence_id FK, user_id, action
  ('URL_MINTED'|'PLAYBACK'), accessed_at   [90d retention]
```

New activity types (server-source only): `RECORDING_STARTED`,
`RECORDING_STOPPED`, `RECORDING_FAILED`, `EVIDENCE_SNAPSHOT_UPLOADED`,
`EVIDENCE_SNAPSHOT_REJECTED`, `EVIDENCE_CLIP_REQUESTED`,
`EVIDENCE_CLIP_READY`, `EVIDENCE_CLIP_FAILED`.

New permission: `MONITORING_EVIDENCE_READ` (TEACHER only, like
`MONITORING_CAMERA_MANAGE`).

Policy change (P4-A V33 rule relaxed): `evidence_clips` no longer requires
`full_recording`; with recording OFF it enables the rolling buffer. Still
requires `monitoring_enabled` and (per P4-A) `ai_detection` for alert-driven
clips? No — clips require only monitoring; snapshots keep requiring AI.

## 3. API surface

### Student (JWT, attempt owner, IN_PROGRESS)
- `POST /api/attempts/{attemptId}/evidence/snapshots` — multipart
  (`image/jpeg` ≤ 2 MiB, fields `alertId`, `idempotencyKey`,
  `capturedAt` epoch-ms). Binds: ≤3 per alert, ≤30 per attempt,
  alert belongs to the attempt, policy `evidenceSnapshotsEnabled`.
  Idempotent on `idempotencyKey` (repeat = 200 + existing row).
  → `EvidenceSnapshotResponse{evidenceId,status,provenance:'CLIENT_CAPTURE'}`.
- Ingest response extension (P4-C DTO, backward compatible):
  `AiDetectionBatchResponse.results[i].snapshotRequest =
  {alertId, reason:'ALERT_OPENED'}` when this event opened a window and the
  policy enables snapshots — the client captures the *current* frame then.
- `GET /api/attempts/{attemptId}/monitoring/media-status` —
  `{fullRecordingEnabled, evidenceClipsEnabled, snapshotsEnabled}` for the
  student indicator + first-join notice (read-only projection of the frozen
  policy; no teacher-config surface).

### Teacher (MONITORING_EVIDENCE_READ + session ownership)
- `GET /api/exam-sessions/{sessionId}/evidence?alertId=&kind=&status=`
  → page of evidence metadata (no URLs).
- `POST /api/exam-sessions/{sessionId}/ai-alerts/{alertId}/clip` → creates
  `CLIP` PENDING (window = firstDetectedAt−30s … lastDetectedAt+60s, cap 5
  min); idempotent per (alertId, provenance-mode) while PENDING/AVAILABLE.
  → `EvidenceResponse`.
- `GET /api/exam-sessions/{sessionId}/evidence/{evidenceId}/url` →
  `{url, expiresAt}` presigned GET (300 s); mints an audit row.
- `GET /api/exam-sessions/{sessionId}/recordings?attemptId=` → per-attempt
  segments (start/end/bytes/duration/status/objectDeleted) + derived gaps.

### Internal (egress webhook)
- Existing `POST /internal/media/v1/livekit/webhooks` now also routes
  `egress_started|egress_ended|egress_updated` → recording job updates.

## 4. Recording coordinator state machine

```
camera track_published (binding w/ attempt IN_PROGRESS)
  └─ AFTER_COMMIT → policy: fullRecording ? start FULL : (clips ? start ROLLING pulse)
       FULL:    egress run until track_unpublished/participant_left/submit/timeout
       ROLLING: pulse (120 s default) → on COMPLETE: keep-last-N (delete older
                objects), schedule next pulse while camera open
egress webhooks (dedupe ledger): STARTING/ACTIVE/ENDING → mirror status;
  COMPLETE → copy FileInfo{object,size,duration,start,end} + RECORDING_STOPPED
  activity; FAILED/ABORTED → RECORDING_FAILED activity (never exam-affecting)
track termination / submit / session close → StopEgress (best effort, retried
  by reconcile job listing active egress on the room)
```

All egress/storage calls run outside DB transactions
(`@TransactionalEventListener(AFTER_COMMIT)` + the gateway's
assertNoTransaction guard, same as RoomService).

## 5. Clip extraction job

1. Covering segments: `monitoring_recording_jobs` rows for the attempt
   (`kind` per provenance mode) intersecting `[windowStart, windowEnd]`.
2. No intersection → `FAILED/NO_COVERAGE` (honest: buffer/recording did not
   exist then). Partial → produce clip, `PARTIAL` + `coverage_json.gaps`.
3. ffmpeg: presigned GET inputs, per-input `-ss/-to`, `-c copy`,
   `-movflags +faststart`, temp file → PUT `clips/{id}.mp4` → SHA-256 →
   AVAILABLE/PARTIAL. ffmpeg absent/fails → `FAILED/FFMPEG_*`.
4. Alert times are client-observed clocks; pulses/segments are server clocks.
   Window is widened by a skew margin (±5 s) before coverage math, gaps
   smaller than 2 s are ignored (pulse restart cost), both honest in metadata.

## 6. Frontend surfaces

- Student attempt page: `RecordingStatusPill` (clone of CameraStatusPill
  contract) fed by `media-status`; first-render notice
  "Phiên này đang ghi hình"/"Đang lưu đệm 2 phút phục vụ cắt clip" when on.
  Snapshot capture in `use-attempt-ai-detection` `handleFrame` on
  `snapshotRequest` from the ingest response (canvas → JPEG 0.85 → upload);
  transient pill state "Đã gửi ảnh minh chứng".
- Teacher LiveMonitor `AiAlertFeed`: per-alert evidence row — snapshot
  thumbnails (label "Ảnh do máy thí sinh gửi"), "Tạo clip" button with
  PENDING/AVAILABLE/PARTIAL/FAILED/EXPIRED states, `<video controls>` using
  the signed URL (re-fetched on expiry), seek-to-alert offset = window start.
  `MonitoringSection`: clips option no longer disabled by recording OFF.
- No new STOMP topics: EVIDENCE_*/RECORDING_* activity events invalidate the
  evidence queries through the existing session-topic pipeline.

## 7. Security matrix (tested)

| Actor | Snapshots | Clips/URL | Recordings | Storage creds |
|---|---|---|---|---|
| Owning student | upload own attempt only | none | none | none |
| Other student | 404/403 | 403 | 403 | none |
| Owning teacher | read+URL (audit) | create+read+URL (audit) | read+URL (audit) | none |
| Foreign teacher | 404 (ownership check first) | 404 | 404 | none |
| Frontend | — | — | — | never |

Storage: single private bucket `quizopia-evidence`; MinIO root creds live
only in backend env; presign TTL 300 s; every URL mint audited.

## 8. Retention & cleanup (tested)

- Hourly job: evidence past `expires_at` → object delete + `EXPIRED`;
  access-log rows > 90 d purged; rolling pulse objects beyond keep-N deleted
  (row keeps metadata, `object_deleted=true`); orphan reconciliation deletes
  unreferenced `rolling/`/`recordings/` objects older than 1 h.
- Manual demo purge: `DELETE /api/exam-sessions/{sessionId}/evidence`
  (teacher-owner) → marks + deletes objects (demo hygiene; audit row kept).

## 9. Acceptance test matrix (issues #91–#94)

Real-stack gates (Testcontainers MinIO/Postgres + real LiveKit/egress +
Playwright where marked): snapshot upload round-trip w/ SHA-256 + HEAD;
duplicate idempotency; bound rejection; foreign/student IDOR; recording ON →
playable MP4 (ffprobe + browser playback evidence); recording OFF → no
recording objects; clips OFF+recording OFF → NO_COVERAGE; clips ON+recording
OFF → real pre-roll clip from pulses (PARTIAL on induced gap); egress
crash/duplicate webhook/storage outage → honest FAILED states, exam flows
unaffected; retention expiry → EXPIRED metadata, no dead URLs; P4-A/B/C
regressions green; backend Maven + Testcontainers; frontend lint/tsc/vitest/
build; Playwright A–H + new P4-D spec.
