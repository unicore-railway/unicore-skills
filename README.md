# unicore-skills

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
| [`creating-github-repo-and-ci`](skills/creating-github-repo-and-ci/SKILL.md) | Publishing the repo to GitHub and adding the required CI checks. |
| [`deploying-to-railway`](skills/deploying-to-railway/SKILL.md) | Connecting the service to Railway, configuring production settings, and attaching the custom domain. |

## Install from GitHub

Detailed platform notes:

- Codex: [docs/README.codex.md](/Users/romanshevchuk/Projects/unicore-skills/docs/README.codex.md)
- Cursor: [docs/README.cursor.md](/Users/romanshevchuk/Projects/unicore-skills/docs/README.cursor.md)
- Architecture: [docs/ARCHITECTURE.md](/Users/romanshevchuk/Projects/unicore-skills/docs/ARCHITECTURE.md)

### Claude Code

Marketplace install:

```bash
/plugin marketplace add unicore-railway/unicore-skills
/plugin install unicore-skills@unicore-railway
```

Local iteration:

```bash
claude --plugin-dir /path/to/unicore-skills
```

This now works because the repository includes [.claude-plugin/marketplace.json](/Users/romanshevchuk/Projects/unicore-skills/.claude-plugin/marketplace.json) in addition to the plugin manifest.

### Codex

Codex uses native skill discovery well with a clone-and-symlink flow. The install instructions live in [.codex/INSTALL.md](/Users/romanshevchuk/Projects/unicore-skills/.codex/INSTALL.md).

### Cursor

Cursor now has a first-class plugin manifest in [.cursor-plugin/plugin.json](/Users/romanshevchuk/Projects/unicore-skills/.cursor-plugin/plugin.json). For private/internal use before marketplace publishing, use repo-local adapters:

```bash
git clone https://github.com/unicore-railway/unicore-skills.git
bash unicore-skills/scripts/install-consumer-adapters.sh /path/to/target-repo
```

That installs:

- `.agents/skills/`
- `.cursor/rules/`
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.windsurf/skills/`

Marketplace and local-install notes live in [.cursor-plugin/INSTALL.md](/Users/romanshevchuk/Projects/unicore-skills/.cursor-plugin/INSTALL.md).

### Windsurf

Windsurf supports repo-local and global skills. For a GitHub-distributed repo, you can either:

- commit `.windsurf/skills/` into the target repo
- use the adapter installer above
- or clone/copy the `.agents/skills/` or `.windsurf/skills/` folders into a workspace

### GitHub Copilot

Copilot uses repository files, not a separate plugin installer. The adapter installer above copies the needed files into the target repo.

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
