#!/usr/bin/env bash
set -euo pipefail
source_dir="$(cd "$(dirname "$0")" && pwd)"
script="$source_dir/check-artifact-approval.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"
mkdir dist scripts
cp "$source_dir/wasm-notices.py" scripts/
printf 'MIT test license\n' > LICENSE
printf 'third-party test notice\n' > NOTICE
printf '\0asm\r\0\1\0' > dist/director-compiler.wasm
python3 scripts/wasm-notices.py embed dist/director-compiler.wasm --license LICENSE --notice NOTICE
checksum() { (cd dist && sha256sum director-compiler.wasm > SHA256SUMS); }
checksum
export APPROVED=true
export APPROVED_LICENSE_SHA256="$(sha256sum LICENSE | cut -d ' ' -f 1)"
export APPROVED_NOTICE_SHA256="$(sha256sum NOTICE | cut -d ' ' -f 1)"
reject() {
  if bash "$script" > "$work/output" 2>&1; then
    echo 'CI gate accepted invalid licensing or artifact state' >&2; exit 1
  fi
  test ! -e dist/LICENSE && test ! -e dist/NOTICE
}
APPROVED=false reject
APPROVED_LICENSE_SHA256="$(printf '0%.0s' {1..64})" reject
APPROVED_NOTICE_SHA256="$(printf '0%.0s' {1..64})" reject
mv NOTICE saved-notice
reject
mv saved-notice NOTICE
printf 'unreviewed change\n' >> LICENSE
reject
printf 'MIT test license\n' > LICENSE
printf 'unreviewed change\n' >> NOTICE
reject
printf 'third-party test notice\n' > NOTICE
printf '\0asm\r\0\1\0' > dist/director-compiler.wasm
checksum
reject # Valid checksum cannot excuse missing embedded notices.
python3 scripts/wasm-notices.py embed dist/director-compiler.wasm --license LICENSE --notice NOTICE
checksum
printf '\0' >> dist/director-compiler.wasm
reject
printf '\0asm\r\0\1\0' > dist/director-compiler.wasm
python3 scripts/wasm-notices.py embed dist/director-compiler.wasm --license LICENSE --notice NOTICE
checksum
bash "$script"
(cd dist && sha256sum --check SHA256SUMS)
echo 'Director CI candidate approval tests passed'
