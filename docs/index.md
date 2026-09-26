---
title: Director Compiler
description: Distribution identity, component boundary, and current release status.
eyebrow: GAMS Project Unit
status: in-progress
---

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

This site is deployed from release tags so its default content corresponds to an explicit released source ref. Aggregate GAMS ecosystem documentation is intentionally outside this repository.
