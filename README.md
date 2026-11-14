# GAMS Director Compiler

The Director Compiler is a [GAMS](https://github.com/kkgams/gams) WASM Project Unit that compiles `.director` source into deterministic Director JSON IR or structured diagnostics. Callers own file access and resource packing.

| Unit | Source / output | License | Original work |
| --- | --- | --- | --- |
| Director Compiler | `compiler.odin`, `core.odin`, `lexer.odin`, `rules.odin`, `json_writer.odin`, `component.c`; `build.nosync/director-compiler.wasm` | [MIT](LICENSE), complete [third-party terms](NOTICE) | kkgams; Odin and WASI runtime contributors |

The component exports `gams:director-compiler/director-compiler@1.0.0` with `compile(source) -> result<string, list<diagnostic>>`. This interface version does not imply complete Director language v1 support; see [language and implementation status](docs/director-language.md). Linked standard WASI imports must be supplied by the runtime; no Project filesystem preopens are required.

The raw component embeds the complete `LICENSE` and `NOTICE` texts as `gams.license` and `gams.notice`. Preserve these sections when redistributing. GitHub assets and the existing `ghcr.io/kkgams/gams/director-compiler:<numeric-version>` distribution remain independent of the interface version.

## Development

Install Nix, then run native commands with `nix develop --command make <target>`. Odin, WASI SDK, binding tools, Rust/Wasmtime and dependency-free Node are pinned by the flake and Cargo lockfile.

| Command | Purpose |
| --- | --- |
| `make build` | Compile the component under `build.nosync/`. |
| `make package` | Build raw WASM, full LICENSE/NOTICE and SHA256SUMS; unchanged output does no work. |
| `make test` | Compile a separate test component and run all Director behavioral assertions through native Wasmtime. |
| `make open` | Build and open local `gams.json` in the released macOS Apple Silicon Host. |
| `make serve-docs` | Serve pinned wiki; independent `DOCS_PORT` defaults to 8080. |
| `make docs` | Build documentation into `build.nosync/site/`. |
| `make validate-docs` | Validate documentation links and metadata. |
| `make clean` | Remove known generated build, docs and marked downloads; preserve supplied tools/Units and unidentified legacy output. |

The Host downloads only when absent and retains its release notices. Existing tools are not updated implicitly. The local Project is a Files View preview, not a compiler editor or runtime test. GUI interaction is not covered by the native suite.
