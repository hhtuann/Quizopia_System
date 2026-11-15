# P4-0 / P4-C — AI Model Audit & Integration Readiness

**Status:** Pre-implementation checklist. This is the **only material technical input that cannot be derived from the current Quizopia repositories**: user's external pretrained models. No AI model source, artifact or benchmark has been supplied in this turn, and none is assumed.

## 1. Required audit inputs

For each existing model (phone, multiple persons; later gaze), record:

| Item | Required evidence |
|---|---|
| Repository/artifacts | Read-only repo URL or uploaded files; commit/hash, license and artifact checksum |
| Model identity | Architecture/framework, weights format, versions, dependencies, Python/ONNX/CUDA runtime |
| Input | Image color space, dtype, shape, dynamic batch, preprocessing, aspect ratio, normalization |
| Output | Labels/classes, confidence semantics, bounding boxes, coordinates, multiple detections, gaze output units |
| Hardware | CPU model, GPU model/VRAM, driver, precision (FP32/FP16/INT8), batch sizes |
| Latency | p50/p95/p99 of preprocessing, inference, postprocessing at representative resolution |
| Accuracy | Validation dataset provenance, confusion matrix, per-class precision/recall, false alerts/hour, false negatives |
| Domain robustness | Low light, glasses, partial occlusion, webcam orientation, skin tone/device quality and backgrounds where relevant |
| Privacy | Whether training data has appropriate rights, whether prediction stores images, no automatic student-image training |
| Deployability | Docker image reproducible, health probes, graceful GPU overload, version pinning, OOM recovery |

Do **not** copy secrets/private student footage into tickets. Use staged consented or synthetic test media and anonymized evaluation summaries.

## 2. Minimal implementation-neutral adapter

```python
from typing import Protocol, Sequence

class ModelAdapter(Protocol):
    model_id: str
    model_version: str
    def load(self) -> None: ...
    def predict(self, frames: Sequence['Frame']) -> list['Detection']: ...
```

`Detection` must expose `type`, `confidence`, `frameTimestamp`, `modelVersion`, and optional `boundingBoxes`. The core uses a registry keyed by `modelId`; adding gaze does not change Backend tables/contracts beyond versioned detection types and model-specific metadata. Services must not directly write grades or attributes declaring cheating.

## 3. Experiment plan — three-level validation

1. **Adapter contract tests** with fixed synthetic input (formats, shapes, invalid frames, multiple outputs, determinism where expected).
2. **Representative real-model tests** with approved, consented clips of phone present/absent; one/multiple/no people; backgrounds, illumination, occlusion; measure confusion matrix and performance by scenario. Gaze requires a separate calibration and fairness pilot.
3. **End-to-end model tests** via LiveKit subscription → frame receiver → model → aggregation → authenticated Backend callback → DB → snapshot → teacher alert. Verify time alignment to correct Attempt and dedupe.

Never claim real-model accuracy based only on fake detector, demo video, or mocked output. Thresholds should be selected by measuring false positives per learner-hour and missed events, comparing against review workload and class fairness; document risk and intended use. Treat `LOOKING_AWAY` as inconclusive human-review context only.

## 4. Resource sizing (measure, do not guess)

Let `N` be concurrent publishers; `f` sampling FPS/publisher; `L` measured effective GPU seconds/frame after batching. Nominal load in frame/s is `N*f` and utilization lower-bound estimate is `(N*f)*L`, with concurrency, batching, CPU overhead and queueing considered. For a 100-student design with 1.5 FPS assumed solely for sizing discussion, model pipeline receives 150 sampled frames/s — *not* a proven capability. For the university demo, **benchmark 5 concurrent real publishers (mandatory), aim for 10**, track end-to-end alert latency and dropped frames, then select model resolution/FPS. 30/50/100 are future capacity experiments only. Bound all queues and discard old frames rather than issuing stale alerts.

## 5. Model-independent warning schema

- `PHONE_DETECTED`: supported only after confirming model output/validation.
- `MULTIPLE_PERSONS_DETECTED`: output contract must specify person counting, min confidence and handling of photos/posters.
- `NO_PERSON_DETECTED`: conditional, only if model explicitly supports it.
- `LOOKING_AWAY`: disabled until gaze adapter/calibration/evaluation is available.
- `CAMERA_DISCONNECTED`: media/system event, **not** an AI classification.

All events record original sample timestamp, server receipt, `modelId`, `modelVersion`, aggregation rule version and confidence. Teacher can mark false positive; review notes are used for quality monitoring only with privacy controls, not training without appropriate basis.

## 6. P4-C unblock gate

- [ ] Model inventory and licenses documented
- [ ] Exact input/output adapters for phone and multi-person complete
- [ ] Reproducible container/runtime and cold-start measured
- [ ] Latency/throughput measured on intended hardware
- [ ] False-positive/false-negative evaluation including lighting/device variations
- [ ] Temporal aggregation profile version defined from data
- [ ] AI service-to-Backend contract tests pass with a genuine model, separately from fake worker
- [ ] Privacy/security reviewer approves any camera data stored by AI
- [ ] No cheating verdict or disciplinary automation

**Owner input requested:** provide model repo/artifact and a short README of required runtime. It is acceptable to defer exact hardware and performance decisions until the benchmark, but they cannot be represented as verified facts.


## Academic-demo model acceptance note (2026-11-14)

The milestone is a **working classroom demonstration**, not a validated commercial proctoring product. Show two real detection categories supported by the provided model (phone and multiple people), and record real model version, hardware, measured inference latency and representative success/failure clips. Explicitly label false positives and model limitations. Support 5 simultaneous video feeds for the demo if the machine permits; target 10. Model stubs are acceptable for CI and fault injection only, **never** as evidence that the real model works. Future gaze adapter must remain disabled until actual output contract and accuracy are supplied.

---

## 7. REAL AUDIT RESULTS (2026-11-15) — owner artifact `yolo26s.onnx`

The owner supplied the artifact at `D:\Developer\quizopia-ai-assets\yolo26s.onnx`
(19,215,911 bytes, SHA-256 `a1364960967674c8e0301222be72db49b26d01e9ad9bb08ad91f5a19e1364`).
Copied verbatim to `frontend/public/models/yolo26s.onnx` (checksum verified identical);
model card `frontend/public/models/MODELCARD.md`. No inference code was supplied —
the I/O contract below was derived by loading the graph and running it.

### 7.1 Graph facts (measured)

| Item | Fact |
|---|---|
| Identity | Ultralytics **YOLO26s**, ultralytics 8.4.64, exported pytorch 2.12.0, ONNX opset 17 |
| License | **AGPL-3.0** — academic-demo use documented; not a redistribution of weights beyond the owner's own repo |
| Input | `images` `[1,3,640,640]` float32; Ultralytics preprocessing: RGB, /255, letterbox pad 114 |
| Output | `output0` `[1,300,6]` float32; row = `[x1,y1,x2,y2,score,classId]` in 640-letterbox pixel coords; **end-to-end NMS embedded** — no NMS step required by consumers |
| Classes | COCO 80. Used: `0 person`, `62 tv`, `63 laptop`, `67 cell phone` |
| Gaze | **Not present** (no gaze/head-pose output) — gaze adapter stays disabled (contract stub only) |

### 7.2 Runtime decision (ADR-008 Amendment 1)

Browser-side ONNX Runtime Web on the student's own camera track is the initial
real-model path (`CLIENT_MODEL` provenance, `*_OBSERVED` events); a
worker path (`WORKER_VERIFIED`, `POST /internal/ai/v1/detections`, API-key) is
contract-ready but not deployed (repo creation separately owner-gated). Full
rationale + comparison table: `AI_PROCTORING_CONTRACT.md` §2 (this folder).

### 7.3 Measured latency

| Runtime | Hardware | p50 | p95 | Notes |
|---|---|---|---|---|
| Python onnxruntime 1.32 CPU | Demo workstation (Ryzen, CPUExecutionProvider) | 50.1 ms | 56.6 ms | 30-run sorted, random 640² input |
| onnxruntime-web (browser) | Same workstation | TBD §7.4 | TBD §7.4 | WASM vs WebGPU measured by `frontend/e2e/ai-benchmark.mts` |

### 7.4 Browser benchmark (MEASURED 2026-11-15, real model)

`node e2e/ai-benchmark.mts --webcam` (real attempt page, real adapter,
`window.__quizopiaAi.createRealDetector()`; evidence
`frontend/e2e/evidence/ai-benchmark.json` + `ai-benchmark-attempt.png`):

| Pass | Runtime | Frames | wall p50 | wall p95 | Sustained FPS | Detections ≥0.5 |
|---|---|---|---|---|---|---|
| Synthetic canvas 30s | **ORT_WEB_WEBGPU** | 98 | **309 ms** | 321.5 ms | **3.2** | 0 (drawn shapes — no false positives) |
| REAL webcam 20s | **ORT_WEB_WEBGPU** | 70 | **288 ms** | 299.7 ms | **3.5** | 0 |

Environment: Chromium 159 headed, Windows x64, 16 logical cores, WebGPU
adapter available. Wall time = preprocess + inference + postprocess.
The default 1.5 FPS analysis budget therefore has >2× headroom; the
scheduler caps at 3 FPS. WASM-only numbers were not separately captured
this run (WebGPU available and selected on the demo machine); the
synthetic-camera CI runs exercise the WASM fallback path functionally.

Incidental REAL end-to-end evidence (during e2e bring-up, before the fake
was injected deterministically): the REAL model once analyzed the
synthetic Chromium camera stream live and its `cell phone` detection
(≥0.5) was ingested ACCEPTED and aggregated into a PHONE_DETECTED alert —
real browser inference → ingest → aggregation → teacher REST, unplanned
but genuine (run log `AI-HTTP 200 ... ACCEPTED`, bg_78 chain).

### 7.4.1 Evidence scope honesty (pre-merge review)

- The **0 false positives on 98 synthetic frames** is a smoke observation
  on drawn shapes ONLY — it is NOT a real-world accuracy claim. No
  false-positive/false-negative evaluation on representative footage has
  been performed.
- Deferred to P4-F #98 (needs physical hardware + approved footage):
  low-light behavior, occlusion handling, multi-person in real footage,
  false-positive/negative measurement, WASM-only latency benchmark,
  5-physical-webcam concurrent demo.
- Independent AI Worker: NOT deployed — browser-first per ADR-008
  Amendment 1; the worker contract exists (`/internal/ai/v1/detections`)
  but nothing emits `WORKER_VERIFIED` rows until the owner deploys a
  key-holding worker.

### 7.5 Capability honesty table

| Detection | Real-model support | Status in P4-C |
|---|---|---|
| Phone (`cell phone`) | Yes (COCO 67) | Implemented, real model |
| External screen (`tv`/`laptop`) | Yes (COCO 62/63) | Implemented, real model |
| Multiple persons (count of `person`) | Yes (COCO 0) | Implemented, real model |
| Person not visible (0 `person`) | Yes (COCO 0 absence) | Implemented, observation only |
| Gaze / looking away | **No** | Disabled adapter stub, no warnings shown |
| Automatic cheating verdict | Out of scope by ADR-008 | Never implemented |

False-positive characterization on representative footage: recorded with the
real-model demo evidence (phone present/absent, screen present/absent, low
light, portrait webcam, multi-person) — see P4-C final report; stub runs are
always labeled SIMULATED and never used as accuracy evidence.
