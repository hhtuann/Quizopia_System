# Phase 4 — Classroom Demonstration Runbook (design checklist, not executed)

**Purpose:** a 5–10 participant, real-camera, real-model classroom demo. This is **not a production deployment guide**. Paths/commands for LiveKit/AI/Egress are placeholders until implementation and real tests exist; do not claim these services are already present.

## A. Setup after implementation

1. Prepare a dev-only `.env` with freshly generated local secrets; never commit it. Keep MinIO buckets private; do not use example root credentials outside dev.
2. Start System's existing Docker Compose services, then the **future** LiveKit+Egress+AI profiles after PRs are merged/authorized. Check health endpoints, TURN/ICE, S3 access and available GPU (CPU if model feasible).
3. Create one TEACHER and **five consenting adult** demo participants; target ten. Prepare one ACTIVE classroom, published Exam, CLASS_RESTRICTED Session; exercise both recording OFF and ON. Show monitoring notice and camera indicators.
4. Source fixtures: real webcams wherever available. A looping synthetic camera feed can replace a missing physical webcam only if explicitly labeled; test real AI inference on the resulting frames separately. Ensure no minors or unknowingly recorded participants.

## B. Script to demonstrate to instructor

| Step | What to perform | Teacher/student observable proof |
|---|---|---|
| 1 | Teacher creates class-restricted Session, monitoring enabled | Backend rejects PUBLIC and empty-class monitoring |
| 2 | 5 participants accept notice, grant webcam, complete readiness | Authorized live camera grid, each publisher bound to correct Session |
| 3 | Student changes an answer, saves, flags question, leaves and returns tab | `ANSWER_SAVED`/answer history distinct from browser-only observations |
| 4 | Show phone to one webcam; another consenting adult joins a webcam frame | **Real-model** PHONE and MULTIPLE_PERSONS alert grouped by temporal rules |
| 5 | Click alert | Private snapshot with timestamp; evidence clip seekable around alert |
| 6 | Demonstrate recording ON; repeat clip with recording OFF + real bounded buffer | Full recording with actual segments, and OFF does not mean no buffer |
| 7 | Disconnect student webcam temporarily | Attempt continues, autosave correct, teacher sees gap/recovery |
| 8 | Student submits; teacher reloads page | Persisted activity timeline, alert review notes and report |
| 9 | Wrong student/teacher tries direct evidence/room access | Authorization denied; no public bucket access |
| 10 | Stop session/clean test recordings | Egress finalized state, retention/manual demo cleanup proof |

## C. Quality/measurement log (fill with actual evidence only)

- Exact System / Backend / Frontend / AI HEADs and CI run URLs: **TBD**
- OS/browser versions, CPU/GPU/RAM, camera count, real vs synthetic: **TBD**
- Media join/room stats, reconnect duration, teacher grid bandwidth: **TBD**
- Real model identity/version, frame sampling, actual FPS/latency and false-positive examples: **TBD**
- Snapshot/MP4/clip generated object IDs and checksum audit (redacted): **TBD**
- Full Testcontainers FE test counts + E2E results + independent review: **TBD**
- **Do not describe mock detections as working AI model or 10-camera capability if only 5 were tested.**

## D. Outage script (if time permits)

- Kill webcam → reconnect, answers retained; kill AI worker → detection unavailable but Attempt unaffected; crash Egress → recording PARTIAL/FAILED; restart STOMP → REST cursor reconciliation.

## E. Deferred

30/50/100 publisher scale, enterprise HA, cloud production rollout, formal data-protection legal audit for real students and commercial SLAs are **not required for this academic demonstration**. These remain future tasks if scope changes.
