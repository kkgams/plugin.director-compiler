# Publishing the Director Compiler

The owner selected MIT for this standalone repository. Raw-WASM notice embedding and verification are implemented. An engineering third-party audit is recorded in `THIRD-PARTY-REVIEW.md`, with full texts in root `NOTICE`. Publication remains gated pending actual Linux verification, owner review of the documented provenance limitations, and approval of both licensing-file digests. This document records the release contract, workflow behavior, validation performed during extraction, and known gaps. It does not authorize publication.

## Release contract

| Item | Pilot value |
| --- | --- |
| Distribution Version | `0.1.0` from `version.txt` |
| Git tag / GitHub Release | `v0.1.0` |
| WIT package | `gams:director-compiler@1.0.0` |
| WIT world | `gams:director-compiler/director-compiler-plugin@1.0.0` |
| GHCR reference | `ghcr.io/kkgams/gams/director-compiler:0.1.0` |
| GitHub Release assets | `director-compiler.wasm`, `LICENSE`, applicable `NOTICE`, `SHA256SUMS` |

Distribution and WIT versions are deliberately separate. The workflow derives the Distribution Version from `version.txt`, derives the WIT version from `wit/package.wit`, verifies the release tag, and publishes only the immutable Distribution Version OCI tag. It does not publish `latest` or a WIT-only tag.

## Workflows

### `verify.yml`

Runs for pull requests, `release` branch pushes, and manual dispatch on Ubuntu. It installs Nix, runs `make test`, mocked candidate/OCI/GitHub Release gates, and `make build`. The Nix shell builds pinned `wkg` with only its upstream network-dependent integration test skipped; all offline Rust checks remain enabled. The build evidence is generated and the SDK/link/module summary is printed in CI logs **without distributing** binaries. The inspected link is repackaged and compared byte-for-byte against the candidate. It has read-only repository permissions and cannot publish.

A downloadable Actions artifact **is distribution**, so the candidate plus `LICENSE`, `NOTICE`, `SHA256SUMS` and `dist/evidence/` is uploaded only for `release` branch runs when the owner sets `DIRECTOR_COMPILER_ARTIFACT_UPLOAD_APPROVED=true` and both digest variables match exact root licensing bytes. `scripts/check-artifact-approval.sh` verifies the embedded bytes and checksums before upload. PR runs never upload, and an initial Linux verification run needs no approval variables. Candidate approval does not grant GHCR or GitHub Release approval.

### `release.yml`

Runs for `v*` tags or manually. Runs for the same workflow/ref are serialized and are never canceled in progress. Its verification job tests the mocked OCI/GitHub Release safety paths, builds the pinned `wkg` in the Linux release shell on **manual branch runs** (without publishing), then builds/tests and stages a checksummed component with separate exact LICENSE and NOTICE assets. The publication job runs only from a tag and then:

1. verifies `refs/tags/v<version.txt>`;
2. verifies the WIT package declaration;
3. enforces the licensing gate, including exact approved `LICENSE` and `NOTICE` SHA-256 digests (also checked before the verification job builds);
4. downloads the candidate, verifies its original checksum, and creates a final `SHA256SUMS` covering the component, `LICENSE`, and required root `NOTICE`;
5. authenticates to GHCR with the workflow token;
6. obtains a registry token with the explicit `repository:<path>:pull` scope and checks the exact Distribution Version tag;
7. pushes only when the registry explicitly returns `404`; if the tag exists, pulls it and skips the push only when its component bytes exactly match, otherwise fails;
8. creates the matching GitHub Release with the component, checksum manifest, `LICENSE`, and applicable `NOTICE`.

Authentication failures, transport failures, malformed responses, and registry statuses other than the expected `200`/`404` are failures, never evidence that a tag is absent. This makes a retry after an interrupted release safe: an identical existing OCI artifact is retained, while a different artifact can never be overwritten by the workflow. A GitHub Release that already exists is still a hard failure and requires owner review; only an explicit GitHub API `404` is treated as absence. Failed authentication, transport errors and other statuses cannot authorize publication.

A manual run on a branch performs the gated build and uploads a **downloadable, owner-approved release candidate**, but does not push GHCR or create a GitHub Release. A manual run intended to publish must select an existing release tag as its ref and still pass every gate.

### `pages.yml`

Builds and deploys the repository-owned wiki from `docs/` for a published release. The release workflow calls it after creating the checksummed release; it does **not** also run from `release.published` (which would race/cancel the reusable Pages run). A manual run must select an existing published release tag; branch refs fail. This makes released documentation, not development-branch documentation, the default Pages deployment. The workflow uses the actual `justgook/wiki` action API: `source`, `output`, and its `path` output. Aggregate ecosystem documentation belongs elsewhere and is not implemented here.

## Required owner setup

No credentials should be shared with automation authors or local tooling. A repository owner must:

1. review the owner-selected MIT license at root `LICENSE` and its copyright attribution;
2. review root `NOTICE` and `THIRD-PARTY-REVIEW.md`, including the SDK adapter provenance limitation and Linux evidence;
3. verify the built raw-WASM OCI artifact: `gams.license` must match `LICENSE`, and `gams.notice` must match `NOTICE` when present. The build embeds these after stripping; tests and the downloaded-artifact release gate check exact bytes. Review the complete linked dependency notice inventory before final approval;
4. compute `sha256sum LICENSE NOTICE`; set `DIRECTOR_COMPILER_LICENSE_SHA256` and `DIRECTOR_COMPILER_NOTICE_SHA256` to their respective lowercase digests. When approving a downloadable CI candidate, set **separate** `DIRECTOR_COMPILER_ARTIFACT_UPLOAD_APPROVED=true` and rerun `verify.yml` on `release`. After inspecting that downloaded candidate and its Linux evidence, set `DIRECTOR_COMPILER_LICENSE_APPROVED=true` only if approving GHCR/GitHub Release packaging;
5. enable GitHub Actions as the Pages source;
6. review the `github-pages` and `release` environment protection settings, if used;
7. confirm `GITHUB_TOKEN` may write organization packages and create releases;
8. decide package visibility after publication.

Changing either `LICENSE` or `NOTICE` invalidates approval until the owner reviews the change and updates the corresponding digest variable. The boolean remains a deliberate distribution approval gate; both digests bind it to the reviewed licensing bytes. The GitHub Release carries checksummed licensing files, but the OCI artifact remains the raw WASM component. Do not fabricate a `LICENSE`, set any approval variable speculatively, add a personal token, or weaken the workflow gate.

## Validation recorded during extraction

- The source boundary is standalone: root `*.odin`, `component.c`, and `wit/` are copied into the distribution repository.
- The authored WIT contract has no imports. Inspection of the linked artifact found WASI 0.2.6 SDK runtime imports, including filesystem types/preopens; see README for the exact inventory. Consumers must supply these standard interfaces.
- The pilot versions are explicit and non-equivalent: Distribution `0.1.0`, WIT `1.0.0`.
- The source overview identifies implemented tracer-bullet behavior and accepted v1 gaps. The extracted `docs/language.md` must be copied from that overview so status wording does not drift.
- The component artifact has one canonical filename, `director-compiler.wasm`; the final GitHub Release SHA-256 manifest also covers `LICENSE` and applicable `NOTICE`.
- Build/test commands are repository-local (`make test`, `make build`) and run through `nix develop` in CI.
- Workflow actions are pinned to full reachable commits and permissions are scoped per job.
- All three workflow files pass `actionlint` after placing the template at repository root.
- The wiki action's v1.1.0 API and required `_config.md` / `_sidebar.md` files were checked against `justgook/wiki`'s actual `action.yml` and build script. A local assembly smoke test produced `_config.md`, `_sidebar.md`, `index.md`, and `language.md` in the built site's content directory.

## Known gaps / release blockers

- **Blocking:** Engineering notice review and embedding are implemented. Owner approval of the reviewed texts, provenance limitations, and distribution packaging is still pending.
- The accepted Director v1 language is not fully implemented. Current omissions are documented in `docs/language.md`; release notes must not imply otherwise.
- The extraction must be exercised in a fresh standalone checkout on GitHub's Linux runner; validation inside the source repository is not a substitute.
- GHCR push, GitHub Release creation, package visibility, and Pages deployment require owner-controlled GitHub settings and have not been executed by this preparation.
- The public aggregate documentation site is deferred; this repository publishes only its own released documentation.
- Supply-chain provenance/signing beyond GitHub's workflow records and SHA-256 checksums has not been selected.

## Safe pre-publication validation

These commands do not publish:

```sh
nix develop --command make test
nix develop --command make build
test -s dist/director-compiler.wasm
(cd dist && sha256sum director-compiler.wasm > SHA256SUMS)
(cd dist && sha256sum --check SHA256SUMS)
./scripts/test-release-oci-preflight.sh
```

For actual Linux validation, the owner pushes `release` (not a release tag) and waits for **Verify component** to pass. No variables are needed for this build-only run: review the SDK VERSION, toolchain, link map and adapter producer metadata printed in its logs against `THIRD-PARTY-REVIEW.md`. To download candidate/evidence, the owner sets the two exact SHA-256 digest variables and **candidate-only** approval variable as described above, then reruns `verify.yml` on `release`. Check all three payloads with `sha256sum --check SHA256SUMS`, validate the WASM and its embedded texts, and record run URL/source commit. Local macOS success or linting is not Linux execution evidence.

Only after reviewing the candidate, the owner sets the separate `DIRECTOR_COMPILER_LICENSE_APPROVED=true` release variable and manually runs `release.yml` **on the branch**: it now verifies the release shell and `wkg` on hosted Linux without publishing. Complete [`RELEASE-CHECKLIST.md`](./RELEASE-CHECKLIST.md). The owner alone creates/pushes `v0.1.0` on that verified commit. Its tag workflow can push GHCR and create the GitHub Release; Pages deployment additionally requires the owner to configure the Pages environment/source. No retagging a failed pushed version to pick up later workflow fixes.
