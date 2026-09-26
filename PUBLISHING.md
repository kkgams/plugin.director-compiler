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

Runs for pull requests, branch pushes, and manual dispatch on Ubuntu. It installs Nix, runs `make test`, OCI preflight mock tests, and `make build`. It uploads the candidate plus `dist/evidence/`: SDK identity, tool versions, licensing/artifact hashes, a linker map, and module metadata. The evidence link is repackaged and compared byte-for-byte against the candidate. It has read-only repository permissions and cannot publish; no approval variables are needed.

### `release.yml`

Runs for `v*` tags or manually. Runs for the same workflow/ref are serialized and are never canceled in progress. Its verification job tests the mocked OCI safety paths before building and stages a checksummed artifact. The publication job runs only from a tag and then:

1. verifies `refs/tags/v<version.txt>`;
2. verifies the WIT package declaration;
3. enforces the licensing gate, including exact approved `LICENSE` and `NOTICE` SHA-256 digests (also checked before the verification job builds);
4. downloads the candidate, verifies its original checksum, and creates a final `SHA256SUMS` covering the component, `LICENSE`, and required root `NOTICE`;
5. authenticates to GHCR with the workflow token;
6. obtains a registry token with the explicit `repository:<path>:pull` scope and checks the exact Distribution Version tag;
7. pushes only when the registry explicitly returns `404`; if the tag exists, pulls it and skips the push only when its component bytes exactly match, otherwise fails;
8. creates the matching GitHub Release with the component, checksum manifest, `LICENSE`, and applicable `NOTICE`.

Authentication failures, transport failures, malformed responses, and registry statuses other than the expected `200`/`404` are failures, never evidence that a tag is absent. This makes a retry after an interrupted release safe: an identical existing OCI artifact is retained, while a different artifact can never be overwritten by the workflow. A GitHub Release that already exists is still a hard failure and requires owner review.

A manual run on a branch is a verification-only run. A manual run intended to publish must select an existing release tag as its ref and still pass every gate.

### `pages.yml`

Builds and deploys the repository-owned wiki from `docs/` for a published release. The release workflow calls it after creating the checksummed release; owner-created `release.published` events can also run it. A manual run must select an existing published release tag; branch refs fail. This makes released documentation, not development-branch documentation, the default Pages deployment. The workflow uses the actual `justgook/wiki` action API: `source`, `output`, and its `path` output. Aggregate ecosystem documentation belongs elsewhere and is not implemented here.

## Required owner setup

No credentials should be shared with automation authors or local tooling. A repository owner must:

1. review the owner-selected MIT license at root `LICENSE` and its copyright attribution;
2. review root `NOTICE` and `THIRD-PARTY-REVIEW.md`, including the SDK adapter provenance limitation and Linux evidence;
3. verify the built raw-WASM OCI artifact: `gams.license` must match `LICENSE`, and `gams.notice` must match `NOTICE` when present. The build embeds these after stripping; tests and the downloaded-artifact release gate check exact bytes. Review the complete linked dependency notice inventory before final approval;
4. compute `sha256sum LICENSE NOTICE`; set `DIRECTOR_COMPILER_LICENSE_SHA256` and `DIRECTOR_COMPILER_NOTICE_SHA256` to their respective lowercase digests. Set `DIRECTOR_COMPILER_LICENSE_APPROVED=true` only after approving both exact texts and the raw-OCI packaging decision;
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

For actual Linux validation, the owner must push the assembled standalone repository to a branch (not a release tag), open **Actions → Verify component → Run workflow**, and wait for success. No licensing-approval variables need to be enabled. Download its candidate/evidence artifact, review `wasi-sdk-VERSION`, linker members and adapter producer metadata against `THIRD-PARTY-REVIEW.md`, and record the run URL and source commit. Local macOS success or workflow linting is not Linux execution evidence.

Then complete [`RELEASE-CHECKLIST.md`](./RELEASE-CHECKLIST.md). Only the owner should create/push the release tag after the licensing gate is genuinely satisfied.
