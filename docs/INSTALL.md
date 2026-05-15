# Installation

- [Claude Code](#claude-code)
  - [Recommended companion: Railway plugin](#recommended-companion-railway-plugin)
- [Claude Desktop](#claude-desktop)
- [Codex](#codex)
- [Cursor](#cursor)
- [Windsurf](#windsurf)
- [GitHub Copilot](#github-copilot)

## Claude Code

Marketplace install:

```bash
/plugin marketplace add unicore-railway/unicore-skills
/plugin install unicore-skills@unicore-skills
/reload-plugins
```

`/reload-plugins` activates skills immediately without restarting. If skills don't appear after install, run it again.

Local iteration:

```bash
claude --plugin-dir /path/to/unicore-skills
```

The repository includes [.claude-plugin/marketplace.json](../.claude-plugin/marketplace.json) in addition to the plugin manifest.

To update to the latest version:

```bash
/plugin update unicore-skills@unicore-skills
/reload-plugins
```

### Recommended companion: Railway plugin

The official Railway plugin gives agents direct Railway API access (deploy status, logs, env vars, domains). Install it alongside unicore-skills:

```bash
/plugin marketplace add railwayapp/railway-skills
/plugin install railway@railway-skills
```

Then add the Railway MCP server:

```bash
claude mcp add railway-mcp-server -- npx -y @railway/mcp-server
```

Use the Railway plugin for general Railway API queries. Use the unicore `deploying-to-railway` skill for all deployment steps — it enforces company conventions that `use-railway` does not know about.

## Claude Desktop

1. Open Claude Desktop → **Customize** → **Directory** → **Plugins**.
2. Click **Your organization** tab.
3. Add the marketplace using the GitHub repo: `unicore-railway/unicore-skills`.
4. The `unicore-skills` plugin will appear — click **Install**.

The plugin is powered by [.claude-plugin/marketplace.json](../.claude-plugin/marketplace.json). If the plugin doesn't appear after adding the marketplace, remove it and re-add it to force a refresh.

## Codex

Codex uses native skill discovery well with a clone-and-symlink flow. The install instructions live in [.codex/INSTALL.md](../.codex/INSTALL.md).

## Cursor

Cursor has a first-class plugin manifest in [.cursor-plugin/plugin.json](../.cursor-plugin/plugin.json). For private/internal use before marketplace publishing, use repo-local adapters:

```bash
git clone git@github.com:unicore-railway/unicore-skills.git
bash unicore-skills/scripts/install-consumer-adapters.sh /path/to/target-repo
```

That installs:

- `.agents/skills/`
- `.cursor/rules/`
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.windsurf/skills/`

Marketplace and local-install notes live in [.cursor-plugin/INSTALL.md](../.cursor-plugin/INSTALL.md).

## Windsurf

Windsurf supports repo-local and global skills. For a GitHub-distributed repo, you can either:

- commit `.windsurf/skills/` into the target repo
- use the adapter installer above
- or clone/copy the `.agents/skills/` or `.windsurf/skills/` folders into a workspace

## GitHub Copilot

Copilot uses repository files, not a separate plugin installer. The adapter installer above copies the needed files into the target repo.
