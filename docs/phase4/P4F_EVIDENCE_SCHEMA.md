# P4-F Evidence Manifest — Version 1

**PRIVATE evidence index only.** Required by [P4-F2 #98](https://github.com/hhtuann/Quizopia_System/issues/98) and [P4-F1 #97](https://github.com/hhtuann/Quizopia_System/issues/97). Never commit a filled manifest with PII, camera device labels, secrets, presigned URLs, photos, student video, or private security test material.

The Python standard-library validation tool is in scripts/p4f_gate.py. It checks that required evidence has been **declared** consistently; it CANNOT authenticate the camera devices, check that referenced MP4s exist, confirm a test run, grant legal rights or replace an independent reviewer.

~~~powershell
python scripts/p4f_gate.py C:\private\quizopia-p4f\evidence.json --json
python -m unittest discover -s scripts -p 'test_p4f_gate.py' -v
~~~

**Exit 0 = complete declaration, manual reviewer still required; 2 = missing/unmet fields; 1 = invalid JSON/IO.** CI merely runs unit tests for this validator; it never performs physical camera or model E2E testing.

## Required top-level structure

- schemaVersion: integer 1. scope: ACADEMIC_DEMO. runId: unique nonempty identifier.
- refs: exact 40-character full commit SHAs for system, backend and frontend. These must match the System merged gitlinks and exact-head test evidence.
- environment: nonempty os, browser, livekitVersion, egressVersion, storage.
- consent: true booleans adultsOnly, noticeShown, noDefaultAudio, noAutomaticVerdicts, footageRightsConfirmed. Only mark true when witnessed.
- cameras: array of **at least two** physical-SOURCE records (owner amendment 2026-11-18: e.g. built-in BisonCam + live iPhone via e2eSoft iVCam — virtual driver, physical phone sensor), each with distinct publisherId, deviceIdSha256 and trackSid.
- syntheticBenchmark: object with publishers=5, source=SIMULATED, teacherDecodedAll=true, evidenceRef — the separately-labeled five-simulated-publisher WebRTC benchmark; NEVER counted toward cameras.
- teacherGrid: observedAt timestamp with explicit timezone; private evidenceRef of a redacted screenshot and teacher subscriptions. Every physical camera must be ACTIVE at this exact timestamp.
- ai: separate phone and multiplePeople proof objects, each with real-model identifiers and actual evidence, not fake hooks.
- recording: on (real full video-only segment and seekable playback); off (no full recording, actual rolling-buffer clip).
- faults: six mandatory, each with answer and grade integrity proof.
- security: named negative tests and redacted independent evidence.
- retention: 30-day media/evidence, 90-day activity/review and manual demo purge proof.
- tests: backend, frontend, browserE2e and system; each has passed integer >0, failed integer 0, and private evidenceRef.
- review: independentSecurity, independentFunctional true, outstanding p0=p1=p2=0 and evidenceRef.
- attestation: adult witness identifier (private), physicalDevicesWitnessed, noSyntheticCounted true, and private witness evidenceRef.

## One physical-source camera record (repeat at least twice)

~~~json
{
  "source": "PHYSICAL",
  "publisherId": "anonymous-adult-1",
  "deviceIdSha256": "0000000000000000000000000000000000000000000000000000000000000001",
  "trackSid": "TR_anonymized_1",
  "connectedAt": "2026-11-17T10:00:00+07:00",
  "disconnectedAt": "2026-11-17T10:10:00+07:00",
  "teacherSubscribed": true,
  "decodedFrames": 120,
  "measuredFps": 12.5,
  "evidenceRef": "private-redacted-camera-stats"
}
~~~

**EXAMPLE NOT MEASURED**: The timestamp, FPS, hashes, IDs and values above are placeholders. The real reviewer must compare device identities OFFLINE and watch the teacher grid. Distinct WebRTC track SIDs alone do not prove distinct physical camera sensors. Five Chromium fake cameras, five browsers sharing one webcam, OBS/loopback sources or a duplicate of the same sensor do NOT qualify. The iVCam source qualifies ONLY as the live iPhone sensor (witness the phone streaming).

## AI / recording structure (not actual results)

~~~json
{
  "ai": {
    "phone": {"modelIsReal": true, "source": "PHYSICAL", "modelId": "yolo26s", "alertId": "private-redacted-id", "snapshotRef": "private-snapshot-hash", "clipRef": "private-clip-hash", "evidenceRef": "private-model-proof", "inferenceP95Ms": 250},
    "multiplePeople": {"modelIsReal": true, "source": "PHYSICAL", "modelId": "yolo26s", "alertId": "private-redacted-id", "snapshotRef": "private-snapshot-hash", "clipRef": "private-clip-hash", "evidenceRef": "private-model-proof", "inferenceP95Ms": 250}
  },
  "recording": {
    "on": {"videoFileRef": "private-full-mp4-hash", "playbackEvidenceRef": "private-ffprobe-and-seek", "videoOnly": true, "seekVerified": true},
    "off": {"clipRef": "private-buffer-clip-hash", "playbackEvidenceRef": "private-ffprobe-and-seek", "bufferWasEnabled": true, "noFullRecording": true}
  }
}
~~~

All values above are placeholders. Phone and multiplePeople must be genuine real-model observations with actual snapshot and clip, NOT Playwright mocked detections.

## Faults and security

At least one real attempt, with accepted answer history and submitted-grade comparison, for EACH required kind:

~~~json
{"kind": "CAMERA_LOSS", "answersPreserved": true, "gradeUnaffected": true, "honestDegradedState": true, "evidenceRef": "private-observed-fault-and-db-proof"}
~~~

Required kinds: CAMERA_LOSS, LIVEKIT_RESTART, AI_UNAVAILABLE, EGRESS_FAILURE, MINIO_UNAVAILABLE, STOMP_RESTART.

security object requires true for crossUserMediaDenied, crossClassTimelineDenied, evidenceUrlOwnerOnly, expiredTokenDenied, revokedTokenResidualDocumented, unsignedWebhookDenied, callbackReplayIdempotent and privateBucketVerified; plus evidenceRef. retention object requires media30Days, activity90Days, manualDemoPurge true; plus evidenceRef. All attestations require evidence review, not just checkboxes.

The reviewer must preserve privacy. No staff/member should paste private media, face data, token payloads, unredacted WebRTC stats or presigned URLs into issues. Log hashed/redacted artifact identifiers and exact environment/command results in the final report.

## Gate honesty

A fabricated manifest could pass structural validation; **its existence or exit 0 does not establish P4-F success**. Human physical-device witness, reproducible private media/DB/network traces and independent source/security review remain required. Gaze is experimental and not a substitute for phone/multiple-person AI proof. The independent Python worker proposed by [#88](https://github.com/hhtuann/Quizopia_System/issues/88) remains a separate owner decision; do not mark it implemented without an actual worker.
