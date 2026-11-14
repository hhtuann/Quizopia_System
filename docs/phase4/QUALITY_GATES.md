# P4 — Engineering, Demo Security and Final Acceptance Gates

**Status:** Proposed execution gate matrix; design-only. No tests have been run by producing this document.

## 1. Mandatory autonomous engineering loop

`Inspect (main + worktrees) → Plan → Implement in feature branch → Targeted tests → Full suites → Independent review → P0/P1/P2 findings → Fix → Rerun regressions → Re-review → Report on exact PR HEAD → Owner approval → Merge (only after permission)`. No direct coding on main, no force push, no resetting user work, no deleting Docker data/volumes, no auto deploy.

**Before any coding agent touches repo:** `git status` in System/backend/frontend, branch/HEAD checks, untracked/WIP preservation, gitlinks, migration latest version, Docker volumes, current CI. Future AI repo creation and submodule change are **separately authorized operations**.

## 2. Milestone-specific exit gates

| Milestone | Essential proof | Must not claim until verified |
|---|---|---|
| P4-0 | ADR approved for course demo, model audit requested, safety/threat checklist, issue dependencies reviewed | Model performance known |
| P4-A | Backend Testcontainers migration + policy + START + UPSERT/Submit concurrency; FE activity; timeline | Accepted answer history complete without tx tests |
| P4-B | Two real/fake camera publishers and authorized teacher WebRTC viewer, negative subscription tests, token TTL/rejoin check, reconnect | WebRTC secure just because REST auth passes |
| P4-C | Signed AI callback/dedupe + isolated stub test + **separate real-model evaluation** | AI accuracy from fake/model-stub alone |
| P4-D | S3 private access, snapshot checksum, egress final MP4/segments, rolling-buffer clip, playback seek, deletion test | Recording available from an egress-start acknowledgement |
| P4-E | Durable unified timeline/teacher report/review, browser reconnect and accessibility tests | Frontend feed of 20 messages is full history |
| P4-F | End-to-end **5 real publishers + target 10**, real-model detections, failure injection, privacy basics, access controls and local demo runbook | Production readiness or 30/50/100 stream scale |

## 3. Core Testcontainers matrix

- Migration from empty DB and representative pre-P4 snapshot; no rewriting past Flyway.
- `PUBLIC` reject monitoring, restricted zero class reject; class changed after config, attempt initiated race with config freeze, session window past start; version conflict and owner mismatch.
- Duplicate start same student/multi-tab; consumed/expired/mismatched preflight readiness; no camera track; Egress start failed when required; resume while camera offline; blocked participant semantics and permission revocation.
- Autosave strictly higher seq conditional UPSERT; stale no history; accepted once with history; DB history failure causes rollback; simultaneous autosaves/submit; timeout, graded results unchanged.
- Browser batch dedupe, validation, rate limits, malicious metadata, timestamps skew/out-of-order, submission delayed event.
- AI event wrong mapping/unknown model/late callbacks/duplicate event/forged service signature; no automatic grade mutations.
- Evidence per-asset ownership, deletion, orphan cleanup, signatures and expired state; avoid open object key access.
- Alert review append-only history, expectedVersion conflict, cross-session update denied.

## 4. Frontend/browser E2E matrix

1. Teacher creates class-restricted Session with monitoring enabled, classes selected; PUBLIC toggling disallowed both FE+BE.
2. Student visits eligibility landing, sees notice, grants webcam, preview renders; Backend verifies video publishing; starts attempt using one-time lease.
3. Student selects/changes answer, autosaves, flags question, switches tab, loses focus; observe difference between client and server confirmed events.
4. Media disconnect happens: Attempt continues and answers save; camera reconnection updates gap; no forced auto-submit/penalty.
5. Stub AI emits fake detection → backend aggregated alert → snapshot/clip available; teacher receives after-commit notification and opens authorized evidence.
6. Real AI trial uses explicitly documented model fixture/dataset, reports accuracy/latency separately.
7. Full recording ON: segments captured, upload verified, playback seek to timestamp and pause/resume; OFF: no full video, but bounded clip mode preserves only short-term chunks.
8. Student submits or deadline expires; teacher reloads and sees durable timeline, review notes, report; evidence expires according to policy, metadata `EXPIRED` remains until 90 days.
9. Unauthorized student/teacher cannot open another user's camera/evidence; token stolen/revoked test; no correct answer leaked.
10. Cross-browser/accessibility/responsive checks: desktop/mobile feasibility noted, permission denied, camera unavailable, slow network, screen reader, keyboard and language.

## 5. Media/AI/S3 fault injection

| Fault | Expected observation |
|---|---|
| LiveKit server restart/disconnect | UI `RECONNECTING`, media gap recorded, Attempt/answers intact |
| Egress startup timeout | No false `RECORDING` claim; preflight blocks **new** monitored Attempt if full recording mandatory; existing Attempt continues |
| Egress crashes after start | partial/gap and recovery segment; no `AVAILABLE` without object HEAD |
| AI worker outage/GPU overload | AI coverage degraded and queue drops measured, no stale unmarked alerts |
| Webhook duplicate/missing/out of order | Idempotent records and periodic reconciliation |
| MinIO temporary outage | Retry/backpressure, error states, no leaked public objects |
| Delayed detection after next Attempt starts | Match historical media binding by epoch/time or quarantine; never reattribute to newest |
| Backend/STOMP restart | DB state survives; client reloads with cursor and removes duplicates |
| User removes camera mid-Attempt | incident logged, reconnect shown, Attempt ongoing |
| Consent/permission revoked | future access refused and actor removed; self-host residual stale token explicitly measured |

## 6. Security and privacy checklist

- [ ] Threat model for stream access, cross-class/session, token replay, webhook spoof, AI-to-backend identity, object keys, HLS segment signing, audit tampering.
- [ ] No public S3 buckets or shared MinIO root credentials; minimum IAM scopes, TLS, encryption and private signed URLs.
- [ ] Token TTL and self-host residual access window tested/documented; policy for worst-case rejoin exposure approved.
- [ ] No arbitrary client STOMP SEND; server-side per-subscribe authorization and replay recovery; any new monitoring topic is separately scoped.
- [ ] Explicit monitoring/camera/AI/snapshot/clip/full-recording notice in student workflow; document version and consent/legal basis.
- [ ] Avoid using minors or unconsenting students in demo. Provide camera permission error states, basic keyboard accessibility, and describe AI false positives.
- [ ] Academic demo uses **consenting adults or synthetic/approved footage**, with brief camera/AI/recording notice and no public sharing. Formal Vietnamese law/child/privacy impact review is deferred unless real students or production deployment are introduced.
- [ ] Media 30d and activity 90d cleanup verified; bounded rolling-temp buffer deletion and a manual demo cleanup path tested. Hold/data-request workflows are future production work.
- [ ] AI prediction cannot change grading or directly punish users; reviewers can mark false positives with audit trail.

## 7. Performance benchmarks / SLO candidate fields

Measured using explicit fixture and hardware: concurrent publishers, browsers/viewers, video resolution/FPS/bitrate, SFU ingress/outbound, CPU/RAM, AI GPU/VRAM/batch processing, frame sampling drops, p50/p95/p99 alert latency, recording startup/finalize and failure, S3 object latency, DB writes/s, dashboard update latency, timeline p95, network reconnection outcomes. **Do not invent target success metrics or report estimates as performance measurements.** Owner can adopt numerical go-live thresholds only after a baseline test.

## 8. Final report template

```markdown
# Phase 4 Milestone X — Final Integration Report
- Scope and issue IDs:
- Repo/branch/exact HEAD SHAs:
- Migration versions:
- Test commands, environment, passed/failed/skipped counts:
- Browser/real-media E2E proof:
- AI stub vs REAL model proof (separate):
- Performance: hardware, concurrency, p50/p95 and bottlenecks:
- Security and demo-safety findings and reviewer sign-offs:
- P0/P1/P2 findings: none outstanding / detailed blockers:
- Feature flags and rollback-by-disabling policy:
- CI run links on exact PR HEAD:
- Risk register and residual issues:
- GO/NO-GO recommendation:
- MERGE/DEPLOY: NOT AUTHORIZED (await explicit PO decision)
```

## 9. Definition of Done

All Phase 4 features work with measured actual E2E evidence (5 real publishers mandatory, 10 target), basic access controls and repeatable local demo script; issues and regression QA green; media/evidence retention works; no P0/P1/P2 **functional/security** blockers; existing exam correctness remains; owner approval separates merge/deployment. A mock-only AI demo **does not** complete Phase 4. Formal production legal approval and 30/50/100 load are not academic-demo blockers.


## 10. Academic demo acceptance evidence (v1.1)

**Required media proof:** two browsers with distinct identities + five simultaneous real camera publishers, teacher live grid, selective subscriptions and camera disconnect/reconnect. Target ten publishers if the local machine/network permits. Record the count exactly rather than claiming ten if only five pass.

**Required AI proof:** separately show raw real-model detections and aggregated alerts for a phone and multiple people, with actual inference latency on recorded hardware. Stub worker can validate transport/idempotency but must never satisfy this gate. Gaze detection optional until validated.

**Required evidence proof:** actual snapshot, full recording ON and OFF, seekable full video when ON, alert clip via bounded rolling buffer when full recording is OFF, recorded gap after restart, private access negative tests, 30/90 cleanup or time-travel test.

**Required reliability proof:** bad media/network and AI/Egress/S3 outages must not lose accepted answers or change submit/grade; teacher reload sees persistent Attempt timeline and review notes; exact PR HEAD tests and one reproducible demo checklist.

**Not required to pass academic gate:** 30/50/100 simultaneous publishers, managed cloud services, Kubernetes/HA, formal legal impact assessment, real student/pilot production, enterprise runbooks.
