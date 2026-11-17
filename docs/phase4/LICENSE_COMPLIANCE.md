# P4-C License Compliance Review — Ultralytics YOLO26s (AGPL-3.0)

Status: **Product Owner decisions D1–D3 accepted 2026-11-15; implementation submitted in P4-C Draft PRs. Verify final CI before any merge.**
Scope: `frontend/public/models/yolo26s.onnx` (19,215,911 bytes, SHA-256
`a1364960967674c8e0301222be72db49b26d01e9ad9bb08ad91f5a19e1364`) — committed to
the public `Quizopia_Frontend` repository (PR #27).

## 1. Facts established

| Item | Finding | Confidence |
|---|---|---|
| Model identity | Ultralytics YOLO26s, **fine-tuned by the Quizopia Product Owner from publicly released pretrained `yolo26s.pt`** (owner-confirmed); ONNX graph advertises COCO 80 names (`metadata.names`; producer `pytorch 2.12.0`, ultralytics 8.4.64, date 2026-06-11) | Certain (graph metadata) |
| Ultralytics' licensing position | **Weights trained with their code are derivative works of AGPL-3.0 software; ONNX exports inherit it.** Stated publicly by Ultralytics maintainers (ultralytics/ultralytics issue #22458, #21936) and their license pages | Certain (their stated position) |
| Runtime dependency | `onnxruntime-web` 1.31.1 — **MIT licensed** (no copyleft) | Certain |
| Quizopia repos | **AGPL-3.0 full-text LICENSE added in all three P4-C PR branches** (not merged yet). Backend Maven license and Frontend package license fields updated. GitHub public repo visibility alone does not grant a license. | Certain |
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
- The Product Owner subsequently **authorized AGPL-3.0 licensing of all three repositories** and retaining the fine-tuned model. No Ultralytics Enterprise purchase. This review does not assert every associated training artifact has been publicly distributed.

## 4. Verified mitigations already in place (technical, done)

- `frontend/public/models/MODELCARD.md` states the AGPL-3.0 license + upstream
  link (committed in PR #27).
- `frontend/LICENSE-THIRD-PARTY.md` (this round) adds the full attribution
  block + AGPL-3.0 reference text pointer + onnxruntime-web (MIT) notice.
- `docs/phase4/AI_MODEL_AUDIT.md` §7.1 records the license prominently.
- No Ultralytics **code** is vendored — only the weights artifact. The
  preprocessing/postprocessing (letterbox, CHW, [1,300,6] parse) was written
  from the graph audit, not copied from their repo.

## 5. Product Owner Decisions — APPROVED (2026-11-15)

| # | Decision | Options | Default if undecided |
|---|---|---|---|
| D1 | **APPROVED:** retain owner fine-tuned `yolo26s.onnx`, comply with AGPL-3.0, no Enterprise purchase | Root LICENSE/third-party notices/source offer | Verify resulting PR CI |
| D2 | **APPROVED:** license all three Quizopia repositories AGPL-3.0 | Full-text LICENSE added to Backend, Frontend and System PR branches; Maven/npm metadata updated where relevant | Verify licenses exist on `main` only after merge |
| D3 | **APPROVED:** make Quizopia's complete corresponding application source available under AGPL-3.0; do not rely on a contested mere-aggregation exemption | SOURCE-AVAILABILITY.md in each repo, visible frontend source link | Owner to inventory fine-tuning recipe/config and verify third-party/dataset distribution rights |

## 6. Conclusion

The Product Owner **has accepted AGPL-3.0 for the model and all three application repositories**. License and source-offer changes are now in the **Draft PR branches**, pending CI and merge approval. The user confirms **self fine-tuning from public Ultralytics `yolo26s.pt` pretrained weights**; the original model card's incomplete provenance is amended accordingly. Public training scripts/config/augmentation and data release rights **were not supplied here** and must be inventoried before claiming reproducible training or full corresponding-source completeness. Do not publish private datasets, credentials or student footage. No merge/deploy is authorized by this documentation change.


## 7. Source and license artifact locations (P4-C branch)

- [System LICENSE](../../LICENSE), [System source offer](../../SOURCE-AVAILABILITY.md)
- [Backend LICENSE](https://github.com/hhtuann/Quizopia_Backend/blob/feature/p4-c-ai-proctoring/LICENSE), [Backend source offer](https://github.com/hhtuann/Quizopia_Backend/blob/feature/p4-c-ai-proctoring/SOURCE-AVAILABILITY.md)
- [Frontend LICENSE](https://github.com/hhtuann/Quizopia_Frontend/blob/feature/p4-c-ai-proctoring/LICENSE), [Frontend source offer](https://github.com/hhtuann/Quizopia_Frontend/blob/feature/p4-c-ai-proctoring/SOURCE-AVAILABILITY.md) and [third-party notices](https://github.com/hhtuann/Quizopia_Frontend/blob/feature/p4-c-ai-proctoring/LICENSE-THIRD-PARTY.md)

Track P4-F source inventory separately. Do not conflate copyright/license permissions with permissions to publish a private or third-party dataset.

## 8. Gaze models (`feature/p4-c-gaze-tracking`) — provenance verified 2026-11-17

Two more model files ship in `frontend/public/models/` with the gaze
feature. Provenance was verified by **byte-identical SHA-256** against the
public upstream release assets (not by file name):

| File (SHA-256) | Upstream (verified) | Code / weight license | Training data terms |
|---|---|---|---|
| `yolov11n-face.onnx` (`61d8cf12…10ee67b5`) | akanametov/yolo-face release `1.0.0`, asset `yolov11n-face.onnx` — downloaded copy hash-identical | Repo **GPL-3.0**; ONNX metadata: Ultralytics **AGPL-3.0** (YOLO11n, ultralytics 8.3.20). GPL-3.0 §13 allows combination with AGPL-3.0; Quizopia is AGPL-3.0 | WIDER FACE — non-commercial research (dataset card CC BY-NC-ND 4.0) |
| `mobileone_s0_gaze.onnx` (`8b4fdc4e…a55f7d9f`) | yakhyo/gaze-estimation ("MobileGaze") release `weights`, asset `mobileone_s0_gaze.onnx` — GitHub-published digest identical; DOI 10.5281/zenodo.14257640 | **MIT**, (c) 2024 Yakhyokhuja Valikhujaev | Gaze360 (MIT CSAIL) — non-commercial research only (CC BY-NC-SA per the paper record) |

**Disposition.**

- *Redistribution in the public AGPL-3.0 repositories (academic, non-commercial):*
  permitted by the code/weight licenses above, with the notices recorded in
  `frontend/LICENSE-THIRD-PARTY.md` §3 and `frontend/public/models/MODELCARD.md`.
- *Commercial use / production deployment:* **owner decision required.** Both
  training datasets are non-commercial research datasets; whether dataset
  terms bind trained weights is unsettled. Until the owner signs off (or the
  weights are replaced by commercially-cleared ones), treat the gaze feature as
  **experimental / academic demo only**.
- *Kill switch:* building the frontend with `NEXT_PUBLIC_AI_GAZE=off` ships the
  attempt page without gaze analysis; yolo26s object detection is unaffected,
  and the two files can then be removed from a release artifact.
- The gaze signal is an **observation for teacher review only** — never a
  verdict, never a score input (ADR-008, CONTRACT §8).
