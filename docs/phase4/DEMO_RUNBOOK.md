# Quizopia P4-F — Final Academic Demo Runbook

**Status: EXECUTED & ACCEPTED (2026-11-18 closure).** The amendment gates were executed with private evidence (Epic #77 Final Integration Report v2); Phase 4 is CLOSED. This runbook remains the reproducible procedure for future demos. Original scope: [Epic #77](https://github.com/hhtuann/Quizopia_System/issues/77), [P4-F1 #97](https://github.com/hhtuann/Quizopia_System/issues/97), [P4-F2 #98](https://github.com/hhtuann/Quizopia_System/issues/98). **Product Owner amendment 2026-11-18:** the physical gate is **TWO simultaneous independent real camera SOURCES** — the built-in BisonCam NB Pro plus a live iPhone camera delivered via e2eSoft iVCam (a Windows virtual driver whose source is a physical phone sensor; the driver being virtual does NOT disqualify it). OBS/loopback/synthetic Chromium devices never qualify. Separately, five SIMULATED publishers over real LiveKit/WebRTC form a labeled benchmark section and are never counted as physical sources.

Academic demo only: consenting adults or approved synthetic media (synthetic does not satisfy the two-physical-source gate). No real-student rollout, hidden recording, microphone by default, public media, auto-cheating verdict or grade impact. Recording OFF by default; media/evidence retention 30 days and activity/review metadata 90 days.

## 1. Preserve baseline and prepare isolated environment

From the System repo root record full commit SHAs using git rev-parse HEAD and git ls-tree HEAD backend frontend, plus Backend and Frontend git rev-parse HEAD. Keep local Docker volumes and owner changes. Use fresh test accounts, consented adult participants, private evidence directory **outside Git**; never commit access tokens, device labels/IDs, recordings, presigned URLs, photos or participant identities.

Prerequisites: Docker Desktop, Java 21, Maven wrapper, Node/npm, Chromium, Playwright, ffmpeg/ffprobe, MinIO, LiveKit + Egress. Have **two real sources**: the workstation's built-in camera plus an iPhone running the e2eSoft iVCam app (witness the phone actually streaming). Capture environment hardware, OS, network topology and version pins in private manifest.

## 2. Start real local services

From System root (PowerShell; secrets in gitignored .env.livekit, never in Git):

~~~powershell
docker compose up -d
docker compose --env-file .env.livekit -f docker-compose.livekit.yml --profile egress up -d
docker compose ps
curl.exe http://localhost:7880
~~~

For host-run backend/Next use the matching environment in [infra/livekit/README.md](../../infra/livekit/README.md) and [P4-D reproducibility](https://github.com/hhtuann/Quizopia_Frontend/blob/main/e2e/P4D-REPRODUCIBILITY.md): Backend LIVEKIT enabled, credentials matching .env.livekit, RoomService localhost:7880, WebSocket address reachable by EVERY physical client, private MinIO credentials and valid Egress storage endpoint. Other laptops accessing a LAN URL will generally need HTTPS/TLS for getUserMedia; localhost on the server is NOT reachable as localhost from other devices. Test TURN/ICE UDP and firewall routes. Never expose dev secrets or MinIO publicly.

### Existing regression commands (SYNTHETIC browser camera suite)

~~~powershell
# Backend repo
.\mvnw.cmd clean verify
# Frontend repo
npm ci
npx tsc --noEmit
npm run lint
npm test
npm run build
npx playwright test --config e2e/playwright.config.ts
# Real-model benchmark on ONE PHYSICAL webcam (interactive)
node e2e/gaze-benchmark.mts --webcam
~~~

The Playwright config uses Chromium fake-device flags, and cannot satisfy #98 hardware. The gaze benchmark runs real ONNX inference but is NOT by itself a full teacher-grid/attempt demo or multi-device benchmark. Distinguish fake detector test hooks, simulated camera video, and actual inference.

## 3. Two physical-source cameras: mandatory witnessed gate (amendment 2026-11-18)

1. Teacher creates a published Exam, active classroom and monitored CLASS_RESTRICTED Session assigned to that class (PUBLIC and zero-class monitoring rejected). Use two recording configurations in separate disposable sessions: full recording OFF+clip ON and full recording ON.
2. Two consenting adults (or one operator + one participant) sign off notice covering camera, AI observations, snapshots, video, rolling buffer, retention and review; each uses a separate user account on a separate PHYSICAL camera SOURCE (built-in BisonCam; live iPhone via e2eSoft iVCam). No OBS, loopback, fake device flags, prerecorded source or reusing one sensor for both publishers.
3. Each browser allows real camera permission, sees preview, completes server preflight and starts the Attempt. Verify video-only publication and live teacher authorization.
4. At ONE timestamp, teacher sees TWO LIVE subscribed tiles with decoded frames; record anonymized publisher identity, distinct deviceId SHA-256 pseudonym, trackSid, connectedAt, disconnectedAt, measured FPS, number decoded frames and teacher-grid screenshot. Both camera lifetimes must enclose the SAME teacher grid observedAt.
5. A separate adult reviewer witnesses (a) the iPhone physically streaming into iVCam (live scene + iVCam watermark) and (b) the built-in camera as a distinct sensor. Never upload serials, labels or faces.
6. Capture anonymized WebRTC stats, SFU CPU/RAM/bandwidth, Chrome getStats samples, frontend/Backend timings and measured reconnect latencies. Do not mistake frames published for frames actually decoded by the teacher.

## 4. Actual AI and evidence — both recording policies

On a consented camera, physically show a PHONE and have another consenting adult enter the frame. Confirm **real shipped YOLO26s model** (not fake hook), typed phone/multiple-person events, grouped teacher alerts, confidence/provenance and measured inference p50/p95. Mark CLIENT_MODEL as an observation, never WORKER_VERIFIED or misconduct verdict; independent worker #88 remains unimplemented.

For EACH required alert: check bound Attempt, alert timestamp, private snapshot hash, accurate first-frame bbox and a real ffprobe-verified seekable clip. In recording ON, verify video-only full MP4 size/checksum, S3 HEAD and playback seek. In recording OFF, verify no full recording, but real bounded rolling buffer clip, including honest PARTIAL when coverage is missing. Confirm access audit and short-lived teacher-only playback URL. Preserve accepted-answer history and grade independent of all media/AI failures. Experimental gaze can be shown separately, but does not replace phone + multiple-person proof.

## 5. Failure injection in the disposable environment

Capture before/after accepted answers, submitted grade, source states, gap/report screenshots, logs and recovery. Never damage actual users' Docker volumes.

| Fault to induce deliberately | Expected proof |
|---|---|
| CAMERA_LOSS, then restore webcam | Camera gap and reconnect; autosave/submission survive |
| LIVEKIT_RESTART (isolated local SFU) | Honest media gap, no phantom recording/coverage |
| AI_UNAVAILABLE (block ONNX resource or inference) | No false accusation; Attempt, answers and grade unaffected |
| EGRESS_FAILURE (stop/restart local Egress) | PARTIAL/FAILED state, never AVAILABLE solely on start ACK |
| MINIO_UNAVAILABLE (stop/restart isolated local storage) | Honest PENDING/FAILED media; autosave/grade still correct |
| STOMP_RESTART | REST cursor recovery, durable timeline/reviews, no duplicate accepted answers |

A nonexistent independent Python worker cannot be outage-tested. Document the implemented browser-first architecture and explicitly resolve #88 as a future scope item **only with Product Owner approval**, rather than falsely marking it built.

## 6. Security / privacy & retention

Independent reviewer uses unauthorized other-student/other-class accounts and confirms media/grid, timeline, evidence, report and answers are access denied. Test expired and revoked LiveKit token rejoin (self-host stale token residual exposure ~120 s is documented, not a guarantee of immediate eviction); unsigned/replayed webhook; wrong Attempt/media binding; forged AI callback; private MinIO; expired playback URL; rate abuse. No default audio or hidden full recording. Test camera permission denied, browser reload and basic keyboard navigation.

Verify 30-day media/evidence, 90-day activity/review sweeps, rolling temp purge and manual evidence purge for the **disposable** session via DELETE /api/exam-sessions/{sessionId}/evidence. Do not delete unrelated Attempt or grades; do not use docker compose down -v. Record review findings and proof of P0/P1/P2 fixes. See [P4F_SECURITY_REVIEW.md](P4F_SECURITY_REVIEW.md).

## 7. Manifest and terminal Final Gate

Store a PRIVATE JSON manifest following [P4F_EVIDENCE_SCHEMA.md](P4F_EVIDENCE_SCHEMA.md); no real students, raw media or tokens in Git.

~~~powershell
python scripts/p4f_gate.py C:\private\quizopia-p4f\evidence.json --json
python -m unittest discover -s scripts -p 'test_p4f_gate.py' -v
~~~

This validator checks declared *distinctness, temporal overlap, evidence completeness and no mocks*. It cannot prove physical sensors, actually inspect referenced files, attest to consent, validate legal rights or execute a media test. Independent reviewer MUST inspect the private evidence and witness devices.

**GO** only with two witnessed simultaneous physical-SOURCE cameras (BisonCam + live iPhone/iVCam per the 2026-11-18 amendment) plus the separately-labeled five-SIMULATED-publisher benchmark; real model phone/multiple-person alerts; actual private snapshot, clip, video ON/OFF; recorded faults without data loss; security/access negatives; retention/purge; exact-head green tests/CI, independent P0/P1/P2-free review, and an explicit disposition of still-open architecture/worker issue #88. Ten cameras, 30/50/100 scaling and formal commercial rollout are non-goals.

**NO-GO** if only synthetic WebRTC cameras, modeled-only detections, missing private evidence, missing device concurrency, faulty access controls, P0/P1/P2 or unresolved owner policy blockers. Do not close Epic #77, merge feature PRs or deploy without the actual gate and separate Product Owner approval.
