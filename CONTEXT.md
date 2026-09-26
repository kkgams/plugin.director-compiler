# Director Compiler context

## Language

**Director**:
The narrative world model and rule runtime whose authored source language is compiled by this repository.

**Director Compiler**:
A singleton WASM Project Unit that parses, validates, and lowers Director source text into deterministic Director JSON IR.

**Distribution Version**:
The release version of this repository and its built component artifact. It is read from `version.txt` and currently starts at `0.1.0`.

**WIT Interface Version**:
The version in the WIT package declaration that identifies the component contract. It is currently `gams:director-compiler@1.0.0` and is independent of the Distribution Version.

**Director JSON IR**:
The deterministic JSON output of successful compilation. It is intermediate runtime data, not a packed resource.

**Structured Diagnostic**:
A source error containing a stable code, human-readable message, and source span. Invalid source produces diagnostics instead of JSON.

## Relationships and boundaries

- The Director Compiler accepts source text and returns Director JSON IR or Structured Diagnostics.
- The caller owns reading source, writing output, and any later resource-packing step.
- The Director Compiler API is pure and does not read Project Config. Its linked WASM artifact has standard WASI SDK runtime imports, including filesystem interfaces; these are distinct from authored GAMS plugin dependencies.
- Distribution Version `0.1.0` exposes WIT Interface Version `1.0.0`; neither number asserts complete implementation of all accepted Director v1 language behavior.
- `docs/director-language.md` documents both accepted syntax and explicit implementation gaps.

## Current ambiguity

The owner selected MIT for the standalone Director Compiler repository; its text is in `LICENSE`. Publication requires preservation of third-party copyright/permission notices in raw-WASM distribution, exact repository-scoped LICENSE/NOTICE SHA-256 matches, and an owner-pushed release tag; no separate approval boolean is required. Review the third-party notice inventory before tagging. This selection does not relicense unrelated GAMS code or third-party dependencies.
