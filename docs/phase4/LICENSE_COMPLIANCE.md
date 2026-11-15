# P4-C License Compliance Review — Ultralytics YOLO26s (AGPL-3.0)

Status: **reviewed 2026-11-15; blocking decision(s) for the Product Owner.**
Scope: `frontend/public/models/yolo26s.onnx` (19,215,911 bytes, SHA-256
`a1364960967674c8e0301222be72db49b26d01e9ad9bb08ad91f5a19e1364`) — committed to
the public `Quizopia_Frontend` repository (PR #27).

## 1. Facts established

| Item | Finding | Confidence |
|---|---|---|
| Model identity | Ultralytics YOLO26s, trained by Ultralytics on COCO (`metadata.names` = COCO 80; producer `pytorch 2.12.0`, ultralytics 8.4.64, date 2026-06-11) | Certain (graph metadata) |
| Ultralytics' licensing position | **Weights trained with their code are derivative works of AGPL-3.0 software; ONNX exports inherit it.** Stated publicly by Ultralytics maintainers (ultralytics/ultralytics issue #22458, #21936) and their license pages | Certain (their stated position) |
| Runtime dependency | `onnxruntime-web` 1.31.1 — **MIT licensed** (no copyleft) | Certain |
| Quizopia repos | **No LICENSE file in any of the three repositories**; `backend/pom.xml` has an empty `<license/>`; `frontend/package.json` has no license field | Certain |
| Distribution facts | The `.onnx` file is (a) committed to a public repo, (b) served by the app to every student browser at `/models/yolo26s.onnx` | Certain |

## 2. What AGPL-3.0 requires here (per Ultralytics' interpretation)

1. **Distribution (AGPL §9–§10)**: conveying the model requires providing the
   license text and the "Corresponding Source". For weights, Ultralytics treats
   the weights file itself as the object; the training code is theirs
   (already public, AGPL). Practically: ship the AGPL-3.0 text + attribution
   + a written offer/link to the upstream source.
2. **Network clause (§13)**: users interacting with the work over a network
   must be offered its complete corresponding source. In our architecture the
   model executes **in the user's own browser** — the user already receives
   the artifact itself; the remaining obligation is the license text +
   upstream source link.
3. **Combined work (Ultralytics' Enterprise trigger)**: Ultralytics asserts
   that an application embedding their weights is a combined/derivative work,
   making the **host application's source code disclosable under AGPL** unless
   an Enterprise license is bought. **This is their commercial position; the
   FSF-style "mere aggregation" argument (the app merely loads a data file)
   is a defensible but contested reading.** Whether Quizopia's own code must
   be AGPL-licensed is a legal judgment this review cannot settle.

## 3. Explicitly NOT claimed

- **Academic/non-commercial use is NOT an AGPL exemption.** Nothing in this
  project relies on that.
- This review does not relicense the project, remove the model, or purchase
  anything — those are owner decisions.

## 4. Verified mitigations already in place (technical, done)

- `frontend/public/models/MODELCARD.md` states the AGPL-3.0 license + upstream
  link (committed in PR #27).
- `frontend/LICENSE-THIRD-PARTY.md` (this round) adds the full attribution
  block + AGPL-3.0 reference text pointer + onnxruntime-web (MIT) notice.
- `docs/phase4/AI_MODEL_AUDIT.md` §7.1 records the license prominently.
- No Ultralytics **code** is vendored — only the weights artifact. The
  preprocessing/postprocessing (letterbox, CHW, [1,300,6] parse) was written
  from the graph audit, not copied from their repo.

## 5. Product Owner Decisions required

| # | Decision | Options | Default if undecided |
|---|---|---|---|
| D1 | Accept AGPL-3.0 terms for the model artifact as shipped | (a) comply: add AGPL text + source offer, keep model public; (b) buy Ultralytics Enterprise; (c) move model out of the public repo to owner-controlled storage (AGPL still arguably applies to serving); (d) replace with a permissively-licensed detector (e.g. YOLOX, Apache-2.0) in a later phase | keep draft PR unmerged — **merge blocker** |
| D2 | Repo licensing posture | add an explicit project LICENSE to all three repos (e.g. copyright-header + chosen license); today the repos declare NOTHING, which is itself a defect for a public repo | recommend: pick a license explicitly |
| D3 | AGPL app-source disclosure stance | if D1=(a): decide whether Quizopia source is offered under AGPL (Ultralytics' reading) or the app claims aggregation (contested reading) — legal counsel call | document the chosen stance |

## 6. Conclusion

Technical compliance hygiene is in place (attribution, notices, docs). The
**unresolved items are legal decisions only the Product Owner can make**
(D1–D3). Until D1 is decided, PR #27 (frontend, which ships the model) should
stay **draft/unmerged**. Backend PR #26 and System PR #103 do not distribute
the artifact and are not license-blocked.
