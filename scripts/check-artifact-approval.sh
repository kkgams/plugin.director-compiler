#!/usr/bin/env bash
# A downloadable GitHub Actions artifact is distribution, even without a tag.
set -euo pipefail
bash scripts/check-licensing-digests.sh
(cd dist && sha256sum --check SHA256SUMS)
python3 scripts/wasm-notices.py verify dist/director-compiler.wasm --license LICENSE --notice NOTICE
cp LICENSE NOTICE dist/
(cd dist && sha256sum director-compiler.wasm LICENSE NOTICE > SHA256SUMS && sha256sum --check SHA256SUMS)
