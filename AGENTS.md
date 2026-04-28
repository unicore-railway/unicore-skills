# unicore-skills

This repository packages internal engineering playbooks for multiple AI coding tools.

## Source of truth

- Canonical playbooks live in `skills/<topic>/SKILL.md`.
- Tool-specific adapters live in:
  - `.claude-plugin/`
  - `.codex-plugin/`
  - `.cursor/rules/`
  - `.windsurf/skills/`
  - `.github/`

## Editing rules

- Update canonical skill files before updating adapters.
- Keep YAML frontmatter valid and stable.
- Prefer portable guidance in canonical skills and tool-specific behavior in adapter files.
- Keep repository documentation aligned when a workflow changes materially.

## Current playbooks

- `skills/zero-to-running-tool/SKILL.md`: run first for non-technical users or fresh machines — installs prerequisites and verifies access
- `skills/building-unicore-tool/SKILL.md`: orchestrate the full zero-to-production workflow
- `skills/bootstrapping-nextjs-service/SKILL.md`: scaffold the app, env validation, health endpoint, and frontend defaults
- `skills/setting-up-prisma-postgres/SKILL.md`: add PostgreSQL, Prisma, migrations, and the DB health check
- `skills/setting-up-nextauth-okta/SKILL.md`: add Okta SSO via Auth.js v5, the auth health check, and local env defaults
- `skills/setting-up-trpc/SKILL.md`: add tRPC v11 + TanStack Query — the only sanctioned client/server layer for app-internal endpoints
- `skills/creating-github-repo-and-ci/SKILL.md`: publish the repo and add CI
- `skills/deploying-to-railway/SKILL.md`: configure Railway, production variables, and the custom domain
