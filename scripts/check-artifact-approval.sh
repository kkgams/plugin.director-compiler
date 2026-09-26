#!/usr/bin/env bash
# A downloadable GitHub Actions artifact is distribution, even without a tag.
set -euo pipefail
[[ "${APPROVED:-}" == true ]] || { echo 'CI artifact upload lacks explicit owner approval.' >&2; exit 1; }
for file in LICENSE NOTICE; do
  [[ -s "$file" ]] || { echo "Missing/nonempty required text: $file" >&2; exit 1; }
done
for digest in "${APPROVED_LICENSE_SHA256:-}" "${APPROVED_NOTICE_SHA256:-}"; do
  [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || { echo 'Approved digests must be lowercase SHA-256.' >&2; exit 1; }
done
[[ "$(sha256sum LICENSE | cut -d ' ' -f 1)" == "$APPROVED_LICENSE_SHA256" ]] || { echo 'LICENSE approval digest mismatch.' >&2; exit 1; }
[[ "$(sha256sum NOTICE | cut -d ' ' -f 1)" == "$APPROVED_NOTICE_SHA256" ]] || { echo 'NOTICE approval digest mismatch.' >&2; exit 1; }
(cd dist && sha256sum --check SHA256SUMS)
python3 scripts/wasm-notices.py verify dist/director-compiler.wasm --license LICENSE --notice NOTICE
cp LICENSE NOTICE dist/
(cd dist && sha256sum director-compiler.wasm LICENSE NOTICE > SHA256SUMS && sha256sum --check SHA256SUMS)
