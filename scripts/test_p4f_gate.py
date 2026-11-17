#!/usr/bin/env python3
"""Tests for evidence-contract completeness; NOT hardware tests."""
import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from p4f_gate import review_manifest
from p4f_idor_probe import assess as assess_idor


def valid_manifest():
    start = "2026-11-17T10:00:00+07:00"
    end = "2026-11-17T10:10:00+07:00"
    grid = "2026-11-17T10:05:00+07:00"
    record = {
        "modelIsReal": True, "source": "PHYSICAL", "modelId": "yolo26s",
        "alertId": "alert-123", "snapshotRef": "private/snapshot.sha256",
        "clipRef": "private/clip.sha256", "evidenceRef": "private/ai-log.txt",
        "inferenceP95Ms": 250,
    }
    return {
        "schemaVersion": 1, "scope": "ACADEMIC_DEMO", "runId": "p4f-test-run",
        "refs": {"system": "a" * 40, "backend": "b" * 40, "frontend": "c" * 40},
        "environment": {
            "os": "Windows 11", "browser": "Chromium 127",
            "livekitVersion": "1.9.0", "egressVersion": "1.9.0", "storage": "private MinIO",
        },
        "consent": {
            "adultsOnly": True, "noticeShown": True, "noDefaultAudio": True,
            "noAutomaticVerdicts": True, "footageRightsConfirmed": True,
        },
        "cameras": [
            {
                "source": "PHYSICAL", "publisherId": f"adult-{i}",
                "deviceIdSha256": f"{i:064x}", "trackSid": f"TR_{i:06d}",
                "connectedAt": start, "disconnectedAt": end,
                "teacherSubscribed": True, "decodedFrames": 120,
                "measuredFps": 12.5, "evidenceRef": f"private/camera-{i}.json",
            }
            for i in range(5)
        ],
        "teacherGrid": {"observedAt": grid, "evidenceRef": "private/grid.png"},
        "ai": {"phone": copy.deepcopy(record), "multiplePeople": copy.deepcopy(record)},
        "recording": {
            "on": {"videoFileRef": "private/full.mp4.sha256",
                   "playbackEvidenceRef": "private/playback-on.txt",
                   "videoOnly": True, "seekVerified": True},
            "off": {"clipRef": "private/rolling-clip.sha256",
                    "playbackEvidenceRef": "private/playback-off.txt",
                    "bufferWasEnabled": True, "noFullRecording": True},
        },
        "faults": [
            {"kind": kind, "answersPreserved": True, "gradeUnaffected": True,
             "honestDegradedState": True, "evidenceRef": f"private/{kind}.txt"}
            for kind in (
                "CAMERA_LOSS", "LIVEKIT_RESTART", "AI_UNAVAILABLE",
                "EGRESS_FAILURE", "MINIO_UNAVAILABLE", "STOMP_RESTART"
            )
        ],
        "security": {
            **{k: True for k in (
                "crossUserMediaDenied", "crossClassTimelineDenied",
                "evidenceUrlOwnerOnly", "expiredTokenDenied",
                "revokedTokenResidualDocumented", "unsignedWebhookDenied",
                "callbackReplayIdempotent", "privateBucketVerified"
            )},
            "evidenceRef": "private/security-review.md",
        },
        "retention": {
            "media30Days": True, "activity90Days": True,
            "manualDemoPurge": True, "evidenceRef": "private/purge.txt",
        },
        "tests": {
            suite: {"passed": 1, "failed": 0, "evidenceRef": "private/ci.txt"}
            for suite in ("backend", "frontend", "browserE2e", "system")
        },
        "review": {
            "independentSecurity": True, "independentFunctional": True,
            "p0": 0, "p1": 0, "p2": 0, "evidenceRef": "private/review.md",
        },
        "attestation": {
            "witness": "consenting operator", "physicalDevicesWitnessed": True,
            "noSyntheticCounted": True, "evidenceRef": "private/hardware.txt",
        },
    }


class P4FManifestTests(unittest.TestCase):
    def test_structurally_complete_manifest(self):
        self.assertEqual([], review_manifest(valid_manifest()))

    def test_five_synthetic_cameras_cannot_satisfy_gate(self):
        case = valid_manifest()
        case["cameras"][0]["source"] = "SIMULATED"
        self.assertTrue(any("PHYSICAL" in p for p in review_manifest(case)))

    def test_four_cameras_not_enough(self):
        case = valid_manifest()
        case["cameras"].pop()
        self.assertIn("at least five physical camera records required", review_manifest(case))

    def test_distinct_tracks_do_not_prove_distinct_devices(self):
        case = valid_manifest()
        case["cameras"][1]["deviceIdSha256"] = case["cameras"][0]["deviceIdSha256"]
        self.assertTrue(any("deviceIdSha256" in p for p in review_manifest(case)))

    def test_nonoverlapping_cameras_rejected(self):
        case = valid_manifest()
        case["cameras"][1]["disconnectedAt"] = "2026-11-17T10:02:00+07:00"
        self.assertTrue(any("simultaneously active" in p for p in review_manifest(case)))

    def test_naive_timestamps_rejected(self):
        case = valid_manifest()
        case["teacherGrid"]["observedAt"] = "2026-11-17T10:05:00"
        self.assertTrue(any("timezone" in p for p in review_manifest(case)))

    def test_mock_ai_not_real_ai(self):
        case = valid_manifest()
        case["ai"]["phone"]["modelIsReal"] = False
        self.assertTrue(any("ai.phone.modelIsReal" in p for p in review_manifest(case)))

    def test_egress_and_rolling_buffer_both_required(self):
        case = valid_manifest()
        del case["recording"]["off"]["clipRef"]
        self.assertTrue(any("recording.off.clipRef" in p for p in review_manifest(case)))

    def test_missing_failure_injection_rejected(self):
        case = valid_manifest()
        case["faults"] = [x for x in case["faults"] if x["kind"] != "MINIO_UNAVAILABLE"]
        self.assertIn("missing fault injection: MINIO_UNAVAILABLE", review_manifest(case))

    def test_open_security_finding_rejected(self):
        case = valid_manifest()
        case["review"]["p1"] = 1
        self.assertIn("review.p1 must be 0", review_manifest(case))

    def test_false_answer_integrity_rejected(self):
        case = valid_manifest()
        case["faults"][0]["answersPreserved"] = False
        self.assertTrue(any("answersPreserved" in p for p in review_manifest(case)))

    def test_unreviewed_manifest_cannot_pass(self):
        case = valid_manifest()
        case["attestation"]["physicalDevicesWitnessed"] = False
        self.assertTrue(any("physicalDevicesWitnessed" in p for p in review_manifest(case)))


    def test_boolean_does_not_count_as_zero_failed_tests(self):
        case = valid_manifest()
        case["tests"]["frontend"]["failed"] = False
        self.assertTrue(any("tests.frontend.failed" in p for p in review_manifest(case)))

    def test_boolean_does_not_count_as_zero_open_issues(self):
        case = valid_manifest()
        case["review"]["p1"] = False
        self.assertTrue(any("review.p1" in p for p in review_manifest(case)))

    def test_boolean_schema_version_rejected(self):
        case = valid_manifest()
        case["schemaVersion"] = True
        self.assertTrue(any("schemaVersion" in p for p in review_manifest(case)))




class P4FIDORContractTests(unittest.TestCase):
    def test_actual_owner_and_unrelated_teacher_denied(self):
        self.assertTrue(assess_idor(200, 403, 401))
        self.assertTrue(assess_idor(200, 404, 403))

    def test_unknown_endpoint_not_false_positive(self):
        self.assertFalse(assess_idor(404, 404, 404))

    def test_foreign_user_with_access_fails(self):
        self.assertFalse(assess_idor(200, 200, 401))

    def test_anonymous_getting_access_fails(self):
        self.assertFalse(assess_idor(200, 403, 200))




if __name__ == "__main__":
    unittest.main()
