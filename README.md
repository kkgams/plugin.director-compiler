## Current tag-based release authorization

Pushing the matching version tag authorizes release in this repository. No manual
checksum variables, approval boolean, hosted-review approval, or `release`-branch
HEAD match is required. Branch candidates still validate their payloads; they do
not publish a GitHub Release or OCI version. Manual branch runs verify only.

Repository/tag/version and WIT identity checks, build/runtime tests, source and
build-evidence checks, nonempty LICENSE/NOTICE, exact embedded licensing bytes,
generated SHA256SUMS, independent candidates, and GitHub Release/OCI no-overwrite
checks remain required. The workflow uses the automatic GitHub token. Never move
or overwrite an existing version tag. Pages publication remains independent.

This policy supersedes historical approval-variable and pre-tag review/branch
requirements below, not source provenance or legal terms. It does not claim hosted
validation or authorize this editing session to commit, push, tag, or publish.
No source snapshots, legal texts, or historical evidence are refreshed.

> **Prospective v0.2.0 maintenance preparation — NOT release-ready.**
> Target: `plugin.director-compiler` v0.2.0, `director-compiler.wasm`, `ghcr.io/kkgams/gams/director-compiler:0.2.0`.
> Below is frozen historical documentation: existing GitHub Release URLs,
> versioned examples and repair instructions refer to their original releases.
> For a future v0.2.0 candidate, use the prepared distribution metadata;
> rebuild and run repository-owned locked toolchain/runtime tests, review
> source drift, linked evidence and exact LICENSE/NOTICE/candidate digests.
> Migrate the direct-release publisher to draft-first immutable-policy and
> exact public-byte verification before any tag/OCI push/Pages publication.
> Do not run the historical publishing commands as v0.2.0 instructions.

# GAMS Director Compiler

The Director Compiler is a singleton WASM Project Unit that compiles human-authored Director source (`.director`) into deterministic Director JSON IR (`.director.json`). It is a pure source-to-JSON component: callers provide text and own file access and resource packing.

## Release identity

- Distribution version: **0.1.0** (canonical value: [`version.txt`](./version.txt))
- WIT package: **`gams:director-compiler@1.0.0`**
- OCI artifact: **`ghcr.io/kkgams/gams/director-compiler:0.1.0`**

The distribution version and WIT interface version are independent. A `0.1.0` pilot distribution exposing WIT `1.0.0` does **not** claim the Director language implementation is complete.

## Implementation status

This pilot implements the core tracer bullet, including entities, direct matchers, rules, common changes, deterministic JSON, and structured diagnostics. Accepted v1 work remains incomplete, notably structured value paths, nested matcher link values, matcher continuations, declaration/rule interleaving, and complete diagnostic recovery. See [Director language and implementation status](./docs/director-language.md) for the exact current list.

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

- [Director language and current implementation status](./docs/director-language.md)
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

The build/tests and publication workflow verify exact embedded bytes. The engineering notice audit is in [`THIRD-PARTY-REVIEW.md`](./THIRD-PARTY-REVIEW.md). Public CI logs can supply initial Linux SDK/link evidence without distributing a WASM. The first hosted Linux run passed with uploads disabled. A downloadable Actions candidate now requires the checked-in `CI_ARTIFACT_UPLOAD_ENABLED` switch (now `true`) plus this repository's exact `LICENSE_SHA256` and `NOTICE_SHA256` variables; GHCR/GitHub Release starts only when the owner pushes the matching version tag; there is no release-approval boolean. Review the candidate and run the optional branch-only release dry run before tagging. Exact-byte licensing digests still fail closed. See [`PUBLISHING.md`](./PUBLISHING.md).

## Local Project and documentation

```sh
nix develop --command make open
make serve-docs                 # http://localhost:8080; override DOCS_PORT
make validate-docs
make docs                       # portable site under build/site/
```

`make open` builds the component and opens this repository's `gams.json` with
explicit `GAMS_APP_CWD`. If absent, `tools/gams.app` is downloaded from the latest
GAMS macOS Apple Silicon release, with its accompanying notices retained.
An existing download is never updated implicitly; Gatekeeper is not bypassed.
No neighboring checkout is required. First launch needs network access for the
Project's pinned published dependencies.

The local Project loads the built plugin and the published Files View to browse
Project files. It is not a plugin-specific editor or an API/runtime test.
The wiki uses pinned `justgook/wiki` v1.4.0, cached under ignored `build/`.
GitHub Pages builds with `make docs` on every push to `release`, independently of
component releases. Set Pages source to **GitHub Actions** in repository settings.
