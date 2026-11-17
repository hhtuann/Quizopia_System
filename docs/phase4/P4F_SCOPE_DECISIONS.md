# P4-F — Proposed Scope Reconciliation Before Closing Epic #77

**Status: PROPOSED for explicit Product Owner decision. No permission or waiver is inferred by this file.** P4-A through P4-E and experimental browser gaze were merged. Original Epic [#77](https://github.com/hhtuann/Quizopia_System/issues/77) and child issues still contain requirements written before browser-first AI was selected.

## Open issue reconciliation

| Issue | Present reality | Required explicit terminal disposition |
|---|---|---|
| [#78 P4-0.1](https://github.com/hhtuann/Quizopia_System/issues/78) architecture package | ADR-008 + amendments, API/event contracts, Quality Gates, security and demo designs exist in source; issue remains OPEN | Independent architecture/security sign-off against final implemented HEADs, then close as completed if acceptance demonstrated (no retroactive invention of testing) |
| [#88 P4-C1](https://github.com/hhtuann/Quizopia_System/issues/88) independent AI Worker | The browser's ONNX Runtime Web runs real YOLO26s and experimental face+gaze; Backend has authenticated worker-compatible callback, **but no independent LiveKit-subscribing Python Worker/service/repo** | **Option A (recommended for existing academic-demo scope):** Product Owner explicitly removes the independent worker from P4 acceptance, transfers it to a future issue/phase with a link, closes #88 as superseded/rescoped (not as implemented). **Option B:** build and test actual independent worker and keep #88 open until real completion |
| [#97 P4-F1](https://github.com/hhtuann/Quizopia_System/issues/97) | Draft security checklist/runbook exists; no new independent exact-head full runtime audit or live negative test has been demonstrated in this response | Execute negative tests, independent P0/P1/P2 review and honest evidence |
| [#98 P4-F2](https://github.com/hhtuann/Quizopia_System/issues/98) | Five synthetic WebRTC camera publishers and a one-physical-camera smoke were previously proven; new Draft real-5-camera harness exists but has **not run on five devices** | Five distinct PHYSICAL cameras at one instant, actual model/evidence/recording/fault proof, measured results and independent witness |

## Proposed decision P4-F-D1 — Browser-first AI as academic-demo boundary

The university **academic-demo** acceptance may rely on real shipped local browser YOLO26s inference with CLIENT_MODEL provenance and teacher-reviewed observations, provided it is never called a server-verified, independent AI Worker. The Backend worker-compatible API remains as a secure future integration point. Defer the Python LiveKit subscriber, queue, worker scheduling, work distribution, GPU worker deployment and a separate AI repository/submodule to a future explicitly authorized workstream; do not create it merely to close a checklist.

If the Product Owner chooses this rescope, update Epic #77's architecture/acceptance wording and cross-link the new deferred issue before closing #88. Existing P4 F1/F2 tests then inject browser AI-model failure/unavailability, rather than falsely claiming a worker outage run. This decision **does not weaken** the mandatory phone/multiple-person real-model demo or five physical webcams.

## Proposed decision P4-F-D2 — Gaze is experimental and not a misconduct verdict

Gaze is an optional supplementary observation. The face and gaze model upstream release licensing is documented; related WIDER FACE/Gaze360 research-only dataset terms mean no commercial deployment claim. Academic-demo mandatory model proof remains phone and multiple-people, which require real inference and actual alert/evidence artifacts. Do not use simulated H8 to claim model accuracy.

## NON-NEGOTIABLE P4-F conditions

- **Five distinct PHYSICAL webcam devices concurrently** with live teacher-decoded frames, independent witness; five virtual cameras do not qualify. Ten optional.
- Consent of adults / approved footage, no default audio/hidden recording, private playback and 30/90 retention, no automatic AI verdict or grade impact.
- Real phone/multiple-person inference, actual private snapshot/seekable clips and full-recording ON/OFF behavior.
- Security IDOR/replay/MinIO/token negative tests, fault injection and answers/grade preserved, independent no-P0/P1/P2 findings.
- Exact-head CI and manual real-media E2E evidence. A green manifest-validator CI is only a validator test.
- Do not merge/deploy or close Phase 4 until owner explicit GO based on real artifacts.

## Decision record (leave unset until actual owner approval)

- Owner choice #88: UNDECIDED (A browser-first rescope / B build worker)
- Independent architect/security sign-off #78: NOT RECORDED
- P4-F1 independent security evidence: NOT RECORDED
- Five simultaneous PHYSICAL cameras #98: NOT RECORDED
- Actual-model/full media/fault gate #98: NOT RECORDED
- Epic #77 final GO: NOT GRANTED

This document proposes the cleanest path to legitimate P4 completion, not a false assertion that unbuilt scope or unperformed hardware work passed.
