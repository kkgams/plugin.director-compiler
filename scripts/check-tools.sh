#!/usr/bin/env bash
set -euo pipefail

expect_exact() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" != "$expected" ]]; then
    printf 'expected %s %s, got %s\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi
}

expect_exact Odin 'dev-2026-08:db0cd7963' "$(odin version | awk '{print $3}')"
expect_exact wasm-tools '1.248.0' "$(wasm-tools --version | awk '{print $2}')"
expect_exact wit-bindgen-cli '0.57.1' "$(wit-bindgen --version | awk '{print $2}')"
expect_exact wkg '0.15.0' "$(wkg --version | awk '{print $2}')"

: "${WASI_SDK_PATH:?WASI_SDK_PATH must point to WASI SDK 33.0}"
expect_exact WASI-SDK '33.0+m' "$(head -n 1 "$WASI_SDK_PATH/VERSION")"
