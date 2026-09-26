# GAMS Director Compiler

The Director Compiler is a singleton WASM Project Unit that compiles human-authored Director source (`.director`) into deterministic Director JSON IR (`.director.json`). It is a pure source-to-JSON component: callers provide text and own file access and resource packing.

## Release identity

- Distribution version: **0.1.0** (canonical value: [`version.txt`](./version.txt))
- WIT package: **`gams:director-compiler@1.0.0`**
- OCI artifact: **`ghcr.io/kkgams/gams/director-compiler:0.1.0`**

The distribution version and WIT interface version are independent. A `0.1.0` pilot distribution exposing WIT `1.0.0` does **not** claim the Director language implementation is complete.

## Implementation status

This pilot implements the core tracer bullet, including entities, direct matchers, rules, common changes, deterministic JSON, and structured diagnostics. Accepted v1 work remains incomplete, notably structured value paths, nested matcher link values, matcher continuations, declaration/rule interleaving, and complete diagnostic recovery. See [Director language and implementation status](./docs/language.md) for the exact current list.

Do not describe this distribution as a complete implementation of Director language v1 merely because its WIT contract is `1.0.0`.

## Build and test

With Nix installed:

```sh
nix develop --command make test
nix develop --command make build
```

Inside the development shell, the equivalent commands are `make test` and `make build`. The release workflow runs tests before it accepts the build artifact.

The expected output is:

```text
dist/director-compiler.wasm
```

## Component API

The canonical contract is [`wit/package.wit`](./wit/package.wit):

```wit
compile: func(source: string) -> result<string, list<diagnostic>>;
```

Successful compilation returns Director IR as JSON text. Invalid source returns structured diagnostics and no JSON. The authored WIT API has no imports and the compiler does not read Project files. The linked artifact nevertheless imports WASI 0.2.6 interfaces through the SDK runtime: `io/error`, `io/streams`, `cli/stdin`, `cli/stdout`, `cli/stderr`, `clocks/wall-clock`, `filesystem/types`, and `filesystem/preopens`. A consumer must supply those standard interfaces; the pure compiler operation does not require Project filesystem preopens. Do not treat the artifact as import-free.

## Documentation

- [Director language and current implementation status](./docs/language.md)
- [Release checklist](./RELEASE-CHECKLIST.md)
- [Publishing and validation notes](./PUBLISHING.md)
- [Repository context](./CONTEXT.md)

## License

[MIT](./LICENSE), selected by the owner for this standalone Director Compiler repository. Third-party code retains its applicable notices and terms.

The built WASM carries the complete `LICENSE` bytes in a top-level `gams.license` custom section and the complete required `NOTICE` bytes in `gams.notice`. These are added after stripping. Do not strip licensing sections from redistributed artifacts.

Verify a downloaded artifact against this release's license files:

```sh
python3 scripts/wasm-notices.py verify dist/director-compiler.wasm --license LICENSE --notice NOTICE
```

The build/tests and publication workflow verify exact embedded bytes. The engineering notice audit is in [`THIRD-PARTY-REVIEW.md`](./THIRD-PARTY-REVIEW.md). Actual Linux verification and digest-bound owner approval of both `LICENSE` and `NOTICE` remain required. See [`PUBLISHING.md`](./PUBLISHING.md).
