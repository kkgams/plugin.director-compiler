# Director compiler WebAssembly third-party review

## Scope and conclusion

This review covers the final standalone `dist/director-compiler.wasm`, not the
whole source snapshot or development shell. It distinguishes code present in
(or conservatively treated as present in) the distributed component from tools
used only to build or test it.

The final component needs a third-party notice. `template/NOTICE` contains the
source-authentic license/notice text selected by this review. The project's own
MIT license remains in `template/LICENSE`, is embedded separately as
`gams.license`, and is intentionally not duplicated in `NOTICE`.

This is an engineering license review, not legal advice or a representation of
perfect legal certainty. The conservative choices and remaining provenance
questions are called out below.

## Pinned inputs and provenance

### Odin runtime and libraries included in the core module

The standalone flake locks `odin-lang/Odin` to:

- commit `db0cd79633fe05069dc4f9248d2796eb8ec3b858`;
- Nix source hash `sha256-y4vuR3l4xpZ1o0bkalDIEPLQZBsEyGK+10HFk2bGP0U=`;
- reported compiler version `dev-2026-08:db0cd7963`.

The package source imports `core:mem` and `base:runtime`; Odin also supplies its
runtime implicitly and those packages use `base:intrinsics` and `base:builtin`.
For `-target:wasi_wasm32`, the applicable source set is from the exact pinned
`base/runtime`, `base/intrinsics`, `base/builtin`, and `core/mem` trees. In
particular, the target selects `entry_wasm.odin`, `os_specific_wasi.odin`,
`heap_allocator_other.odin`, `procs_wasm.odin`, and `wasm_allocator.odin`; it
does not select the Unix, Windows, JS, Orca, or BSD target files. Odin's
minimum-dependency and LLVM passes remove unused declarations, so “parsed from
the package” is not the same as “has bytes in the final module.”

The unstripped Odin object provides direct evidence for retained runtime code:
its linking metadata names `runtime::bounds_check_error.handle_error`,
`runtime::slice_handle_error`, runtime printing procedures, 128-bit helpers,
and memory operations. The final notice therefore includes the exact Odin root
license. It also conservatively includes Odin's exact
`base/runtime/LICENSE-compiler-rt.txt`: the pinned runtime source contains
LLVM-derived `runtime.fixuint`/`runtime.fixint`, although those names were not
found in this optimized object.

`core/mem/tlsf` is a separate subpackage and is not imported by this compiler;
its license is not included. Odin itself is both a build tool and the source of
runtime/library code compiled into the output; only the latter creates the
runtime notice rationale.

### WASI SDK 33 link inputs

The flake downloads the platform archive named by release `wasi-sdk-33`, SDK
version `33.0`, under a platform-specific fixed SHA-256. The inspected SDK
reports:

```text
33.0+m
wasi-libc: 161b3195fc25
llvm: 4434dabb6991
llvm-version: 22.1.0
config: f992bcc08219
```

The release tag and exact source topology are:

- `WebAssembly/wasi-sdk` annotated tag `wasi-sdk-33`, peeled commit
  `c10c0507deb3e5aad506f1f9f32084e49a21834b`;
- submodule `src/wasi-libc` commit
  `161b3195fc2558d2b1ba3eb9ffae3b2b47407623`, also tag `wasi-sdk-33`;
- submodule `src/llvm-project` commit
  `4434dabb69916856b824f68a64b029c67175e532`, also peeled tag
  `llvmorg-22.1.0`;
- submodule `src/config` commit
  `f992bcc08219edb283d2ab31dd3871a4a0e8220e`.

`wasm32-wasip2-clang -###` confirms the link driver passes:

- WASI `crt1-reactor.o`;
- `-lc`, resolved from the `wasm32-wasip2` wasi-libc archive;
- `libclang_rt.builtins.a`;
- `wasm-component-ld` as the linker frontend, with SDK `wasm-ld` beneath it.

A repeated real link with `-Wl,-Map,/tmp/director-link.map` proves that the
following wasi-libc members contribute to the output:

```text
__init_tls.c.obj
abort.c.obj
default_attr.c.obj
defsysinfo.c.obj
dlmalloc.c.obj
errno.c.obj
pthread_self.c.obj
sbrk.c.obj
```

It also proves that no member of `libclang_rt.builtins.a` was selected. The
archive is on the command line, but no compiler-rt archive code is linked in
this build. Accordingly, the SDK compiler-rt/LLVM license is not included on
that basis. Odin's separately copied compiler-rt-derived runtime notice remains
included for the reason above.

The selected wasi-libc objects include wasi-libc-authored code, musl-derived
code, and dlmalloc. `NOTICE` therefore contains exact copies of wasi-libc's
license inventory, its MIT license option, musl's full `COPYRIGHT`, and the
complete opening public-domain/CC0 notice from `dlmalloc/src/malloc.c`.
Cloudlibc and musl-fts notices are not included: the link map does not select
those implementations. In particular, the linked `errno.c.obj` defines the
`__EINVAL`/`__ENOMEM` constants used by dlmalloc and corresponds to
`libc-bottom-half/sources/errno.c`, not cloudlibc's errno implementation.

Clang and `wasm-ld` are build tools. Their executable code is not distributed in
the component. Headers do not add a separately identified notice here, and the
compiler-rt archive contributes no members.

### Preview 1 adapter and component linker

The SDK source sets `wasm_component_ld_version` to `0.5.22` and installs
`wasm-component-ld@0.5.22`. Upstream tag `v0.5.22` is commit
`c9e38b9bc181ce7a4f8b3d21edb48c47ddf197de`. The installed SDK binary reports
`wasm-component-ld 0.5.22`.

That linker declares `wasi-preview1-component-adapter-provider = "43.0.0"`.
The upstream v0.5.22 lock records provider version `43.0.0`, crates.io checksum
`93759d6fd0db242718bdcc6e4626eff8b0f3124ee7e58e47177a59f561baf164`.
The published provider crate contains command, proxy, and reactor adapters and
identifies repository `bytecodealliance/wasmtime` with license
`Apache-2.0 WITH LLVM-exception`. Wasmtime tag `v43.0.0` is exact commit
`be23469ece57c0be64904f12111c8d808b0ce4ac`.

Because the core module imports `wasi_snapshot_preview1` and the link uses
`-mexec-model=reactor`, `wasm-component-ld` injects the provider's reactor
adapter. `wasm-tools component unbundle --threshold 0` finds a 9,963-byte Rust
core module in the built component with producer:

```text
rustc 1.93.0 (254b59607 2026-01-19)
```

The provider's reactor artifact has the same producer. Its original artifact
is 52,286 bytes; component encoding retains/transforms only the portions needed
by this component, so a whole-file hash comparison after encoding is not
expected. Rust tag `1.93.0` peels to exact commit
`254b59607d4417e9dffbc307138ae5c86280fe4c`.

The adapter is distributed code, not merely a tool, so `NOTICE` includes the
exact Wasmtime Apache-2.0-with-LLVM-exception license and, conservatively, the
Rust 1.93.0 MIT notice for runtime portions in the Rust-produced adapter.

`wasm-component-ld`, `wit-component`, and `wit-bindgen` are build tools, but
generated binding/component support and small synthesized modules remain in
the result. Conservatively, one exact common Bytecode Alliance MIT notice is
included with provenance for:

- `wasm-component-ld` v0.5.22 / commit
  `c9e38b9bc181ce7a4f8b3d21edb48c47ddf197de`;
- `wit-bindgen` v0.57.1 / flake-locked commit
  `2e00369a643c0c8048b8636401e36b0cbf2dfb05`.

Their `LICENSE-MIT` files are byte-identical at those revisions. `wasm-tools`
only strips and validates the artifact; its code is not distributed and its
license is not included.

### Tools not distributed

No separate notices are included merely for these tools or their dependency
trees:

- the Odin compiler executable (distinct from compiled Odin runtime/library);
- Clang, `wasm-ld`, and unused compiler-rt archive members;
- `wasm-tools` stripping/validation code;
- `wit-bindgen` CLI code beyond generated output;
- `wkg` (present in the shell but unused by this build);
- Node.js, jco, and npm dependencies (test/transpile host only);
- Nix/nixpkgs and host patching tools.

The jco-transpiled JavaScript under `build/jco` is a test intermediate and is
not the standalone release artifact under review.

## Notice contents and obligations

`template/NOTICE` uses full text copied from the exact pinned/tagged sources; no
license wording was reconstructed. It includes:

1. Odin's zlib-style root license for linked runtime/core code.
2. Odin's full compiler-rt-derived runtime notice.
3. wasi-libc's exact inventory and selected MIT text.
4. dlmalloc's exact public-domain/CC0 notice.
5. musl's complete copyright/license file.
6. Wasmtime's complete Apache-2.0-with-LLVM-exception text for the adapter.
7. Rust's complete MIT notice, conservatively, for adapter runtime portions.
8. The exact common wasm-component-ld/wit-bindgen MIT text for generated
   support.

The Apache LLVM exception permits embedded portions resulting from compilation
to be redistributed without Apache sections 4(a), 4(b), and 4(d). This review
still carries the full source license text conservatively. The wasi-libc MIT,
musl MIT, Odin, and Bytecode Alliance MIT terms require preservation of their
notices under their respective conditions; embedding `NOTICE` in `gams.notice`
and distributing the source snapshot's `NOTICE` serves that purpose.

## Verification instructions

Prepare a fresh extraction so the new template notice is copied, then build
using the standalone locked flake:

```sh
# Run from the source monorepo; choose a fresh destination (never overwrite).
python3 packaging/director-compiler/prepare.py \
  --output build.nosync/release/plugin-director-compiler-license-review
cd build.nosync/release/plugin-director-compiler-license-review
nix develop 'path:.' --command make clean test
```

Verify the embedded project license and third-party notice exactly match the
source files:

```sh
nix develop 'path:.' --command \
  python3 scripts/wasm-notices.py verify dist/director-compiler.wasm \
    --license LICENSE --notice NOTICE
```

Inspect the pinned toolchain and SDK identity:

```sh
nix develop 'path:.' --command bash -c '
  odin version
  wasm32-wasip2-clang --version
  wasm-component-ld --version
  cat "$WASI_SDK_PATH/VERSION"
  wasm32-wasip2-clang -### -mexec-model=reactor /dev/null 2>&1 | tail -20
'
```

Recreate the linker-member evidence after `make` (this changes only `/tmp`):

```sh
nix develop 'path:.' --command bash -c '
  wasm32-wasip2-clang -o /tmp/director-license-map.wasm \
    -mexec-model=reactor -Ibuild/bindings -O2 -DNDEBUG \
    build/bindings/director_compiler_plugin.c component.c \
    build/director_compiler_core.o.wasm \
    build/bindings/director_compiler_plugin_component_type.o \
    -Wl,--strip-all -Wl,-Map,/tmp/director-license.map
  grep -E "libc[.]a|clang_rt|crt1-reactor" /tmp/director-license.map
'
```

Inspect embedded modules and adapter producer metadata:

```sh
rm -rf /tmp/director-unbundled && mkdir /tmp/director-unbundled
nix develop 'path:.' --command wasm-tools component unbundle \
  --threshold 0 --module-dir /tmp/director-unbundled \
  build/director-compiler.unstripped.wasm \
  -o /tmp/director-unbundled/component.wasm
for module in /tmp/director-unbundled/*.wasm; do
  nix develop 'path:.' --command wasm-tools metadata show "$module"
done
```

To verify upstream references independently:

```sh
git ls-remote https://github.com/WebAssembly/wasi-sdk.git \
  'refs/tags/wasi-sdk-33' 'refs/tags/wasi-sdk-33^{}'
git ls-remote https://github.com/WebAssembly/wasi-libc.git \
  'refs/tags/wasi-sdk-33'
git ls-remote https://github.com/llvm/llvm-project.git \
  'refs/tags/llvmorg-22.1.0' 'refs/tags/llvmorg-22.1.0^{}'
git ls-remote https://github.com/bytecodealliance/wasm-component-ld.git \
  'refs/tags/v0.5.22'
git ls-remote https://github.com/bytecodealliance/wasmtime.git \
  'refs/tags/v43.0.0'
git ls-remote https://github.com/rust-lang/rust.git \
  'refs/tags/1.93.0' 'refs/tags/1.93.0^{}'
```

## Open issues before publication

1. **Obtain owner/counsel approval.** This is a source- and artifact-backed
   engineering review, not legal advice.
2. **SDK `cargo install` is not visibly locked.** WASI SDK 33's build recipe
   runs `cargo install wasm-component-ld@0.5.22` without `--locked`. The fixed
   SDK release archive makes the shipped binary immutable, and v0.5.22's
   source/lock plus producer metadata support the adapter identification, but
   the transformed embedded adapter cannot be whole-file hash-matched to the
   provider crate artifact. If cryptographic source-to-binary provenance is a
   release requirement, rebuild and pin the linker/provider artifact directly
   or obtain upstream build attestation/SBOM.
3. **Cross-platform SDK archive parity was not byte-inspected.** The flake pins
   four platform archives independently. This audit inspected the
   `aarch64-macos` SDK contents and upstream release source. Before claiming
   identical third-party composition across all release builders, repeat the
   VERSION/link-map/module checks on each supported platform (the generated
   target Wasm is expected to use the same SDK source revisions).
4. **Use a fresh extraction containing NOTICE.** The earlier
   `build.nosync/release/plugin-director-compiler-notices` predates
   `template/NOTICE`; it is evidence input, not the publication candidate.
   The standalone Ubuntu verification workflow records SDK identity, linker
   members and producer metadata and proves its inspected link repackages to
   the candidate's exact bytes. Its actual Linux run remains pending.
5. **Keep review coupled to pins.** Any Odin commit, WASI SDK release,
   wasm-component-ld, wit-bindgen, or wasm-tools pin change requires this review
   and `NOTICE` to be regenerated from the new exact sources.
