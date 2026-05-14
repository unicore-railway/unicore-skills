# unicore-skills

**[Installation →](docs/INSTALL.md)**

Reusable internal engineering playbooks for the **Universe Group** Head Office (`unicore`), packaged so the same guidance can be consumed by multiple AI coding tools.

Scope: this org ([`unicore-railway`](https://github.com/unicore-railway)) is dedicated to internal company projects that are **vibe-coded** and **hosted on Railway**. Skills here encode the conventions, defaults, and access flows specific to that setup.

The repo follows a **shared core + platform shims** model:

- Canonical process guides live in `skills/<topic>/SKILL.md`
- Per-tool manifests and install docs point back to the same shared content
- When the guidance changes, update the canonical skill first and sync the shims second

## Access

Both the GitHub org and the Railway workspace are paid and invite-only. Before scaffolding a service, get added to:

1. **GitHub org**: [`unicore-railway`](https://github.com/unicore-railway)
2. **Railway workspace**: **Universe Unicore**

Ask **Roman Shevchuk** (`roman.shevchuk@uni.tech`) to add you to the GitHub org and Railway workspace. Joining the workspace is the only way to deploy on the company's paid Railway plan.

## Supported tools

| Tool | Repo integration |
| --- | --- |
| Claude Code | `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` + `skills/` |
| Codex | `.codex-plugin/plugin.json` + `.codex/INSTALL.md` + `skills/` |
| Cursor | `.cursor-plugin/plugin.json` + `.cursor/rules/*.mdc` + `AGENTS.md` |
| Windsurf | `.windsurf/skills/*/SKILL.md` + `.agents/skills/*/SKILL.md` |
| GitHub Copilot | `.github/copilot-instructions.md` + `AGENTS.md` |

## Repository layout

```text
.
├── skills/                     # Canonical skill content
├── .claude-plugin/             # Claude Code manifest
├── .codex-plugin/              # Codex manifest
├── .codex/                     # Codex install docs
├── .cursor-plugin/             # Cursor manifest and install docs
├── .agents/skills/             # Generic Agent Skills adapter
├── .cursor/rules/              # Cursor project rules
├── .windsurf/skills/           # Windsurf workspace skills
├── .github/                    # GitHub Copilot instructions
├── docs/                       # Tool-specific integration notes
├── scripts/                    # Helper scripts for consumer repos
├── AGENTS.md                   # Cross-tool repo instructions
└── CLAUDE.md                   # Contributor notes for Claude-style agents
```

## Current skills

| Skill | What it covers |
| --- | --- |
| [`zero-to-running-tool`](skills/zero-to-running-tool/SKILL.md) | Run first for non-technical users or fresh machines. Installs Node 24, Colima, `gh`, and Railway CLI, and verifies GitHub org and Railway workspace access. |
| [`building-unicore-tool`](skills/building-unicore-tool/SKILL.md) | Top-level orchestrator for taking a new internal unicore tool from zero to production on Railway. Replaces the old `bootstrapping-unicore-service` and `new-project-to-railway` skills. |
| [`bootstrapping-nextjs-service`](skills/bootstrapping-nextjs-service/SKILL.md) | Scaffolding a new service with Next.js, TypeScript, lint, formatting, test defaults, `zod`-validated env, and the `/api/health` aggregator. |
| [`setting-up-prisma-postgres`](skills/setting-up-prisma-postgres/SKILL.md) | Adding local PostgreSQL, Prisma, the initial schema, migration scripts, and the database health check. |
| [`setting-up-nextauth-okta`](skills/setting-up-nextauth-okta/SKILL.md) | Adding Okta SSO via Auth.js v5 (`@auth/prisma-adapter`), the auth health check, plus local env and onboarding defaults. |
| [`setting-up-trpc`](skills/setting-up-trpc/SKILL.md) | Adding tRPC v11 + TanStack Query as the only sanctioned client/server layer for app-internal endpoints. |
| [`creating-github-repo`](skills/creating-github-repo/SKILL.md) | Publishing the repo to GitHub under `unicore-railway` (always private), the single-`main`-branch workflow (no PRs, no CI — Railway is the only deploy gate), and the Conventional Commits message convention. |
| [`deploying-to-railway`](skills/deploying-to-railway/SKILL.md) | Connecting the service to Railway, configuring production settings, and attaching the custom domain. |

## Reliable triggering

These skills under-trigger on conversational prompts. When a user says "build me a tool for the ops team", Claude often starts scaffolding directly instead of consulting the skill catalog — even when the description matches. Name the skill explicitly to guarantee the right playbook loads:

- New internal unicore tool from scratch: "use `building-unicore-tool` to set up a new service".
- Fresh machine or non-technical user: "use `zero-to-running-tool` first".
- Narrower mid-build task: name the sub-skill (`bootstrapping-nextjs-service`, `setting-up-prisma-postgres`, `setting-up-nextauth-okta`, `setting-up-trpc`, `creating-github-repo`, `deploying-to-railway`).

To get this priming automatically without remembering the skill name, add one line to your `~/.claude/CLAUDE.md`:

```markdown
When scaffolding a new internal service for Universe Group (unicore-railway / Railway-hosted), consult the `building-unicore-tool` skill before writing any code.
```

This was confirmed against a 20-query trigger eval: even the literal phrasing in the original description fired only 0–33% of the time on realistic prompts. The eval set and results live under [evals/building-unicore-tool/](/Users/romanshevchuk/Projects/unicore-skills/evals/building-unicore-tool/).

## Adding a new guide

1. Create `skills/<topic-slug>/SKILL.md`.
2. Add YAML frontmatter at the top. Keep `description` concrete and trigger-friendly:

   ```yaml
   ---
   name: <topic-slug>
   description: Use when <situation>. Covers <key topics>.
   ---
   ```

3. Add or update adapters for the supported tools:
   - Claude Code: usually none beyond the shared `skills/` folder
   - Codex: usually none beyond the shared `skills/` folder
   - Codex install notes: update `.codex/INSTALL.md` when the install flow changes
   - Generic agent ecosystems: add or update `.agents/skills/<topic-slug>/SKILL.md`
   - Cursor packaging: update `.cursor-plugin/plugin.json` if the plugin surface changes
   - Cursor: add or update `.cursor/rules/*.mdc`
   - Windsurf: add or update `.windsurf/skills/<topic-slug>/SKILL.md`
   - GitHub Copilot: update `.github/copilot-instructions.md` or `AGENTS.md` if needed
4. Bump plugin versions when packaging changes:
   - `.claude-plugin/plugin.json`
   - `.codex-plugin/plugin.json`
5. Open a PR or commit according to the workflow documented in the skill itself.
