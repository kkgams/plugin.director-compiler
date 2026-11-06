---
title: Director Compiler
description: Distribution identity, component boundary, and current release status.
eyebrow: GAMS Project Unit
status: in-progress
---
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


# Director Compiler

The Director Compiler turns human-authored `.director` source text into deterministic Director JSON IR. It is distributed as a singleton WASM Project Unit.

## Pilot release identity

| Identity | Version |
| --- | --- |
| Distribution | `0.1.0` |
| WIT package | `gams:director-compiler@1.0.0` |
| OCI artifact | `ghcr.io/kkgams/gams/director-compiler:0.1.0` |

These versions describe different contracts. Distribution `0.1.0` is the pilot artifact release. WIT `1.0.0` is the component interface version. Neither means that every accepted Director language v1 feature is implemented.

## Boundary

The component exports a pure operation:

```wit
compile: func(source: string) -> result<string, list<diagnostic>>;
```

It does not read files, write files, read project configuration, or pack resources. Callers provide source text and decide where to persist or further process successful JSON output.

## Current status

The core compiler tracer bullet is implemented, but accepted Director v1 behavior remains in progress. Read [[Director Language|Language and implementation status]] for supported syntax and the exact current omissions.

## Availability

The owner selected MIT for this repository. Release publication requires the matching owner-pushed tag and exact `LICENSE`/`NOTICE` digests, with notices embedded in the component. Released artifacts include:

- `director-compiler.wasm` and `SHA256SUMS` on the matching GitHub Release;
- the same component at the exact versioned GHCR reference above.

This site is deployed on pushes to the `release` branch, independently of component version tags. Aggregate GAMS ecosystem documentation is intentionally outside this repository.

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
