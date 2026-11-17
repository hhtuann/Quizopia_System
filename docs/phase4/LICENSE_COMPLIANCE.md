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

## 8. Gaze models (branch `kido`, 2026-11-16) — open items, NOT yet reviewed

Two more model files are added to `frontend/public/models/` on branch `kido`
(not pushed, not merged):

| File | What the artifact itself says | Open |
|---|---|---|
| `yolov11n-face.onnx` | ONNX metadata: Ultralytics 8.3.20, `license = AGPL-3.0`, trained on `widerface.yaml` | Same AGPL-3.0 posture as §1–§6 applies. Unknown: who trained/published this checkpoint; WIDER FACE dataset terms |
| `mobileone_s0_gaze.onnx` | No metadata at all | **Upstream repository and license unknown from the file.** The owner demo says it was trained on Gaze360 — check that dataset's usage terms (research/non-commercial restrictions are common for gaze datasets) |

Until the owner records the source and license of the gaze model, treat its
redistribution in a public repository as **undecided**. Notices are drafted
in `frontend/LICENSE-THIRD-PARTY.md` §3.
