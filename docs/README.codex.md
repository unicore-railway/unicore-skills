# unicore-skills for Codex

## Quick install

Tell Codex:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/universe-unicore/unicore-skills/main/.codex/INSTALL.md
```

## How it works

Codex discovers skills through `~/.agents/skills/`. The install flow clones this repository and exposes the shared `skills/` directory through a symlink:

```text
~/.agents/skills/unicore-skills -> ~/.codex/unicore-skills/skills
```

That means the canonical skills stay in one place and update with a normal `git pull`.
