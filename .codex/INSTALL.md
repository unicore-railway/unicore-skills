# Installing unicore-skills for Codex

Enable `unicore-skills` in Codex through native skill discovery.

## Installation

1. Clone the repository:

```bash
git clone https://github.com/unicore-railway/unicore-skills.git ~/.codex/unicore-skills
```

2. Create the discovery symlink:

```bash
mkdir -p ~/.agents/skills
ln -s ~/.codex/unicore-skills/skills ~/.agents/skills/unicore-skills
```

Windows (PowerShell):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\unicore-skills" "$env:USERPROFILE\.codex\unicore-skills\skills"
```

3. Restart Codex.

## Verify

```bash
ls -la ~/.agents/skills/unicore-skills
```

You should see a symlink or junction that points to `~/.codex/unicore-skills/skills`.

## Updating

```bash
cd ~/.codex/unicore-skills
git pull
```

The discovered skills update through the same symlink.
