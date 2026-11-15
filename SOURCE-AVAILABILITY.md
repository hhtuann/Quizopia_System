# Quizopia System — Source Availability & AGPL-3.0

SPDX-License-Identifier: AGPL-3.0-only

The Quizopia System repository (submodule pointers, infrastructure, architecture documentation and orchestration) is available under the **GNU Affero General Public License v3.0**. See the full [LICENSE](LICENSE).

Corresponding source for the complete Quizopia application is organized as three separately versioned, AGPL-3.0 repositories:

1. https://github.com/hhtuann/Quizopia_System — orchestration/docs and exact backend/frontend submodule pointers.
2. https://github.com/hhtuann/Quizopia_Backend — Java / Spring Boot backend.
3. https://github.com/hhtuann/Quizopia_Frontend — Next.js/browser AI integration and owner fine-tuned YOLO26s ONNX artifact.

Use exact Git commit SHAs in submodule pointers/release tags to locate the deployed version's corresponding source. Frontend source offer: [here](https://github.com/hhtuann/Quizopia_Frontend/blob/main/SOURCE-AVAILABILITY.md).

The owner fine-tuned `yolo26s.onnx` from publicly available Ultralytics `yolo26s.pt` pretrained weights, under AGPL-3.0. See `docs/phase4/LICENSE_COMPLIANCE.md`, model card and third-party notices for provenance, license and pending training-recipe inventory. No private data, student media, credentials or personal information are offered by this document.

This commit does not deploy anything and does not approve AI Worker repository creation.
