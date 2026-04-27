---
name: creating-github-repo-and-ci
description: Use when a new unicore service needs its GitHub repository, branching rules, and required CI verification checks.
---

# Creating the GitHub repo and CI

Use this skill once the local project structure is ready to publish.

## Create the repository

```bash
git init
git add -A
git commit -m "chore: initial commit"
gh repo create universe-unicore/my-service \
  --private \
  --source=. \
  --remote=origin \
  --push
```

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
  verify:
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
      - run: npm run lint
      - run: npm run test
      - run: npm run build
```

Keep each verification step separate so it can be marked as a required status check.
