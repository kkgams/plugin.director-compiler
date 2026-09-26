# Director Compiler release checklist

Use this checklist for the pilot distribution and every later release. Checking a box does not itself publish anything.

## Identity and scope

- [ ] `version.txt` contains the intended Distribution Version (pilot: `0.1.0`).
- [ ] The release tag is exactly `v<version.txt>` (pilot: `v0.1.0`).
- [ ] `wit/package.wit` declares the intended WIT package version (pilot: `gams:director-compiler@1.0.0`).
- [ ] README, wiki, release notes, and OCI coordinates distinguish Distribution Version from WIT Interface Version.
- [ ] Release notes state that Director language v1 implementation remains incomplete and list current gaps.

## Required licensing decision — hard gate

- [x] The owner selected MIT for this standalone repository.
- [x] MIT license text exists at repository root as `LICENSE`.
- [x] Engineering audit of linked code is recorded in `THIRD-PARTY-REVIEW.md`; root `NOTICE` contains source-authentic third-party texts.
- [x] Build embeds exact `LICENSE` and optional `NOTICE` bytes after stripping; tests and the pre-publication gate verify them.
- [ ] Owner has reviewed the notice inventory, Linux evidence, and documented adapter provenance limitation before final approval.
- [ ] The owner has set repository variable `DIRECTOR_COMPILER_LICENSE_SHA256` to the lowercase output of `sha256sum LICENSE`.
- [ ] The owner has set `DIRECTOR_COMPILER_NOTICE_SHA256` to the lowercase output of `sha256sum NOTICE`.
- [ ] Only after reviewing exact notice bytes and Linux CI logs, the owner sets **candidate-only** `DIRECTOR_COMPILER_ARTIFACT_UPLOAD_APPROVED=true` and checks the downloaded candidate's `SHA256SUMS`, embedded texts and evidence.
- [ ] After reviewing the candidate, the owner has separately set repository variable `DIRECTOR_COMPILER_LICENSE_APPROVED` to exactly `true` for the GHCR/Release packaging decision.

The workflow must fail before building a release if `LICENSE`, `NOTICE`, any approval variable, or either exact digest match is absent. Changing either licensing file invalidates approval. Do not add placeholder or guessed license text to pass this gate.

## Build and test

- [ ] Standalone Ubuntu **Verify component** workflow passed without distribution variables; run URL and source commit recorded, Linux SDK/link/adapter evidence printed in logs reviewed against `THIRD-PARTY-REVIEW.md`.
- [ ] Following candidate approval, a separate CI run uploaded the checksummed downloadable artifact with `LICENSE`/`NOTICE`; downloaded evidence and raw WASM notices pass exact-byte review.
- [ ] Branch-only manual `release.yml` passed on the intended commit, including `nix develop --command wkg --version` on Linux; no GHCR or GitHub Release publication occurred.

- [ ] A clean checkout succeeds with `nix develop --command make test`.
- [ ] A clean checkout succeeds with `nix develop --command make build`.
- [ ] `dist/director-compiler.wasm` exists and is non-empty.
- [ ] Component tests exercise successful compilation and structured invalid-source diagnostics.
- [ ] The artifact's exported WIT world is `gams:director-compiler/director-compiler-plugin@1.0.0`.
- [ ] `SHA256SUMS` verifies with `sha256sum --check SHA256SUMS`.

## Publication review

- [ ] The target is `ghcr.io/kkgams/gams/director-compiler:<distribution-version>`.
- [ ] No mutable `latest` or WIT-only OCI tag is being introduced accidentally.
- [ ] The GitHub Release will contain `director-compiler.wasm`, `LICENSE`, applicable `NOTICE`, and `SHA256SUMS` covering every attached distribution file.
- [ ] The raw-WASM-only OCI packaging matches the owner's approved licensing decision.
- [ ] The GitHub Release is tied to the exact `v<distribution-version>` tag.
- [ ] GitHub Pages builds documentation from that release tag.
- [ ] Required GitHub environments, Pages source, package visibility, and digest-bound repository variables were configured by an owner.
- [ ] `./scripts/test-release-oci-preflight.sh` passes without network access, including mocked transport, authentication, and unexpected-status failures.

## Post-publication (owner-operated)

- [ ] Download all GitHub Release assets and verify `SHA256SUMS` independently.
- [ ] Pull the exact GHCR version and compare its component bytes with the release artifact.
- [ ] Verify the released documentation opens at the expected GitHub Pages URL and identifies both versions.
- [ ] If retrying an interrupted run, confirm the preflight skipped only an exact-byte OCI match; a different existing tag requires manual owner recovery and must not be overwritten.
- [ ] Record any divergence or rerun in `PUBLISHING.md` before another attempt.
