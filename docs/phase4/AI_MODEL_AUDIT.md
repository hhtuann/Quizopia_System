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
