# P4-F — Scope Reconciliation Record (Phase 4 CLOSED)

**Status: APPROVED & COMPLETED (2026-11-18).** Product Owner authorized the Phase 4 closure (Epic #77 final comment, 2026-11-18): the Final Integration Report v2 was approved, all three P4-F PRs merged, and Epic #77 closed as completed. This file is now a historical record of the decisions taken — earlier "PROPOSED/UNDECIDED" states are preserved below in the decision-record history for audit.

## Final merged baseline (owner-verified, 2026-11-18)

| Repo | PR | Merge SHA | Post-merge CI |
|---|---|---|---|
| Backend | [#30](https://github.com/hhtuann/Quizopia_Backend/pull/30) | `4eba11eef13b6b128f5d6e6a146edfef680a9598` | [SUCCESS — Backend CI](https://github.com/hhtuann/Quizopia_Backend/actions/runs/44231002668) |
| Frontend | [#31](https://github.com/hhtuann/Quizopia_Frontend/pull/31) | `461e17d849792583233b5e18000448d5299c279f` | [SUCCESS — Frontend CI](https://github.com/hhtuann/Quizopia_Frontend/actions/runs/44231941767) |
| System | [#110](https://github.com/hhtuann/Quizopia_System/pull/110) (supersedes #109; GitHub records #109 as MERGED — its head `b823b51` entered main as an ancestor of `5d722ee`) | `5d722ee6ce2818a865045e3edc804ca3255d85cf` | [SUCCESS — Evidence CI](https://github.com/hhtuann/Quizopia_System/actions/runs/44232160082) · [SUCCESS — Pages](https://github.com/hhtuann/Quizopia_System/actions/runs/44232160204) |

System merged-main gitlinks at `5d722ee` point to the merged Backend/Frontend **main** SHAs above (verified by the owner at closure; see commit `21cba4c`). No manual deployment was performed.

## Terminal issue dispositions (all owner-executed 2026-11-18)

| Issue | Disposition |
|---|---|
| [#77](https://github.com/hhtuann/Quizopia_System/issues/77) P4 Epic | **CLOSED AS COMPLETED** — owner accepted the Final Integration Report v2 |
| [#78](https://github.com/hhtuann/Quizopia_System/issues/78) architecture package | **CLOSED — SIGNED OFF** by the owner (ADR-008 + amendments reconciled with source; independent review found no P0/P1/P2) |
| [#88](https://github.com/hhtuann/Quizopia_System/issues/88) independent AI Worker | **CLOSED AS NOT PLANNED (Option A)** — never implemented, never claimed; deferred to POST-P4 [#111](https://github.com/hhtuann/Quizopia_System/issues/111) |
| [#97](https://github.com/hhtuann/Quizopia_System/issues/97) P4-F1 security | **CLOSED** — independent review: 0×P0/P1/P2; 4×P3 fixed with regression; live IDOR negatives PASS |
| [#98](https://github.com/hhtuann/Quizopia_System/issues/98) P4-F2 demo gate | **CLOSED** — two-physical-source gate + real-model detection + recording/fault/security gates PASS |
| [#111](https://github.com/hhtuann/Quizopia_System/issues/111) POST-P4 AI Worker | **OPEN** — post-P4 backlog, explicitly not a Phase 4 item |

## Decision P4-F-D1 — Browser-first AI as the academic-demo boundary — APPROVED (Option A)

The university **academic-demo** acceptance relies on real shipped local browser YOLO26s inference with CLIENT_MODEL provenance and teacher-reviewed observations; it is never described as a server-verified, independent AI Worker. The Backend worker-compatible API (`POST /internal/ai/v1/detections`, constant-time key auth, deny-all when unset, replay protection) remains as a secure future integration point. The independent Python LiveKit-subscribing worker (queue, scheduling, work distribution, GPU deployment, separate AI repository/submodule) is **deferred to POST-P4 #111** — not implemented, not authorized during P4, and never claimed as built. Existing P4 F1/F2 tests inject browser AI-model failure/unavailability rather than claiming worker-outage runs. This decision did not weaken the mandatory phone/multiple-person real-model demo (both proven on hardware).

## Decision P4-F-D2 — Gaze is experimental and not a misconduct verdict — APPROVED

Gaze remains an optional supplementary observation only. The face/gaze model upstream licensing and the WIDER FACE/Gaze360 research-only dataset terms stand; no commercial deployment claim. The mandatory model proof was and remains phone + multiple-people with real inference and actual alert/evidence artifacts. Simulated H8 was never used to claim model accuracy.

## Amendment acceptance record (2026-11-18) — ACCEPTED BY OWNER

- **Two physical-SOURCE cameras (BisonCam NB Pro + live iPhone via e2eSoft iVCam)**: gate PASSED — 2 separate Students/Attempts over real LiveKit; teacher grid decoded NEW frames on BOTH exact camera trackSIDs (~20 FPS each); iVCam verified streaming the real phone sensor; OBS/loopback/synthetic never counted. The consenting-adult operator witnessed the live iPhone during the run.
- **Five SIMULATED publishers over real LiveKit/WebRTC — a SEPARATE, explicitly-labeled benchmark** (6/6 PASS incl. selective subscription, camera loss, SFU restart, revocation, submit-after-storm): never counted toward the physical-source gate.
- **Real-model detection on hardware**: PHONE (`cell phone`, conf 0.86) + MULTIPLE_PERSONS (72/72 frames ≥2 persons, conf 0.96) via real yolo26s/ORT_WEB_WEBGPU on the physical BisonCam; typed events ACCEPTED through the real ingest; real teacher alerts (CLIENT_MODEL provenance).
- Recording ON/OFF (real egress MP4 + real rolling-buffer clip), fault injection 15/15, IDOR negatives 7/7 + 12/12 — all re-verified at the final HEADs. Review loop closed with **no open P0/P1/P2** (4 independent review rounds).

## NON-NEGOTIABLE P4-F conditions (as enforced at the gate — met)

- **Two simultaneous independent physical-SOURCE cameras** (built-in BisonCam + live iPhone via e2eSoft iVCam — virtual driver, physical phone sensor) with live teacher-decoded frames on both exact trackSIDs; OBS/loopback/synthetic never qualified. **Plus** the separately-labeled five-SIMULATED-publisher WebRTC benchmark (never counted as physical). (Superseded the pre-amendment five-device wording.)
- Consent of adults / approved footage, no default audio/hidden recording, private playback and 30/90 retention, no automatic AI verdict or grade impact.
- Real phone/multiple-person inference, actual private snapshot/seekable clips and full-recording ON/OFF behavior.
- Security IDOR/replay/MinIO/token negative tests, fault injection and answers/grade preserved, independent no-P0/P1/P2 findings.
- Exact-head CI and manual real-media E2E evidence. A green manifest-validator CI is only a validator test.
- ~~Do not merge/deploy or close Phase 4 until owner explicit GO based on real artifacts.~~ → **Owner GO granted 2026-11-18; Phase 4 closed. No deployment performed.**

## Decision record — final state (history preserved)

- Owner choice #88: **APPROVED Option A** (browser-first rescope; worker deferred to #111; #88 closed as not planned).
- Independent architect/security sign-off #78: **RECORDED & OWNER SIGNED OFF (2026-11-18)** — independent security review of Backend main `36880db` found **no P0/P1/P2**; 4 P3 hygiene findings (purge gate indirection, unbounded policy cache, worker-ingest admission order, report join robustness) fixed in PR #30 with targeted Testcontainers regression. Live IDOR probe (7 standard routes + 12 extended negatives incl. media-token renewal, snapshot upload, review write, unsigned webhook, keyless worker ingest) all PASS on the real running stack. Architecture docs (ADR-008 + Amendments, AI_PROCTORING_CONTRACT hybrid decision, API_EVENT_CONTRACTS) reconciled with source; the only stale text noted was the historical "V32 latest" baseline note in TECHNICAL_DESIGN.md §2 (written pre-implementation; migrations ended at V43, forward-only, never rewritten).
- P4-F1 independent security evidence: **RECORDED & ACCEPTED (2026-11-18)** — details above; private evidence archive `idor-live-evidence.md`.
- Two-physical-source gate #98: **PASSED & ACCEPTED 2026-11-18** (BisonCam + iPhone/iVCam, 2 Students/Attempts, teacher grid decoded ~20 FPS on both trackSIDs; harness hardened after 6 QA findings + the label-based deviceId pinning root-cause fix for Chromium's per-context deviceId salting). Human iPhone witness: the consenting-adult operator witnessed the live phone streaming during the gate run; evidence JSON honestly carried `…HUMAN_IPHONE_WITNESS_PENDING` until owner acceptance.
- Actual-model/full media/fault gate #98: **PASSED & ACCEPTED 2026-11-18** — synthetic WebRTC E2E 35/35 suite PASS; real-model benchmark + on-hardware detection PASS; fault injection 15/15 PASS; recording ON/OFF PASS. Results in the Final Integration Report v2 (Epic #77).
- Epic #77 final GO: **GRANTED 2026-11-18 — Phase 4 CLOSED AS COMPLETED.**

### Historical blockers (resolved or superseded — kept for the record)

- Pre-amendment hardware blocker ("workstation has ONE physical camera; needs 4 more or 5 laptops") — **superseded** by the owner amendment (two physical sources) and resolved by the PASSED two-source gate.
- OTP issuance IP rate limit (20/h) exhausting during full-suite seeding — mitigated in the isolated dev run only via a dev environment override; never a product change.
- LiveKit Windows UDP port-exclusion overlap — resolved with a local-only compose override (ICE 52000→52100 range documented locally); no repo product change.

### Academic-demo limitations (still true — unchanged by closure)

University course demonstration only: no production certification, no real-student rollout, no formal legal/privacy sign-off, no 30/50/100-camera scaling, no commercial SLA. Evidence media and identities remain private (never committed). The independent Python AI Worker remains future work in #111.

This document records the approved closure path actually taken; it does not retroactively claim anything that was not demonstrated.
