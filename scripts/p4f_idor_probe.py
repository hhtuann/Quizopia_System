#!/usr/bin/env python3
"""P4-F1 live IDOR probe against an isolated, actual Backend/DB.

Uses an OWNing teacher token, an UNRELATED teacher token and anonymous
requests. Owner must receive 200 on each existing route; unrelated user
must receive 403/404; anonymous must receive 401/403. No response bodies,
raw JWTs, signed URLs or PII are printed or persisted. An unknown route
returning 404 for everyone is NOT a PASS.

Env: P4F_API_URL, P4F_OWNER_JWT, P4F_FOREIGN_JWT,
     P4F_SESSION_ID, P4F_ATTEMPT_ID.
Run in isolated dev with consented data only.
DOES NOT test media tokens, LiveKit SFU, webhook signatures,
real MinIO object ACLs, Python Worker or camera hardware.
"""
from __future__ import annotations

import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

ROUTES = (
    "/api/exam-sessions/{session}/monitoring/overview",
    "/api/exam-sessions/{session}/monitoring/participants",
    "/api/exam-sessions/{session}/ai-alerts",
    "/api/exam-sessions/{session}/evidence",
    "/api/exam-sessions/{session}/recordings",
    "/api/attempts/{attempt}/monitoring/report",
    "/api/attempts/{attempt}/monitoring/reviews",
)


def assess(owner: int, foreign: int, anonymous: int) -> bool:
    """Fail closed on unknown routes: owner must get 200."""
    return owner == 200 and foreign in (403, 404) and anonymous in (401, 403)


def _jwt_subject(token: str) -> str | None:
    # Local safety comparison only, NOT a signature verification or auth
    # operation (the Backend verifies the signature on each actual request).
    try:
        encoded = token.split(".")[1]
        payload = json.loads(base64.urlsafe_b64decode(encoded + "=" * (-len(encoded) % 4)))
        sub = payload.get("sub")
        return str(sub) if sub is not None else None
    except (IndexError, ValueError, TypeError, KeyError):
        return None


def _status(url: str, token: str | None) -> int:
    headers = {"Accept": "application/json"}
    if token is not None:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=12) as response:
            response.read(0)
            return response.status
    except urllib.error.HTTPError as exc:
        # Do NOT read/print exception body: it may contain sensitive data.
        return exc.code


def main() -> int:
    names = ("P4F_API_URL", "P4F_OWNER_JWT", "P4F_FOREIGN_JWT",
             "P4F_SESSION_ID", "P4F_ATTEMPT_ID")
    missing = [name for name in names if not os.environ.get(name)]
    if missing:
        print("MISSING environment fields: " + ", ".join(missing), file=sys.stderr)
        return 2

    base = os.environ["P4F_API_URL"].rstrip("/")
    parsed = urllib.parse.urlsplit(base)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        print("INVALID P4F_API_URL (must be HTTP(S))", file=sys.stderr)
        return 2
    if parsed.scheme == "http" and parsed.hostname not in ("localhost", "127.0.0.1", "::1"):
        print("REFUSING to send JWT over nonlocal HTTP; use HTTPS", file=sys.stderr)
        return 2
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        print("REFUSING API base URL containing credentials/query/fragment", file=sys.stderr)
        return 2

    owner = os.environ["P4F_OWNER_JWT"]
    foreign = os.environ["P4F_FOREIGN_JWT"]
    a, b = _jwt_subject(owner), _jwt_subject(foreign)
    if not a or not b or a == b or owner == foreign:
        print("Owner and foreign tokens must identify DIFFERENT JWT subjects", file=sys.stderr)
        return 2

    session, attempt = os.environ["P4F_SESSION_ID"], os.environ["P4F_ATTEMPT_ID"]
    if not session.isdecimal() or not attempt.isdecimal():
        print("Session and Attempt IDs must be decimal numeric", file=sys.stderr)
        return 2

    fail = 0
    for route in ROUTES:
        url = base + route.format(session=session, attempt=attempt)
        try:
            statuses = (_status(url, owner), _status(url, foreign), _status(url, None))
        except (OSError, ValueError, urllib.error.URLError) as exc:
            print(route + " NETWORK ERROR: " + type(exc).__name__)
            fail += 1
            continue
        passed = assess(*statuses)
        print(("{PASS} " if passed else "{FAIL} ") + route +
              " owner/foreign/anonymous=" + "/".join(map(str, statuses)))
        if not passed:
            fail += 1
    print("HTTP IDOR probe: " + ("PASS" if fail == 0 else f"NO-GO ({fail} failed route(s))"))
    print("Scope only HTTP authorization; human reviewer must still inspect media tokens, signed URLs, private S3, callback and actual devices.")
    return 0 if fail == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
