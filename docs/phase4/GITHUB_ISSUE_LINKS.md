# Phase 4 — Published GitHub Issues (2026-11-14)

**Tracking repository:** https://github.com/hhtuann/Quizopia_System/issues

**Status:** All 22 Issues created and initially OPEN. These are task trackers only; no AI repo created, source modified, PR merged or service deployed.

| Key | Issue | Title | Dependencies |
|---|---|---|---|
| `P4-EPIC` | [#77](https://github.com/hhtuann/Quizopia_System/issues/77) | [P4-EPIC] Phase 4 — Exam Monitoring, Activity Tracking & AI Proctoring | — |
| `P4-0.1` | [#78](https://github.com/hhtuann/Quizopia_System/issues/78) | [P4-0.1] Finalize ADR-008, API contracts, demo scope and threat model | — |
| `P4-0.2` | [#79](https://github.com/hhtuann/Quizopia_System/issues/79) | [P4-0.2] Audit real phone/person models and design gaze-compatible adapter contract | [P4-0.1](https://github.com/hhtuann/Quizopia_System/issues/78) |
| `P4-A1` | [#80](https://github.com/hhtuann/Quizopia_System/issues/80) | [P4-A1] Session Monitoring Policy, eligibility & immutable freeze | [P4-0.1](https://github.com/hhtuann/Quizopia_System/issues/78) |
| `P4-A2` | [#81](https://github.com/hhtuann/Quizopia_System/issues/81) | [P4-A2] Attempt/browser activity ingestion and client telemetry | [P4-A1](https://github.com/hhtuann/Quizopia_System/issues/80) |
| `P4-A3` | [#82](https://github.com/hhtuann/Quizopia_System/issues/82) | [P4-A3] Atomic accepted-answer history with autosave correctness preserved | [P4-A1](https://github.com/hhtuann/Quizopia_System/issues/80) |
| `P4-A4` | [#83](https://github.com/hhtuann/Quizopia_System/issues/83) | [P4-A4] Durable Attempt timeline read model and monitoring STOMP envelopes | [P4-A2](https://github.com/hhtuann/Quizopia_System/issues/81), [P4-A3](https://github.com/hhtuann/Quizopia_System/issues/82) |
| `P4-B1` | [#84](https://github.com/hhtuann/Quizopia_System/issues/84) | [P4-B1] LiveKit self-hosted and Egress infrastructure design/compose spike | [P4-0.1](https://github.com/hhtuann/Quizopia_System/issues/78), [P4-A1](https://github.com/hhtuann/Quizopia_System/issues/80) |
| `P4-B2` | [#85](https://github.com/hhtuann/Quizopia_System/issues/85) | [P4-B2] Backend verified camera preflight and new Attempt readiness lease | [P4-B1](https://github.com/hhtuann/Quizopia_System/issues/84), [P4-A1](https://github.com/hhtuann/Quizopia_System/issues/80) |
| `P4-B3` | [#86](https://github.com/hhtuann/Quizopia_System/issues/86) | [P4-B3] Student camera client + Teacher selective Camera Grid | [P4-B1](https://github.com/hhtuann/Quizopia_System/issues/84), [P4-B2](https://github.com/hhtuann/Quizopia_System/issues/85) |
| `P4-B4` | [#87](https://github.com/hhtuann/Quizopia_System/issues/87) | [P4-B4] Camera state reconciliation, reconnect gaps and token revocation | [P4-B2](https://github.com/hhtuann/Quizopia_System/issues/85), [P4-B3](https://github.com/hhtuann/Quizopia_System/issues/86) |
| `P4-C1` | [#88](https://github.com/hhtuann/Quizopia_System/issues/88) | [P4-C1] Independent AI service skeleton, model-adapter SDK & transport | [P4-0.2](https://github.com/hhtuann/Quizopia_System/issues/79), [P4-B1](https://github.com/hhtuann/Quizopia_System/issues/84) |
| `P4-C2` | [#89](https://github.com/hhtuann/Quizopia_System/issues/89) | [P4-C2] Integrate real phone/multiple-person detectors and measure performance | [P4-C1](https://github.com/hhtuann/Quizopia_System/issues/88), [P4-0.2](https://github.com/hhtuann/Quizopia_System/issues/79) |
| `P4-C3` | [#90](https://github.com/hhtuann/Quizopia_System/issues/90) | [P4-C3] Temporal detection aggregation, trusted alerts and realtime feed | [P4-C2](https://github.com/hhtuann/Quizopia_System/issues/89), [P4-A4](https://github.com/hhtuann/Quizopia_System/issues/83), [P4-B4](https://github.com/hhtuann/Quizopia_System/issues/87) |
| `P4-D1` | [#91](https://github.com/hhtuann/Quizopia_System/issues/91) | [P4-D1] Private evidence Object Storage and AI snapshot pipeline | [P4-C3](https://github.com/hhtuann/Quizopia_System/issues/90), [P4-B1](https://github.com/hhtuann/Quizopia_System/issues/84) |
| `P4-D2` | [#92](https://github.com/hhtuann/Quizopia_System/issues/92) | [P4-D2] Opt-in per-Attempt Egress full recording and segment recovery | [P4-B2](https://github.com/hhtuann/Quizopia_System/issues/85), [P4-B4](https://github.com/hhtuann/Quizopia_System/issues/87), [P4-D1](https://github.com/hhtuann/Quizopia_System/issues/91) |
| `P4-D3` | [#93](https://github.com/hhtuann/Quizopia_System/issues/93) | [P4-D3] Evidence video clips from full recording OR bounded rolling buffer | [P4-D2](https://github.com/hhtuann/Quizopia_System/issues/92), [P4-D1](https://github.com/hhtuann/Quizopia_System/issues/91), [P4-C3](https://github.com/hhtuann/Quizopia_System/issues/90) |
| `P4-D4` | [#94](https://github.com/hhtuann/Quizopia_System/issues/94) | [P4-D4] Playback authorization, evidence retention & orphan cleanup | [P4-D2](https://github.com/hhtuann/Quizopia_System/issues/92), [P4-D3](https://github.com/hhtuann/Quizopia_System/issues/93) |
| `P4-E1` | [#95](https://github.com/hhtuann/Quizopia_System/issues/95) | [P4-E1] Unified teacher monitoring overview & per-Attempt timeline UI | [P4-A4](https://github.com/hhtuann/Quizopia_System/issues/83), [P4-B3](https://github.com/hhtuann/Quizopia_System/issues/86), [P4-C3](https://github.com/hhtuann/Quizopia_System/issues/90), [P4-D4](https://github.com/hhtuann/Quizopia_System/issues/94) |
| `P4-E2` | [#96](https://github.com/hhtuann/Quizopia_System/issues/96) | [P4-E2] Alert review, false-positive feedback and Attempt monitoring reports | [P4-E1](https://github.com/hhtuann/Quizopia_System/issues/95), [P4-C3](https://github.com/hhtuann/Quizopia_System/issues/90) |
| `P4-F1` | [#97](https://github.com/hhtuann/Quizopia_System/issues/97) | [P4-F1] Independent security review and demo hardening | [P4-E2](https://github.com/hhtuann/Quizopia_System/issues/96), [P4-D4](https://github.com/hhtuann/Quizopia_System/issues/94), [P4-B4](https://github.com/hhtuann/Quizopia_System/issues/87) |
| `P4-F2` | [#98](https://github.com/hhtuann/Quizopia_System/issues/98) | [P4-F2] 5–10 camera demo benchmark, failure injection, real AI E2E and runbook | [P4-F1](https://github.com/hhtuann/Quizopia_System/issues/97), [P4-C2](https://github.com/hhtuann/Quizopia_System/issues/89) |

## Milestone counts

| Milestone | Task count |
|---|---:|
| P4-0 — Architecture & AI feasibility | 2 |
| P4-A — Monitoring Foundation | 4 |
| P4-B — Camera Infrastructure | 4 |
| P4-C — AI Proctoring | 3 |
| P4-D — Evidence & Recording | 4 |
| P4-E — Unified Monitoring & Review | 2 |
| P4-F — Demo Reliability & Integration | 2 |

## Important boundaries

- **Demo:** 5 simultaneous real webcams minimum, 10 target, real phone/person model. Clips from actual full recording or bounded rolling buffer. Use consenting adults or approved synthetic footage and never claim mock AI equals real AI.
- **Deferred:** 30/50/100 concurrent users, formal production legal sign-off, enterprise HA.
- **Separate gates:** Creating Issue is not permission to create the AI repository/submodule, implement source, merge PR or deploy.
- **Source baseline:** System `86cdb2e`; Backend `972d6a9`; Frontend `7a01090`. Recheck current Git main before implementation.

## Recommended order

1. Review P4-0.1 ([#78](https://github.com/hhtuann/Quizopia_System/issues/78)) and provide model artifacts for P4-0.2 ([#79](https://github.com/hhtuann/Quizopia_System/issues/79)).
2. On separate implementation authorization, begin P4-A1 ([#80](https://github.com/hhtuann/Quizopia_System/issues/80)), then advance following dependency chains.
3. Use `DEMO_RUNBOOK.md` as the end-to-end acceptance script; maintain PR HEAD, CI and real-model evidence.

**This is a generated index of published Issues; if a user edits GitHub Issues later, GitHub is the canonical source.**
