# .github

How the Heliodoron organization runs its repositories. Every repository
follows the same standard, and this repository is where that standard lives.

## What is here

| Path | Purpose |
|---|---|
| `CONTRIBUTING.md` | The pull request standard: one intent, title format, squash merge, review before opening |
| `SECURITY.md` | How to report a vulnerability |
| `SUPPORT.md` | Where questions go |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1 |
| `.github/pull_request_template.md` | The four sections of every pull request |
| `.github/workflows/shared-checks.yml` | The reusable checks every repository calls |
| `docs/definition-of-done.md` | What a repository must hold before it is tagged `v1.0.0` |
| `scripts/bootstrap-repo.sh` | Creates a repository from the template and applies the settings |
| `scripts/clean-copy-gate.sh` | The local gate run before every pull request |

The first five are GitHub default community health files: they apply to
every repository in the organization that has no file of its own.

## How a change reaches main

1. The change is reviewed before its pull request opens, because a pull
   request can be closed but never deleted.
2. The pull request runs two required statuses: `checks` (title format,
   typographic characters, forbidden files, large files) and the
   repository's own `ci`.
3. It is squash merged. The title becomes the commit subject and the
   description becomes the commit body. The branch is deleted.

Main is protected by a ruleset: no deletion, no force push, pull requests
only, both statuses required, linear history.

## Versions

The shared checks are versioned with tags on this repository. Each
repository pins the workflow to a commit SHA, and Dependabot moves the pin
when a new version is tagged. Dependabot waits three days after a release
before it proposes it, so an urgent fix is pinned by hand in a normal pull
request.

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE).
