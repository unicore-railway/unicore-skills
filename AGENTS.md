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

- `skills/bootstrapping-unicore-service/SKILL.md`: orchestrate the full zero-to-production workflow
- `skills/new-project-to-railway/SKILL.md`: Railway-specific alias for the top-level orchestrator
- `skills/bootstrapping-nextjs-service/SKILL.md`: scaffold the app and local frontend defaults
- `skills/setting-up-prisma-postgres/SKILL.md`: add PostgreSQL, Prisma, and migrations
- `skills/setting-up-nextauth-okta/SKILL.md`: add Okta SSO, NextAuth, and local env defaults
- `skills/creating-github-repo-and-ci/SKILL.md`: publish the repo and add CI
- `skills/deploying-to-railway/SKILL.md`: configure Railway, production variables, and the custom domain
