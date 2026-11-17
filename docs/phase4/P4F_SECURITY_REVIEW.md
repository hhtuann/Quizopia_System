# P4-F1 Independent Security and Reliability Review Checklist

**Status: OPEN REVIEW PLAN; NO PASS CLAIMS.** Scope [#97](https://github.com/hhtuann/Quizopia_System/issues/97). Review against exact current Backend/Frontend PR HEADs and merged System gitlinks. Do not infer tested behavior from class or test file names. A second reviewer should reproduce negatives with two unrelated demo accounts and an isolated session; document observed status codes and redacted traces.

## Threat model and evidence assignments

| Threat / failure mode | Reviewer actions and required negative proof | Current test/source starting point |
|---|---|---|
| Cross-user camera subscription | Wrong student/teacher tries to obtain teacher camera token/grid; verify Backend auth and LiveKit canSubscribe grants | CameraPreflightServiceIntegrationTests, MonitoringStompIntegrationTests, Frontend Scenario E/F/G |
| Cross-class timeline/results | Unrelated authenticated teacher tries activity/Attempt/report APIs; deny without ownership, even knowing IDs | AttemptTimelineServiceIntegrationTests, MonitoringDashboardHardeningIntegrationTests |
| Evidence URL IDOR | Unrelated account requests evidence metadata and presigned URL by guessing IDs; verify 403/404 and no URL disclosure | EvidencePlaybackIntegrationTests, EvidenceSnapshotIntegrationTests |
| Revoked token | Revoke/RemoveParticipant and rejoin with old LiveKit token; measure residual ability until 120s expiry, document mitigations instead of assuming immediate eviction | infra/livekit/README.md; Frontend Scenario G / measure-turn-residual.mts |
| Webhook spoof/replay | Unsigned, stale, duplicate and out-of-order webhook; reject or idempotently no-op without wrong binding | LiveKitWebhookControllerIntegrationTests, LiveKitWebhookServiceIntegrationTests |
| AI worker callback replay | Wrong worker key, duplicate event ID, late old media epoch, wrong Attempt, malformed payload; grade unaffected | AiWorkerIngestIntegrationTests, AiDetectionIngestIntegrationTests |
| Answers under outage/race | Concurrent autosave and submit with camera/SFU/storage outage; only committed accepted events and correct grade | MonitoringStompIntegrationTests, AnswerHistoryReadIntegrationTests, main attempt concurrency tests |
| Evidence media integrity | Snapshot wrong alert; clip lacks real pre/post media; egress success without S3 HEAD; expired URL; wrong bbox/frame provenance | EvidenceSnapshotIntegrationTests, EvidenceClipRealFfmpegIntegrationTests, RecordingCoordinatorIntegrationTests |
| Retention / purge | 30d media/evidence and 90d activity/review expiry, 29/30/31 and 89/90/91 boundary cases, preserve grades; manual DELETE demo evidence | EvidenceRetentionIntegrationTests, MonitoringRetentionHardeningIntegrationTests |
| AI failure isolation | Disable ONNX fetch or cause gaze inference hang; phone detector/answers/grades unaffected; no fabricated accuracy claim | gaze-adapter.test.ts, model-adapter.test.ts, use-attempt-ai-detection.test.ts |
| Browser camera denial | Deny device permission, unplug camera, resume Attempt and verify no forced submit; keyboard accessible notice/errors | Frontend Scenario E/G and real-webcam-flow.mts |
| Storage hardening | Check MinIO private bucket denies anonymous listing/object GET; Egress and Backend service keys separate where configured | Dev compose, media gateway configuration, EvidencePlaybackIntegrationTests |
| Audio / disclosure | Default microphone track absent; notice accurate on full recording and bounded rolling-buffer clips; teacher assessment never shown to student | P4-D recording e2e, P4-C H8, policy/consent UI |
| Real-model claims | Phone and multiple people require actual ONNX model on approved footage, never a fake detector; review high false-positive load | Frontend ai-benchmark.mts, gaze-benchmark.mts; separate real webcam proof |

## Exact-head verification commands

From the **Backend feature branch**: Java 21, PostgreSQL Testcontainers, run Maven wrapper clean verify plus targeted monitoring suites, record exact SHA/CI run. From the **Frontend feature branch**: npm ci, npx tsc --noEmit, npm run lint, npm test, npm run build, then npx playwright test --config e2e/playwright.config.ts against real backend/LiveKit/Egress/MinIO with **synthetic cameras labeled**. On a separate physical 5-camera environment execute [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md) — this final gate cannot be exercised in GitHub-hosted CI.

All tests should use isolated consenting accounts. Do not disable authentication to make a negative test pass. Never commit sensitive evidence. The independent reviewer must report:

1. Full SHA, dependency versions, exact command, passed/failed/skipped counts, real hardware count and redacted evidence file references.
2. P0/P1/P2 issue IDs and reproducible steps; retest proof after each fix. A green historical CI does not replace exact-head rerun after changes.
3. Security outcome per row: **PASS with actual proof**, **FAIL with finding**, **BLOCKED by real external dependency**, or **NOT RUN**. Do not mark test class existence as PASS.
4. Access token lifetime/rejoin residual behavior, MinIO privacy audit, webcam notice/consent and default recording OFF.
5. Model source/weight licenses and dataset research-only restrictions; no commercial-use representation for experimental gaze without owner review.
6. Final independent security signature/notes, functional reviewer and separate Product Owner GO/NO-GO.

## P4-F1 decision rules

Security GO requires no open P0/P1/P2, verified cross-user/stream/evidence negatives, replay/expiry outcomes, honest 30/90 retention and demo purge, no grading impact, no default audio or hidden recording. Missing private media proof or independent review is **NO-GO**, even if CI is green.

The original independent LiveKit-subscribing Python worker [#88](https://github.com/hhtuann/Quizopia_System/issues/88) does not exist: the implemented deployment is browser-first CLIENT_MODEL observations plus authenticated Backend worker-compatible callback. Never describe worker-specific fault injection as executed; defer or change scope only by explicit owner decision. This review is for the academic demo, not production certification.
