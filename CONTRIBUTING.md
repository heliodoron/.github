# Contributing

These rules apply to every repository in the Heliodoron organization. They
exist so that each history reads as a record of deliberate, reviewed work.

## Who can contribute

The repositories are maintained by Heliodoron. Pull requests and issues from
outside the organization are not open. For questions, see `SUPPORT.md`. To
report a vulnerability, see `SECURITY.md`.

## How changes land

The first commit of a repository is its scaffold: either a scaffold pushed
once, or the "Initial commit" GitHub writes when a repository is created from
the template. Every change after that is a pull request, and every pull
request follows this standard.

## One intent per pull request

A pull request does one thing. The test is the diff, not the title: if
removing any file would leave a pull request that still makes sense on its
own for a different reason, it is two pull requests.

## Title

The title is a conventional commit subject and becomes the squash commit on
main:

    <type>(<optional scope>): <what changed>

- Types: feat, fix, docs, refactor, chore, test, perf.
- The text after the colon is 3 to 72 characters, starts with a lowercase
  letter or a digit, and has no full stop at the end.
- It describes the change, never a tracker step or a ticket number alone.

Examples: `docs: add the architecture figure`, `test: cover the retry path`.

## Description

Four sections, from the pull request template:

- What changed: at most three bullets.
- Why: one or two lines.
- How verified: the commands run and their result, or "not verified",
  stated plainly.
- Seen, not touched: unrelated issues noticed. Omitted when empty.

The description becomes the body of the squash commit, so it is written as
plain text that reads well in `git log`.

## Branches and merging

- Branch names: `<type>/<slug>`, for example `docs/architecture-figure`.
- Squash merge only; the branch is deleted on merge.
- A pull request cannot be deleted, only closed, and a closed one stays
  visible. So a change is reviewed before its pull request opens. The pull
  request opens only when it is ready to merge, and it is merged in the same
  pass. Work in progress stays local.

## Checks

Every pull request runs the shared checks (title format, ASCII punctuation)
and the repository's own CI. Main accepts a merge only when both pass.

## Automated pull requests

Dependabot opens pull requests for GitHub Actions version updates and for
security updates. These are the one exception to review before opening: they
are reviewed after they open. Their titles use the `chore` type, and their
`dependabot/` branch names are exempt from the branch rule. Their generated
description is long HTML, so they are merged with a short written commit
body instead of the description.

## Local setup

Each repository carries its git hooks in `.githooks/`. Turn them on once per
clone:

    git config core.hooksPath .githooks

The hooks check the commit subject format, refuse generated-by and co-author
trailers, check branch names, and refuse a direct push to main.

## Writing

ASCII punctuation only. Plain verbs, short sentences. No generated-by or
co-author trailers.
