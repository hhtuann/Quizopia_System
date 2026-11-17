#!/usr/bin/env python3
"""P4-F academic-demo evidence manifest gate.

This is a *declaration/evidence-index* validator, not proof that real
webcams, recordings, or security controls worked. A human reviewer MUST
inspect the referenced private artifacts before closing Phase 4.

No third-party packages, network calls, cameras, or secrets required.
Usage: python3 scripts/p4f_gate.py /private/path/p4f-evidence.json
Exit 0: structurally complete/consistent declaration (pending independent audit)
Exit 2: unmet or missing acceptance fields
Exit 1: invalid input (JSON/schema/IO)
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import re
import sys
from pathlib import Path
from typing import Any

SHA40 = re.compile(r"^[a-fA-F0-9]{40}$")
SHA256 = re.compile(r"^[a-fA-F0-9]{64}$")
REQUIRED_FAULTS = {
    "CAMERA_LOSS", "LIVEKIT_RESTART", "AI_UNAVAILABLE",
    "EGRESS_FAILURE", "MINIO_UNAVAILABLE", "STOMP_RESTART",
}
REQUIRED_NEGATIVES = {
    "crossUserMediaDenied", "crossClassTimelineDenied",
    "evidenceUrlOwnerOnly", "expiredTokenDenied",
    "revokedTokenResidualDocumented", "unsignedWebhookDenied",
    "callbackReplayIdempotent", "privateBucketVerified",
}


def get(obj: Any, *path: str) -> Any:
    for key in path:
        if not isinstance(obj, dict):
            return None
        obj = obj.get(key)
    return obj


def iso(value: Any) -> datetime | None:
    if not isinstance(value, str):
        return None
    try:
        result = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return result.astimezone(timezone.utc) if result.tzinfo else None
    except (ValueError, OverflowError):
        return None


def populated(value: Any) -> bool:
    return isinstance(value, str) and len(value.strip()) >= 3


def positive_number(value: Any) -> bool:
    return type(value) in (float, int) and 0 < value < 1_000_000_000


def review_manifest(data: Any) -> list[str]:
    problems: list[str] = []
    def check(ok: bool, message: str) -> None:
        if not ok:
            problems.append(message)

    if not isinstance(data, dict):
        return ["root must be an object"]
    check(data.get("schemaVersion") == 1, "schemaVersion must be 1")
    check(data.get("scope") == "ACADEMIC_DEMO", "scope must be ACADEMIC_DEMO")
    check(populated(data.get("runId")), "runId is required")

    for repo in ("system", "backend", "frontend"):
        check(bool(SHA40.fullmatch(str(get(data, "refs", repo) or ""))),
              f"refs.{repo} must be an exact 40-hex commit")
    for field in ("os", "browser", "livekitVersion", "egressVersion", "storage"):
        check(populated(get(data, "environment", field)),
              f"environment.{field} is required")

    for field in ("adultsOnly", "noticeShown", "noDefaultAudio",
                  "noAutomaticVerdicts", "footageRightsConfirmed"):
        check(get(data, "consent", field) is True, f"consent.{field} must be true")

    cameras = data.get("cameras")
    check(isinstance(cameras, list) and len(cameras) >= 5,
          "at least five physical camera records required")
    if isinstance(cameras, list):
        names, devices, tracks = set(), set(), set()
        grid_time = iso(get(data, "teacherGrid", "observedAt"))
        check(grid_time is not None, "teacherGrid.observedAt must be ISO timestamp with timezone")
        check(populated(get(data, "teacherGrid", "evidenceRef")),
              "teacherGrid.evidenceRef is required")
        for n, camera in enumerate(cameras):
            key = f"cameras[{n}]"
            check(isinstance(camera, dict), f"{key} must be an object")
            if not isinstance(camera, dict):
                continue
            check(camera.get("source") == "PHYSICAL", f"{key}.source must be PHYSICAL (synthetic never counts)")
            check(camera.get("teacherSubscribed") is True, f"{key}.teacherSubscribed must be true")
            check(positive_number(camera.get("decodedFrames")), f"{key}.decodedFrames must be > 0")
            check(positive_number(camera.get("measuredFps")), f"{key}.measuredFps must be > 0")
            check(populated(camera.get("evidenceRef")), f"{key}.evidenceRef is required")
            participant = camera.get("publisherId")
            check(populated(participant) and participant not in names, f"{key}.publisherId must be unique")
            names.add(participant)
            device = camera.get("deviceIdSha256")
            check(isinstance(device, str) and bool(SHA256.fullmatch(device)) and device not in devices,
                  f"{key}.deviceIdSha256 must be unique 64-hex pseudonym (not raw device id)")
            devices.add(device)
            track = camera.get("trackSid")
            check(populated(track) and track not in tracks, f"{key}.trackSid must be unique")
            tracks.add(track)
            start, end = iso(camera.get("connectedAt")), iso(camera.get("disconnectedAt"))
            check(start is not None and end is not None and start < end,
                  f"{key} requires connectedAt < disconnectedAt with timezone")
            if start and end and grid_time:
                check(start <= grid_time <= end,
                      f"{key} was not simultaneously active at teacherGrid.observedAt")

    for event in ("phone", "multiplePeople"):
        prefix = f"ai.{event}"
        record = get(data, "ai", event)
        check(isinstance(record, dict), f"{prefix} required")
        check(get(data, "ai", event, "modelIsReal") is True,
              f"{prefix}.modelIsReal must be true (not mocked)")
        check(get(data, "ai", event, "source") == "PHYSICAL",
              f"{prefix}.source must be PHYSICAL for the real demo")
        for field in ("modelId", "alertId", "snapshotRef", "clipRef", "evidenceRef"):
            check(populated(get(data, "ai", event, field)), f"{prefix}.{field} is required")
        check(positive_number(get(data, "ai", event, "inferenceP95Ms")),
              f"{prefix}.inferenceP95Ms must be measured > 0")
    for field in ("videoFileRef", "playbackEvidenceRef"):
        check(populated(get(data, "recording", "on", field)), f"recording.on.{field} is required")
    for field in ("videoOnly", "seekVerified"):
        check(get(data, "recording", "on", field) is True, f"recording.on.{field} must be true")
    for field in ("clipRef", "playbackEvidenceRef"):
        check(populated(get(data, "recording", "off", field)), f"recording.off.{field} is required")
    for field in ("bufferWasEnabled", "noFullRecording"):
        check(get(data, "recording", "off", field) is True, f"recording.off.{field} must be true")

    faults = data.get("faults")
    check(isinstance(faults, list), "faults must be an array")
    seen_faults: set[str] = set()
    if isinstance(faults, list):
        for index, fault in enumerate(faults):
            if not isinstance(fault, dict):
                problems.append(f"faults[{index}] must be object")
                continue
            kind = fault.get("kind")
            seen_faults.add(kind) if isinstance(kind, str) else None
            for field in ("answersPreserved", "gradeUnaffected", "honestDegradedState"):
                check(fault.get(field) is True, f"faults[{index}].{field} must be true")
            check(populated(fault.get("evidenceRef")), f"faults[{index}].evidenceRef is required")
    for required in sorted(REQUIRED_FAULTS - seen_faults):
        problems.append(f"missing fault injection: {required}")

    for field in sorted(REQUIRED_NEGATIVES):
        check(get(data, "security", field) is True, f"security.{field} must be true")
    check(populated(get(data, "security", "evidenceRef")),
          "security.evidenceRef is required")
    for field in ("media30Days", "activity90Days", "manualDemoPurge"):
        check(get(data, "retention", field) is True, f"retention.{field} must be true")
    check(populated(get(data, "retention", "evidenceRef")), "retention.evidenceRef is required")

    for suite in ("backend", "frontend", "browserE2e", "system"):
        check(populated(get(data, "tests", suite, "evidenceRef")),
              f"tests.{suite}.evidenceRef is required")
        check(type(get(data, "tests", suite, "passed")) is int
              and get(data, "tests", suite, "passed") > 0,
              f"tests.{suite}.passed must be > 0")
        check(get(data, "tests", suite, "failed") == 0,
              f"tests.{suite}.failed must be 0")
    check(get(data, "review", "independentSecurity") is True,
          "review.independentSecurity must be true")
    check(get(data, "review", "independentFunctional") is True,
          "review.independentFunctional must be true")
    for severity in ("p0", "p1", "p2"):
        check(get(data, "review", severity) == 0, f"review.{severity} must be 0")
    check(populated(get(data, "review", "evidenceRef")), "review.evidenceRef is required")
    for field in ("physicalDevicesWitnessed", "noSyntheticCounted"):
        check(get(data, "attestation", field) is True,
              f"attestation.{field} must be true")
    check(populated(get(data, "attestation", "witness")),
          "attestation.witness is required")
    check(populated(get(data, "attestation", "evidenceRef")),
          "attestation.evidenceRef is required")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="private P4-F evidence manifest JSON")
    parser.add_argument("--json", action="store_true", help="machine-readable result")
    args = parser.parse_args()
    try:
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        print(f"INVALID MANIFEST: {exc}", file=sys.stderr)
        return 1
    failures = review_manifest(manifest)
    result = {
        "schemaComplete": not failures,
        "requiresIndependentArtifactVerification": True,
        "phase4AutomaticallyClosed": False,
        "failureCount": len(failures),
        "failures": failures,
    }
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("STRUCTURAL PASS (HUMAN AUDIT REQUIRED)" if not failures
              else f"NO-GO: {len(failures)} evidence/schema findings")
        for failure in failures:
            print(f"- {failure}")
        print("Never equate a manifest checkbox with verified real hardware, media or security.")
    return 2 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
