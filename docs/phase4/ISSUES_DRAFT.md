# Quizopia Phase 4 — GitHub Issue Backlog (academic demo, 2026-11-14)

**State:** 1 Epic + 21 children **PUBLISHED** on GitHub 2026-11-14. This document is the archival detailed draft; **GitHub Issue bodies are authoritative**. See `GITHUB_ISSUE_LINKS.md`. Do not import this draft again or create duplicate Issues. Publication does not authorize source changes, merge or deployment.

**Academic goal:** 5 concurrent real webcams mandatory, 10 target, real phone/person AI inference, evidence, recording and replay. Production legal sign-off and 30/50/100 stream scaling deferred.

**Issue tracker:** https://github.com/hhtuann/Quizopia_System/issues

## 0. [[P4-EPIC] Phase 4 — Exam Monitoring, Activity Tracking & AI Proctoring](https://github.com/hhtuann/Quizopia_System/issues/77)

- Key: `P4-EPIC`
- Dependencies: none

**Background:** Extend Quizopia's Modular Monolith with durable Attempt activities, server-verified WebRTC camera monitoring, independent AI detection and evidence (snapshot, full recording, bounded clips), unified teacher review/report. Approved product architecture: self-hosted LiveKit, one room/Session, class-restricted only, full recording OFF by default, MinIO dev/S3 prod, 30d evidence/90d activity, camera-loss never destroys Attempt, independent AI adapters and later approved AI submodule.

**Scope:** P4-0 architecture/model audit and demo safety/privacy baseline; P4-A monitoring foundation; P4-B camera; P4-C real AI; P4-D evidence/recording/retention; P4-E unified dashboard/review; P4-F hardening/benchmarks. **Non-goals:** automatic cheating verdicts; PUBLIC monitoring; direct grade mutation from AI; deploying without authorization.

**Global acceptance criteria:**
- [ ] Teacher enables monitoring on assigned `CLASS_RESTRICTED` Session; Backend rejects `PUBLIC`/zero-class.
- [ ] Learner completes genuine server-verified camera preflight before **new** monitored Attempt.
- [ ] Teacher sees authorized live cameras, student isolation enforced, reconnect and outages are visible without autosave/submit regression.
- [ ] Real model phone/person detections are versioned, grouped, tested separately from fake worker, and alerts delivered durably.
- [ ] Evidence image, optional full recording and clips from full video or rolling buffer work; assets private, auditable and time-bounded.
- [ ] Timeline captures browser/server events, accepted answer history and AI/media/recording provenance, survives reload and reconnect.
- [ ] Teacher reviews alerts/false positives, sees report without any automatic misconduct verdict.
- [ ] 30d media/evidence and 90d activity retention, no P0/P1/P2 functional/security blockers; real 5-camera demo and optional 10-camera stress run measured and documented.

**Definition of Done:** all child issues independently reviewed, documented feature flags and model versions, Testcontainers/FE tests and real media E2E green on exact PR HEADs; academic-demo security/safety checklist and repeatable showcase runbook; owner controls separate merge and deployment gates.

**Architecture constraints:** Keep existing Attempt SQL conditional UPSERT and lock ordering; Spring remains authority for security and grades; only WebRTC carries video, not REST/STOMP; no Kafka/K8s/Elastic without measurement; all sensitive assets private; no AI penalty decisions.

**Milestone dependency map:** `P4-0 → P4-A → P4-B → P4-C / P4-D (parallel where safe) → P4-E → P4-F`; actual child dependencies listed below. 


**Academic scope update (2026-11-14):** Course project, **not for real-student deployment**. Mandatory: 5 simultaneous real camera publishers (target 10), 1 teacher dashboard, real-model PHONE/MULTIPLE_PERSONS alerts, snapshot + clip, full recording ON and OFF, persisted activity/answer timeline and teacher report. 30/50/100 camera scale, production legal paperwork and enterprise HA are future/stretch work, **not completion blockers**. Use consenting adults or approved/synthetic footage, show a notice, protect stored video, and keep 30/90 day retention.

---

## 1. [[P4-0.1] Finalize ADR-008, API contracts, demo scope and threat model](https://github.com/hhtuann/Quizopia_System/issues/78)

- Key: `P4-0.1`
- Dependencies: none

**Milestone:** P4-0 | **Priority:** P0 | **Dependencies:** none

### Background / Scope
Approve stable product invariants, architecture/contract docs, compatibility plan, data classification, retention and risk register; no implementation yet.

### Backend
Check current API shape, auth permissions, migration version, attempt lock-order and error code conventions.

### Frontend
Audit `DESIGN.md`, policy notices, supported browsers and teacher/student session routes.

### Media / AI / Ops
Validate LiveKit self-host token revocation limitation, camera-notice, consenting demo volunteers, S3/TURN/Egress infrastructure assumptions.

### Acceptance Criteria
- [ ] ADR-008 and versioned API/event specs have explicit owner sign-off
- [ ] Scope contains camera, tracking, AI, snapshot, video, clips and unified timeline
- [ ] Document explicit failure policy and academic-demo limitations and deferred production obligations
- [ ] No repo/infra changes performed by this ticket

### Security & Privacy
Demo notice, authorization, no audio, access audit, 30/90 retention and approved adult/synthetic camera footage documented; high residual self-host token risk recorded.

### Tests & Evidence
Document review traceability to baseline main SHA, replay a threat-model tabletop and trace Session + Attempt state transitions.

### DoD / Review Gate
Principal architect + security reviewer; architecture PO gate. Formal production legal audit not required for course demo.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 2. [[P4-0.2] Audit real phone/person models and design gaze-compatible adapter contract](https://github.com/hhtuann/Quizopia_System/issues/79)

- Key: `P4-0.2`
- Dependencies: `P4-0.1`

**Milestone:** P4-0 | **Priority:** P0 | **Dependencies:** P4-0.1

### Background / Scope
Ingest owner-provided AI model repo/artifacts, inspect I/O and runtime, benchmark representative media and decide threshold evaluation protocol.

### Backend
Define trusted callback and media-binding event envelope; no Attempt/Grade mutation.

### Frontend
List UI categories and honest unsupported/disabled states (gaze stays OFF until validated).

### Media / AI / Ops
Document hardware, frames, FPS, batching, GPU VRAM, false positives/negatives, model version/checksum; keep model repo creation deferred.

### Acceptance Criteria
- [ ] Model repo/artifact and reproducible runtime recorded
- [ ] Real adapter contract with phone/person outputs and Gaze extension point
- [ ] p50/p95 latency and accuracy evidence on named hardware or explicit BLOCKED status
- [ ] No claims of real-model accuracy based on stub results

### Security & Privacy
Use approved synthetic/consenting adult samples only; no student footage used for training; record model limitations.

### Tests & Evidence
Model fixture tests + representative lighting/device dataset; synthetic and real-model results labeled separately.

### DoD / Review Gate
AI systems architect independent review; P4-C implementation blocked until real-model inputs available.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 3. [[P4-A1] Session Monitoring Policy, eligibility & immutable freeze](https://github.com/hhtuann/Quizopia_System/issues/80)

- Key: `P4-A1`
- Dependencies: `P4-0.1`

**Milestone:** P4-A | **Priority:** P0 | **Dependencies:** P4-0.1

### Background / Scope
Build monitoring config defaults and invariants for class-restricted sessions only; validated flag combinations; immutable policy freeze.

### Backend
Add additive config model/migration/API; validate class ownership+ACTIVE+≥1; prohibit PUBLIC and last-class removal; freeze at startsAt/OPEN/first Attempt using stable lock/version.

### Frontend
Create/update session checkbox UI, camera-dependent options, policy/retention display and validation across canonical/legacy routes.

### Media / AI / Ops
No LiveKit dependency for config read/write; feature flag default OFF.

### Acceptance Criteria
- [ ] PUBLIC monitoring is rejected server-side
- [ ] Monitored Session requires ≥1 owned active assigned classroom even if client sends zero IDs
- [ ] Monitoring ON implies camera required; invalid AI/clip/recording combos rejected
- [ ] Settings freeze with correct race/optimistic concurrency, including lazy-open SCHEDULED

### Security & Privacy
Owner-only writes and no public disclosure of private policy; default OFF for old client requests.

### Tests & Evidence
Migration fresh/upgrade + service and HTTP validation, concurrent start/freeze/class-removal, FE form a11y/validation.

### DoD / Review Gate
Independent BE+FE review; no change in public/non-monitored eligibility.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 4. [[P4-A2] Attempt/browser activity ingestion and client telemetry](https://github.com/hhtuann/Quizopia_System/issues/81)

- Key: `P4-A2`
- Dependencies: `P4-A1`

**Milestone:** P4-A | **Priority:** P1 | **Dependencies:** P4-A1

### Background / Scope
Bounded event vocabulary for browser focus/tab, answer interaction, navigation, connectivity, and attempt lifecycle hints; durable ingestion.

### Backend
Add attempt-scoped activity event table, batch API, idempotency, trust levels, rate/size limits, server receivedAt, safe validation and cleanup metadata.

### Frontend
Add intent-based tracking without React rerender duplicates; bounded background retry queue and network-gap indicators; never capture essay per keystroke.

### Media / AI / Ops
None; use existing Postgres/REST; do not add new broker.

### Acceptance Criteria
- [ ] Events survive reload and are Attempt-scoped
- [ ] Duplicate batches cannot create infinite rows
- [ ] Clearly distinguish BROWSER-observed and SERVER-confirmed
- [ ] Tracking OFF stops browser collection but not authoritative core lifecycle

### Security & Privacy
Ownership-only API, no PII/answer key in free-form metadata, caps and abuse handling.

### Tests & Evidence
FE event tests, BE rate/size/owner/duplicate/out-of-order tests and browser offline scenario.

### DoD / Review Gate
Independent tracking/privacy review of allowed event fields and data size.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 5. [[P4-A3] Atomic accepted-answer history with autosave correctness preserved](https://github.com/hhtuann/Quizopia_System/issues/82)

- Key: `P4-A3`
- Dependencies: `P4-A1`

**Milestone:** P4-A | **Priority:** P0 | **Dependencies:** P4-A1

### Background / Scope
Append accepted-only answer versions without breaking current atomic UPSERT and deadline/concurrency semantics.

### Backend
Append history after UPSERT affected=1 **in same transaction**; unique question+accepted seq; optional hash/metadata not unrestricted essay content; rollback on history failure.

### Frontend
No new save flow; reuse `use-autosave.ts` and answer-store as-is unless necessary for client event hooks.

### Media / AI / Ops
No media dependency.

### Acceptance Criteria
- [ ] Exactly one history row per accepted sequence
- [ ] Stale or retried UPSERT produces zero new history rows
- [ ] Failed history write rolls back answer update
- [ ] Current answer and submit/grade behavior unchanged

### Security & Privacy
Separate permission for history read; essay snapshot minimization and retention.

### Tests & Evidence
Testcontainers conflicting saves, accepted seq, stale, parallel submit/autosave, rollback and large essay privacy.

### DoD / Review Gate
Database/concurrency specialist independent review; P0 gate.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 6. [[P4-A4] Durable Attempt timeline read model and monitoring STOMP envelopes](https://github.com/hhtuann/Quizopia_System/issues/83)

- Key: `P4-A4`
- Dependencies: `P4-A2`, `P4-A3`

**Milestone:** P4-A | **Priority:** P1 | **Dependencies:** P4-A2, P4-A3

### Background / Scope
Provide timeline pagination/read and non-lossy reconnect semantics; introduce versioned monitoring event stream, preserving existing STOMP contracts.

### Backend
Cursor API, indexes, normalized timeline query, `monitoring_outbox`; allowlist new monitoring subscribe path with existing DB-backed Session owner checks; no client SEND.

### Frontend
Timeline basic filters, loading/empty states, REST baseline, STOMP event dedupe/re-fetch.

### Media / AI / Ops
No additional message broker until benchmark says otherwise.

### Acceptance Criteria
- [ ] Timeline reload preserves history
- [ ] Out-of-order/client clock skew are labeled, stable pagination has no missing/duplicate pages
- [ ] New STOMP destination denies other teacher/student subscriptions
- [ ] Legacy six realtime events and current LiveMonitor continue functioning

### Security & Privacy
No correct answers/grade payloads in STOMP; cursor/authorization safe from IDOR.

### Tests & Evidence
BE cursor boundary/idempotency tests, STOMP spoof/unauthorized integration and FE reconnect tests.

### DoD / Review Gate
Realtime/security independent review; original event contract compatibility proven.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 7. [[P4-B1] LiveKit self-hosted and Egress infrastructure design/compose spike](https://github.com/hhtuann/Quizopia_System/issues/84)

- Key: `P4-B1`
- Dependencies: `P4-0.1`, `P4-A1`

**Milestone:** P4-B | **Priority:** P0 | **Dependencies:** P4-0.1, P4-A1

### Background / Scope
Secure local/dev self-host LiveKit SFU and Egress service with correct UDP/TURN signaling and Redis integration; no production deployment.

### Backend
Implement MediaGateway wrapper and short-lived token service only after approved issue starts.

### Frontend
Dev media connectivity diagnostic route/client for smoke tests.

### Media / AI / Ops
Compose profile, pinned versions, secret injection, TLS/network plan, RoomService health metrics, camera-only publish permissions; document remote-browser NAT limitations.

### Acceptance Criteria
- [ ] Student and teacher can join one room/Session under controlled permissions
- [ ] Student cannot subscribe or publish audio/screen
- [ ] Egress runs separately and can record a test camera track
- [ ] Self-host token stale rejoin behavior verified and documented

### Security & Privacy
TLS, no exposed secrets, minimal grants, no media access after session ownership failure beyond documented TTL residual.

### Tests & Evidence
Real two-camera/single teacher test, network firewall/TURN, negative permission and restart tests.

### DoD / Review Gate
Media/security infrastructure review; no prod deploy gate passed.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 8. [[P4-B2] Backend verified camera preflight and new Attempt readiness lease](https://github.com/hhtuann/Quizopia_System/issues/85)

- Key: `P4-B2`
- Dependencies: `P4-B1`, `P4-A1`

**Milestone:** P4-B | **Priority:** P0 | **Dependencies:** P4-B1, P4-A1

### Background / Scope
Preflight before Attempt ID exists; bind trusted media identity+epoch to a one-time readiness lease consumed inside existing start transaction.

### Backend
Eligibility+policy notice endpoint, preflight/token/verify, track query, lease hash+expiry, authoritative start gate, post-start Attempt binding and orphan pre-start cleanup; resume keeps working under camera loss.

### Frontend
Landing flow requests permission, shows preview and uses lease in existing start mutation.

### Media / AI / Ops
Room state/webhook validation + optional Egress start for recording ON before Attempt.

### Acceptance Criteria
- [ ] No actual published camera → new monitored Attempt blocked
- [ ] Only same user/Session/current policy may consume lease once
- [ ] Simultaneous start produces one Attempt and correct binding
- [ ] Resume existing IN_PROGRESS Attempt never loses autosave access because camera down

### Security & Privacy
No camera bypass, token never logged, no trust in frontend `ready` boolean.

### Tests & Evidence
Http/Testcontainers race/expiry/replay/cross-user/session; real webcam preflight + Egress failure tests.

### DoD / Review Gate
Attempt concurrency + security specialist independent review.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 9. [[P4-B3] Student camera client + Teacher selective Camera Grid](https://github.com/hhtuann/Quizopia_System/issues/86)

- Key: `P4-B3`
- Dependencies: `P4-B1`, `P4-B2`

**Milestone:** P4-B | **Priority:** P1 | **Dependencies:** P4-B1, P4-B2

### Background / Scope
Student permission/preflight/indicator UI; teacher grid and focused video view respecting existing Session detail design.

### Backend
Provide authorized teacher token endpoint and camera state query, participant↔attempt projection.

### Frontend
Camera preview, permission denial/unavailable, grid virtualization/low layers, focus high layer, accessibility, responsive status.

### Media / AI / Ops
LiveKit JS SDK publishing/subscription lifecycle with no mic/audio; drop off-screen subscriptions.

### Acceptance Criteria
- [ ] Teacher can inspect correct eligible students in room
- [ ] Student cannot view another camera
- [ ] 5–10 card grid selectively subscribes to low-quality streams; high-quality subscribe only for selected camera
- [ ] No blocking of Attempt rendering by video errors

### Security & Privacy
Teacher owner/permission required at issuance; stream access audit.

### Tests & Evidence
Playwright + browser media mocks + real browser tests, different roles, tabs and screenreader checks.

### DoD / Review Gate
Independent UX/performance/security review.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 10. [[P4-B4] Camera state reconciliation, reconnect gaps and token revocation](https://github.com/hhtuann/Quizopia_System/issues/87)

- Key: `P4-B4`
- Dependencies: `P4-B2`, `P4-B3`

**Milestone:** P4-B | **Priority:** P0 | **Dependencies:** P4-B2, P4-B3

### Background / Scope
Complete camera/media lifecycle and incident recording, including missed LiveKit webhook and selfhost token revocation risk.

### Backend
Signed webhook ingestion + dedupe; periodic room reconciliation; connection incidents, short TTL grant renewal checks and RemoveParticipant on denial/submit.

### Frontend
Reconnect bounded retry, partial/degraded status, no forced submission; teacher gap timeline.

### Media / AI / Ops
Observability for track publication, orphan room cleanup and Egress lifecycle hints.

### Acceptance Criteria
- [ ] After camera loss Attempt persists and saves answers
- [ ] Connection intervals/gaps are durable
- [ ] Revoked user loses Backend grants; residual self-host stale-token window measured
- [ ] Reordered/missing webhooks reconcile with server state

### Security & Privacy
Signed webhook verification, replay defense, monitor ownership and stale-token threat acceptance.

### Tests & Evidence
Media restart/packet loss/browser reload/removed teacher test + fail-injection.

### DoD / Review Gate
Security/reliability independent review; residual media revocation risk reported.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 11. [[P4-C1] Independent AI service skeleton, model-adapter SDK & transport](https://github.com/hhtuann/Quizopia_System/issues/88)

- Key: `P4-C1`
- Dependencies: `P4-0.2`, `P4-B1`

**Milestone:** P4-C | **Priority:** P0 | **Dependencies:** P4-0.2, P4-B1

### Background / Scope
Create a separate AI codebase **only when specifically authorized**, modular receiver/adapters/scheduler/outbox and trusted Backend callback.

### Backend
AI internal callback endpoint with service authentication, model allowlist, binding validation and idempotency.

### Frontend
Monitoring AI coverage status and unavailable state.

### Media / AI / Ops
Future AI repo/submodule, container, config, fake adapter, health/readiness and reproducible CI; do not grant DB grading permissions.

### Acceptance Criteria
- [ ] Fake video frames can traverse AI adapter and authenticated Backend event contract
- [ ] No model-specific data leaks across adapter boundary
- [ ] Replay/cross-Attempt forgery rejected
- [ ] AI service restart/overload does not break Attempt

### Security & Privacy
Worker credentials isolated, no student footage logged or trained by default.

### Tests & Evidence
Contract, container restart, forged callback, fake detector and bounded queue tests.

### DoD / Review Gate
Architecture and security review; repo creation subject to explicit owner permission.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 12. [[P4-C2] Integrate real phone/multiple-person detectors and measure performance](https://github.com/hhtuann/Quizopia_System/issues/89)

- Key: `P4-C2`
- Dependencies: `P4-C1`, `P4-0.2`

**Milestone:** P4-C | **Priority:** P0 | **Dependencies:** P4-C1, P4-0.2

### Background / Scope
Load verified real models; normalize labels/boxes; validate latency/accuracy under representative webcam conditions. Gaze adapter extension point, but detection disabled until independently verified.

### Backend
Document accepted model version/type schema without relying on invented thresholds.

### Frontend
Display only supported detection classes and model coverage warnings.

### Media / AI / Ops
Preprocessing, warmup, GPU/CPU inference, batched or sampled pipeline, metrics, real-model eval scripts.

### Acceptance Criteria
- [ ] Real phone and multi-person output matches adapter contract
- [ ] Model hash and runtime pinned
- [ ] Measured accuracy and p95 latency on specified hardware
- [ ] Gaze activation explicitly deferred until validated

### Security & Privacy
Approved evaluation footage, dataset provenance and bias/false-positive evaluation.

### Tests & Evidence
Separate real-model test evidence, confusion metrics, per device/light scenario, load samples.

### DoD / Review Gate
AI/ML independent review; no mock-only signoff.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 13. [[P4-C3] Temporal detection aggregation, trusted alerts and realtime feed](https://github.com/hhtuann/Quizopia_System/issues/90)

- Key: `P4-C3`
- Dependencies: `P4-C2`, `P4-A4`, `P4-B4`

**Milestone:** P4-C | **Priority:** P1 | **Dependencies:** P4-C2, P4-A4, P4-B4

### Background / Scope
Persist raw detections separately from grouped alerts; capture event provenance and alert time windows.

### Backend
AI detection ingest dedupe, mapping at observed media epoch, aggregation/cooldown rules, alert outbox and POST-review independence.

### Frontend
Teacher new alert notification, filters, counts and neutral wording.

### Media / AI / Ops
AI worker durable retry/outbox and threshold profile version; no one alert per frame.

### Acceptance Criteria
- [ ] One continuous phone detection produces one grouped alert window
- [ ] Late callbacks never bind to next Attempt
- [ ] Alert changes survive STOMP drop/reconnect
- [ ] No automatic cheating verdict, penalty or grade mutation

### Security & Privacy
Authenticated callback, authorization for alert read, confidence not represented as proof.

### Tests & Evidence
Burst/duplicate/out-of-order/lateness tests, fake detector and verified real-model run.

### DoD / Review Gate
Backend+AI independence review and false-alert assessment.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 14. [[P4-D1] Private evidence Object Storage and AI snapshot pipeline](https://github.com/hhtuann/Quizopia_System/issues/91)

- Key: `P4-D1`
- Dependencies: `P4-C3`, `P4-B1`

**Milestone:** P4-D | **Priority:** P0 | **Dependencies:** P4-C3, P4-B1

### Background / Scope
Private MinIO dev and S3-compatible abstraction, images linked to vetted AI alerts with immutable metadata/checksum.

### Backend
Evidence asset metadata/upload state, backend authorization/signed URL grant, access audit and object recovery.

### Frontend
Evidence thumbnail/preview for teacher and expired/failed states.

### Media / AI / Ops
AI snapshot original-frame capture, checksum verification, private object upload and dedup/cooldown.

### Acceptance Criteria
- [ ] One alert resolves to appropriate snapshot when capture enabled
- [ ] No large image in STOMP or PostgreSQL
- [ ] Cross-user evidence access denied and audited
- [ ] Upload failure does not falsely show AVAILABLE

### Security & Privacy
S3 IAM least privilege, private buckets, TLS/encryption, short signed grants.

### Tests & Evidence
MinIO integration HEAD/hash/unauthorized tests and repeat detection storage cap.

### DoD / Review Gate
Storage/security/privacy independent review.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 15. [[P4-D2] Opt-in per-Attempt Egress full recording and segment recovery](https://github.com/hhtuann/Quizopia_System/issues/92)

- Key: `P4-D2`
- Dependencies: `P4-B2`, `P4-B4`, `P4-D1`

**Milestone:** P4-D | **Priority:** P0 | **Dependencies:** P4-B2, P4-B4, P4-D1

### Background / Scope
Full recording remains OFF by default; ON runs authenticated per-camera Egress with real status and multiple segments/gaps.

### Backend
Recording coordinator state machine, preflight Egress started check, attempt binding, after-commit stop, S3 HEAD finalized verification and background reconciliation.

### Frontend
Recording indicator, teacher availability/partial/failure and playback entry.

### Media / AI / Ops
Self-host Egress pinned version, camera-only media source, segment MP4/HLS and storage uploads.

### Acceptance Criteria
- [ ] No full video when OFF
- [ ] ON captures correct student/Attempt including reconnect segments
- [ ] AVAILABLE only after uploaded object verified
- [ ] Egress crash/status loss produces truthful PARTIAL/FAILED, Attempt still usable

### Security & Privacy
No audio, teacher-only access, prestart orphan capture cleanup and disclosure.

### Tests & Evidence
Real Egress/local MinIO/interrupt/upload fail/finalize/duplicate webhook tests.

### DoD / Review Gate
Media/reliability + privacy independent review.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 16. [[P4-D3] Evidence video clips from full recording OR bounded rolling buffer](https://github.com/hhtuann/Quizopia_System/issues/93)

- Key: `P4-D3`
- Dependencies: `P4-D2`, `P4-D1`, `P4-C3`

**Milestone:** P4-D | **Priority:** P1 | **Dependencies:** P4-D2, P4-D1, P4-C3

### Background / Scope
Clip extraction near alert from full recording and rolling temporary media when full recording OFF.

### Backend
Clip request idempotency, source coverage/gap detection, async status and asset links.

### Frontend
Clip player timeline deep links, PARTIAL/UNAVAILABLE messages.

### Media / AI / Ops
Rolling encoded chunk worker or demonstrably equivalent Egress architecture, strict short TTL/unpinned deletion and measured resource use.

### Acceptance Criteria
- [ ] Recording ON produces alert clip with valid pre/post interval subject to coverage
- [ ] Recording OFF + clip ON works using actual buffer rather than pretending past frames exist
- [ ] Buffer chunks not pinned for alerts are promptly deleted
- [ ] Missing source gaps lead to PARTIAL/UNAVAILABLE, never fictional clip

### Security & Privacy
Disclose that buffer itself stores video, encryption/private access, no indefinite pre-alert footage.

### Tests & Evidence
30s sample scenario, storage interruption, source expired, concurrent clipping and short-TTL cleanup.

### DoD / Review Gate
Media/storage/privacy review; measure buffer disk/CPU cost at 5–10 publishers.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 17. [[P4-D4] Playback authorization, evidence retention & orphan cleanup](https://github.com/hhtuann/Quizopia_System/issues/94)

- Key: `P4-D4`
- Dependencies: `P4-D2`, `P4-D3`

**Milestone:** P4-D | **Priority:** P0 | **Dependencies:** P4-D2, P4-D3

### Background / Scope
Secure MP4/HLS Range/segment playback and automatic 30-day media/90-day activity retention.

### Backend
Segment-aware signed playback, audit grants, retention and manual-demo-cleanup metadata; hold as future extension, orphan recovery, deletion proof and EXPIRED tombstones.

### Frontend
Recording/evidence player and expired-state UX.

### Media / AI / Ops
S3 lifecycle and cleanup tasks; rolling buffer cleanup separate from 30-day policy.

### Acceptance Criteria
- [ ] No unauthenticated HLS segment, MP4 range seek works
- [ ] Media deleted after configured retention per policy
- [ ] Activity metadata remains queryable up to 90d with EXPIRED asset state
- [ ] Orphan preflight and failed Egress objects reconciled

### Security & Privacy
Cross-session playback IDOR, no public buckets, retention expiry, manual demo purge and secure sharing controls.

### Tests & Evidence
End-to-end playlist/segment/Range access, simulated expiry, storage outage and rerun cleanup idempotency.

### DoD / Review Gate
Security/privacy and ops independent review.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 18. [[P4-E1] Unified teacher monitoring overview & per-Attempt timeline UI](https://github.com/hhtuann/Quizopia_System/issues/95)

- Key: `P4-E1`
- Dependencies: `P4-A4`, `P4-B3`, `P4-C3`, `P4-D4`

**Milestone:** P4-E | **Priority:** P1 | **Dependencies:** P4-A4, P4-B3, P4-C3, P4-D4

### Background / Scope
Unify Session monitoring counts, camera grid, roster, alerts and Attempt timeline, preserving Participant Management and Results/Statistics.

### Backend
Aggregated overview queries with correct camera vs Attempt online distinction; timeline/media/report projection tuning.

### Frontend
Student Monitoring Detail: camera, connection gaps, activity, answer history subject to permission, evidence, segments and alerts; filters and virtualized lists.

### Media / AI / Ops
No new runtime service.

### Acceptance Criteria
- [ ] Teacher sees correct unified timeline after reload
- [ ] Counts distinguish IN_PROGRESS from camera connected
- [ ] Alert/evidence timestamp jumps work across segments and show gaps
- [ ] Original Results/Statistics still functional

### Security & Privacy
No answer keys/grades leaked ahead of authorized result flow, per-teacher owner checks.

### Tests & Evidence
FE RTL? not required; keyboard, responsive, reconnect and BE pagination/query-count tests.

### DoD / Review Gate
Frontend UX/data privacy independent review; E2E acceptance.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 19. [[P4-E2] Alert review, false-positive feedback and Attempt monitoring reports](https://github.com/hhtuann/Quizopia_System/issues/96)

- Key: `P4-E2`
- Dependencies: `P4-E1`, `P4-C3`

**Milestone:** P4-E | **Priority:** P1 | **Dependencies:** P4-E1, P4-C3

### Background / Scope
Teacher reviews alerts with notes, status and full review history, then sees monitoring report for finished Attempt.

### Backend
Append-only reviews and status versioning, permission scope, report counts raw detections vs grouped vs confirmed, audit and pagination.

### Frontend
False positive, viewed, follow-up, notes, post-exam report view and export feasibility assessment.

### Media / AI / Ops
No new AI training loop without separate authorization.

### Acceptance Criteria
- [ ] One can mark false positive without deleting original detection/evidence
- [ ] Review history and ownership are immutable/auditable
- [ ] Report distinguishes raw detections, alerts and teacher-reviewed outcomes
- [ ] No automatic cheating or grade change

### Security & Privacy
Owner-only review, notes sanitation/length limits, retention and no unauthorized answer disclosure.

### Tests & Evidence
Review 409 race, authorization, counts aggregation, print/export feasibility, visual and E2E tests.

### DoD / Review Gate
Human-review policy and backend security independent review.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 20. [[P4-F1] Independent security review and demo hardening](https://github.com/hhtuann/Quizopia_System/issues/97)

- Key: `P4-F1`
- Dependencies: `P4-E2`, `P4-D4`, `P4-B4`

**Milestone:** P4-F | **Priority:** P0 | **Dependencies:** P4-E2, P4-D4, P4-B4

### Background / Scope
Independent course-demo safety/security audit across identity, media, AI, recording, storage, frontend. Formal legal/privacy production review is deferred because no real students are involved.

### Backend
Fix any P0/P1/P2 auth, IDOR, rate, retention, encryption, audit issues discovered; demonstrate regression coverage.

### Frontend
Camera/recording notice, simple manual demo-data purge, accessibility, error disclosure and mitigations.

### Media / AI / Ops
Self-host token residual risk measured; TURN, Egress secrets/IAM, private S3 access and local incident handling reviewed.

### Acceptance Criteria
- [ ] Cross-user/cross-class/media access negative tests green
- [ ] Retention deletion, storage/stream audit verified
- [ ] Demo security reviewer signs basic safety/privacy checklist; consented adults or approved footage only
- [ ] No remaining P0/P1/P2 functional/security blockers

### Security & Privacy
Follow privacy-by-design and consented adult/synthetic demo footage; no automatic punishment.

### Tests & Evidence
Pen tests incl HLS segment auth and stale token, data deletion and audit review; rerun all regressions.

### DoD / Review Gate
Independent security reviewer + Product Owner gate; no production legal sign-off needed.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---

## 21. [[P4-F2] 5–10 camera demo benchmark, failure injection, real AI E2E and runbook](https://github.com/hhtuann/Quizopia_System/issues/98)

- Key: `P4-F2`
- Dependencies: `P4-F1`, `P4-C2`

**Milestone:** P4-F | **Priority:** P0 | **Dependencies:** P4-F1, P4-C2

### Background / Scope
Quantify capacity, full failure recovery and browser media→AI→evidence→review path; produce demo-readiness report and runbooks.

### Backend
Backend outbox/reconnect/snapshot query, DB throughput, start/autosave/submit consistency under load.

### Frontend
Cross-browser/teacher grid UX, preflight failure and full E2E recordings.

### Media / AI / Ops
LiveKit, Egress, GPU, rolling-buffer, object storage, network metrics, reproducible scripts and CI evidence.

### Acceptance Criteria
- [ ] Real E2E successfully demonstrates all Phase 4 must-have features
- [ ] Exact PR HEAD backend/frontend/AI tests and CI green
- [ ] 5 publisher run PASS; 10 target measured if available, document actual p95, bandwidth, storage and GPU/CPU usage. 30/50/100 runs optional stretch
- [ ] Fault injection demonstrates no answer loss, truthful monitoring gaps and recording status
- [ ] Local Compose setup, demo seed accounts, consented camera plan, repeatable demo and rollback/runbooks complete; final GO/NO-GO recommendation

### Security & Privacy
No real students used. Adult volunteers consent to camera recording or use approved/synthetic test footage; maintain basic security and retention.

### Tests & Evidence
Measured browser/live-media/AI/S3 E2E; intentional SFU/AI/Egress/MinIO failure injection; full Testcontainers suites.

### DoD / Review Gate
Independent final technical review. Owner authorizes merge/deploy separately; issue completion is not deployment authorization.

Feature branch, targeted + full tests, PR exact HEAD CI, independent review until P0/P1/P2 free, **no merge/deploy without Owner approval**.

**Academic demo scope:** No real-student production rollout. Prioritize working 5-camera (10 target) local demo, real model where AI involved, correctness/security, camera consent notice and private evidence. 30/50/100 streams, enterprise HA and formal legal clearance are NOT blocking acceptance unless Product Owner changes scope. Preserve independent P0/P1/P2 blocker review and separate merge/deploy gate.

---
