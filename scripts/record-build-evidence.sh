#!/usr/bin/env bash
set -euo pipefail

output_dir="${1:-evidence}"
build_dir="${BUILD_DIR:-build}"
dist_dir="${DIST_DIR:-dist}"
cc="${WASI_P2_CC:-wasm32-wasip2-clang}"
wasm_tools="${WASM_TOOLS:-wasm-tools}"
gen_dir="$build_dir/bindings"
component_name=director_compiler_plugin
odin_object="$build_dir/director_compiler_core.o.wasm"
component_type_object="$gen_dir/${component_name}_component_type.o"
artifact="$dist_dir/director-compiler.wasm"

: "${WASI_SDK_PATH:?WASI_SDK_PATH must point to the WASI SDK used for the build}"
for required in LICENSE NOTICE "$WASI_SDK_PATH/VERSION" \
  "$gen_dir/${component_name}.c" "$component_type_object" "$odin_object" "$artifact"; do
  if [[ ! -s "$required" ]]; then
    printf 'build evidence requires nonempty %s\n' "$required" >&2
    exit 1
  fi
done

# Evidence is immutable per run: never delete an arbitrary caller-supplied path.
mkdir -p "$(dirname "$output_dir")"
mkdir "$output_dir"
mkdir "$output_dir/link-inputs" "$output_dir/module-metadata"

# Preserve the SDK's own version record and the exact tool reports rather than
# inferring versions from the flake inputs.
cp "$WASI_SDK_PATH/VERSION" "$output_dir/wasi-sdk-VERSION"
{
  printf 'uname: '; uname -a
  printf 'odin: '; odin version
  printf 'wasm-tools: '; "$wasm_tools" --version
  printf 'wit-bindgen: '; wit-bindgen --version
  printf 'wkg: '; wkg --version
  printf 'node: '; node --version
  printf 'npm: '; npm --version
  printf 'python: '; python3 --version
  printf 'wasi clang:\n'; "$cc" --version
  printf 'wasm-component-ld: '; "$WASI_SDK_PATH/bin/wasm-component-ld" --version
  printf 'wasm-ld: '; "$WASI_SDK_PATH/bin/wasm-ld" --version
} > "$output_dir/tool-versions.txt" 2>&1

# Recompile the two C translation units, then perform a genuine link from the
# resulting objects and the same generated/Odin objects used by the main build.
"$cc" -c -I"$gen_dir" -O2 -DNDEBUG \
  "$gen_dir/${component_name}.c" \
  -o "$output_dir/link-inputs/${component_name}.o"
"$cc" -c -I"$gen_dir" -O2 -DNDEBUG \
  component.c \
  -o "$output_dir/link-inputs/component.o"
cp "$odin_object" "$output_dir/link-inputs/director_compiler_core.o.wasm"
cp "$component_type_object" "$output_dir/link-inputs/${component_name}_component_type.o"

link_rerun="$output_dir/director-compiler.link-rerun.wasm"
link_map="$output_dir/director-compiler.link.map"
"$cc" -o "$link_rerun" -mexec-model=reactor \
  "$output_dir/link-inputs/${component_name}.o" \
  "$output_dir/link-inputs/component.o" \
  "$output_dir/link-inputs/director_compiler_core.o.wasm" \
  "$output_dir/link-inputs/${component_name}_component_type.o" \
  -Wl,--strip-all -Wl,-Map,"$link_map"
test -s "$link_rerun"
test -s "$link_map"
"$wasm_tools" validate "$link_rerun"
# Prove the inspected link has the same release bytes after normal packaging.
"$wasm_tools" strip -a "$link_rerun" -o "$output_dir/repackaged.wasm"
python3 scripts/wasm-notices.py embed "$output_dir/repackaged.wasm" --license LICENSE --notice NOTICE
cmp "$artifact" "$output_dir/repackaged.wasm"

sha256sum LICENSE NOTICE "$artifact" > "$output_dir/artifact-sha256.txt"
sha256sum "$output_dir"/link-inputs/* "$link_rerun" > "$output_dir/link-rerun-sha256.txt"

for module in "$output_dir"/link-inputs/* "$link_rerun" "$artifact"; do
  name="$(basename "$module")"
  "$wasm_tools" metadata show --json "$module" \
    > "$output_dir/module-metadata/${name}.json"
done
