# Definition of done for a repository

A Heliodoron system repository is done, and tagged `v1.0.0`, when every
point below holds.

## Fixed paths

Every repository carries the same standard files: `README.md`, `LICENSE`,
`NOTICE`, `.gitignore`, `.githooks/`, `.github/workflows/checks.yml`,
`.github/workflows/ci.yml` and `.github/dependabot.yml`. Three folder names
are reserved: `tests/`, `evidence/` and `docs/figures/`. Everything else
follows the system's own layout.

## README

One section order in every repository:

1. Title, one-line description, badges (CI, license)
2. What it is, and what it is not
3. Architecture
4. Results: a table in which every number names its evidence file
5. Quickstart: the offline path, in one command block
6. Tests and CI: what the badge proves and what it cannot
7. Project structure
8. Limits and known issues
9. Provenance
10. Contributing and security
11. License and author

## Reproducible

- Dependencies are declared and locked (`uv.lock`, `package-lock.json`,
  `.terraform.lock.hcl`).
- One documented command runs the offline path. It needs no account, key or
  GPU.
- Python repositories use `uv`, `ruff` and `pytest`. Other stacks use their
  own idiom.

## Tests

- Unit tests cover the core logic the README claims.
- One end-to-end test runs the offline path.
- Everything runs in the `ci` workflow with no secrets.
- Infrastructure repositories also run `terraform validate` and
  `terraform fmt -check`, or a manifest schema check.

## Evidence and evals

- `evidence/` holds machine-written result files. Each set has a manifest:
  the run date, the command and the environment.
- Every number in the README names the file that backs it. A number with no
  file is removed or labelled "observed, not measured".
- A system with a model or an agent has an eval script, its saved outputs,
  and a CI test that recomputes the headline metric from the saved outputs.
- Steps that need a GPU or a paid cloud are replaced in CI by mock mode,
  synthetic fixtures, or a replay of saved results. The README says which.

## Figures

`docs/figures/` holds at least one architecture figure and one result
figure. Figures come from the repository's own synthetic data or evidence.
No third-party images, no real client data, no local paths.

## Clean-copy gate

`scripts/clean-copy-gate.sh` runs locally before every pull request. Source
files are copied by an allowlist of tracked files, never by copying a
folder. Agent files, internal notes, trackers, proposals and event material
are never copied. The gate scans for secrets, denied names, old product
names, cloud identifiers, local paths and email addresses. Notebooks are
re-executed from a clean path.

## History

- The repository is created from `heliodoron/template`, which already
  carries the `ci` gate job.
- The history is a short, honest sequence of pull requests along real
  boundaries: core code with its tests and CI steps, then evals and
  evidence, then figures and the final README. Large systems add pull
  requests per component.
- The work is built to green in a private `<name>-rehearsal` repository.
  The public repository is then created fresh and the finished branches are
  replayed as pull requests in the same order.

## GitHub side

The settings from `scripts/bootstrap-repo.sh` are applied and read back,
the ruleset on main is active, the CI badge is green, and the description
and topics are set.

## Release

When everything above holds, main is tagged `v1.0.0` with a GitHub Release
and a short note. The release is made with `gh release create`, which
creates the tag on the server; the local hooks refuse a tag push.
