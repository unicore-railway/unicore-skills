---
name: creating-github-repo-and-ci
description: Use when a new unicore service needs its GitHub repository, branching rules, and required CI verification checks.
---

# Creating the GitHub repo and CI

Use this skill once the local project structure is ready to publish.

## Visibility — always private

**All service repos under [`unicore-railway`](https://github.com/unicore-railway) must be created as private.** This is non-negotiable.

Why:

- Repos reference internal Okta apps, internal domains (`*.railway.unicore-tools.io`), and Railway service names.
- They may contain references to internal data models, internal users, and access patterns.
- Public visibility is reserved for clearly intended OSS work (e.g. this `unicore-skills` repo) — service repos are not that.

Never run `gh repo create ... --public` for a `unicore-railway` service repo, and don't toggle visibility to public after the fact. If you genuinely need a public repo, raise it with **Roman Shevchuk** before creating.

## Create the repository

```bash
git init
git branch -M main
git add -A
git commit -m "chore: initial commit"
gh repo create unicore-railway/my-service \
  --private \
  --source=. \
  --remote=origin \
  --push
```

The `--private` flag is required — every example in this guide assumes it.
The `git branch -M main` step is also required so CI, Railway auto-deploy, and branch protection all target the same default branch.

## Branching rules

Default policy:

- Early stage: direct commits to `main` are acceptable while the project is still taking shape
- Once the service has real users or multiple contributors: switch to PR-only on `main`

To tighten protection later:

1. Open repo settings for `main`.
2. Require a pull request before merging.
3. Require status checks.
4. Optionally require review.

The required checks should be:

- `typecheck`
- `lint`
- `test`
- `build`

## CI workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v6
        with:
          node-version: 24
          cache: npm

      - run: npm ci

      - run: npx prisma generate

      - run: npm run typecheck

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v6
        with:
          node-version: 24
          cache: npm

      - run: npm ci

      - run: npx prisma generate

      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v6
        with:
          node-version: 24
          cache: npm

      - run: npm ci

      - run: npx prisma generate

      - run: npm run test

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v6
        with:
          node-version: 24
          cache: npm

      - run: npm ci

      - run: npx prisma generate

      - run: npm run build
```

This produces four separate required status checks:

- `typecheck`
- `lint`
- `test`
- `build`
