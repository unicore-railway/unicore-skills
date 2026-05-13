---
name: zero-to-running-tool
description: Use FIRST when the user is non-technical (PM, finance, legal, ops) or is starting from a fresh laptop. Verifies prerequisites (Node 24, Colima, gh, railway), GitHub org membership, and Railway workspace access before any unicore service scaffolding.
---

# Zero to running tool

Use this skill **before** any other unicore skill when:

- the user identifies as non-engineer (PM, finance, legal, ops, support, etc.)
- the user mentions a clean or new machine
- a prerequisite check (`node -v`, `gh auth status`, `railway whoami`) fails

This skill is a **gate**. Each section ends in a **Verify** block. Run the verify command yourself, read the output, and only continue when it passes. Do not silently move on.

Tone: the user may not know what these tools are. Before each install, give a one-sentence plain-English reason. Do not ask the user to copy-paste anything that you can run for them.

## 0. Detect the platform

```bash
uname -s
```

- `Darwin` → use the macOS commands below (the supported path).
- `Linux` → ask the user which distribution; substitute the right package manager.
- anything else (e.g. Windows) → stop and ask the user how their machine is set up. The unicore defaults assume macOS or Linux.

## 1. Node.js 24 LTS

Why: every unicore service runs on Node 24.

Install via Homebrew on macOS:

```bash
brew install node@24
brew link --overwrite --force node@24
```

If the user already uses `nvm` or `volta`, prefer that toolchain instead and run `nvm install 24` or `volta install node@24`.

**Verify:**

```bash
node -v
npm -v
```

Expect `v24.x` and `11.x` or higher. If `node -v` shows an older major or `command not found`, do not proceed. If `which -a node` shows multiple versions, ask the user which to keep on `PATH`.

## 2. Docker-compatible runtime (Colima on macOS)

Why: local PostgreSQL runs in a container during development. The user does not need to know what Docker is — just that this provides the database.

```bash
brew install colima docker
colima start
```

On Apple-silicon machines that fail to start a VM, retry with native virtualization:

```bash
colima start --vm-type vz
```

**Verify:**

```bash
docker ps
```

Expect a header row with no containers and no error. If you see `Cannot connect to the Docker daemon`, run `colima start` again and re-verify.

## 3. GitHub CLI, SSH key, and `unicore-railway` org access

Why: unicore services live in the [`unicore-railway`](https://github.com/unicore-railway) GitHub org. Without org membership, repo creation fails. SSH keys are required — all Git operations use SSH, not HTTPS.

```bash
brew install gh
```

**Generate an SSH key** (skip if one already exists at `~/.ssh/id_ed25519`):

```bash
ssh-keygen -t ed25519 -C "your.email@uni.tech"
```

When prompted for a passphrase, **set one** — this protects the key if the laptop is lost or compromised. On macOS, add it to Keychain so it survives reboots without re-entering the passphrase every time:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Also add this to `~/.ssh/config` so macOS reloads the key from Keychain automatically after a reboot:

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

**Upload the key to GitHub and configure `gh` to use SSH:**

```bash
gh auth login --git-protocol ssh
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
gh config set git_protocol ssh
```

**Verify auth:**

```bash
gh auth status
ssh -T git@github.com
```

Expect `Hi <username>! You've successfully authenticated` from the `ssh` check.

**Verify org membership:**

```bash
gh api user/orgs --jq '.[].login' | grep -x unicore-railway
```

If this command prints nothing, **stop**. The user is signed in but not in the org. Tell them, in plain language:

> "You're not in the `unicore-railway` GitHub org yet. Email roman.shevchuk@uni.tech and ask to be added. Once you get the invite, accept it and we'll continue."

Do not proceed until the verify command prints `unicore-railway`.

## 4. Railway CLI and **Universe Unicore** workspace

Why: services deploy to the company's paid Railway workspace. Without workspace access, deploys land on a personal plan.

```bash
brew install railway
railway login
```

If the user is on a remote machine over SSH, use the headless variant:

```bash
railway login --browserless
```

**Verify auth:**

```bash
railway whoami
```

**Verify workspace access:**

```bash
railway list
```

Expect the output to include a workspace whose name contains `Unicore` (case-insensitive). If it does not, **stop**. Tell the user:

> "You can sign in to Railway, but you're not in the **Universe Unicore** workspace yet. Email roman.shevchuk@uni.tech to be added. I'll wait."

Do not proceed until a Unicore workspace is visible.

## 5. Final readiness check

Run all four checks one more time:

```bash
node -v
docker ps
gh api user/orgs --jq '.[].login' | grep -x unicore-railway
railway whoami
```

If every command succeeds, the machine is ready.

## 6. Hand off

- Broad request ("build me an internal tool", "set up a new service") → hand off to `building-unicore-tool`.
- Narrow request ("just scaffold the Next.js app", "wire up Okta") → hand off to the matching sub-skill directly.

Tell the user in plain language: "Your machine is set up. I'll now start the project."

## Common failure modes

- **`gh auth login` browser closes early.** Re-run it; choose "Login with a web browser" again. If browser auth keeps failing, fall back to "Paste an authentication token" with a personal access token scoped to `repo` and `read:org`.
- **`colima start` hangs on first run.** First boot can take several minutes while it downloads the VM image. Wait. If it still fails, try `colima delete && colima start --vm-type vz`.
- **`node -v` still shows the old version after install.** Another Node is earlier on `PATH`. Run `which -a node`, then either remove the older one or update the user's shell rc file with a `PATH` adjustment — confirm with the user first.
- **`railway list` shows only a personal workspace.** The org admin invite has not been accepted, or the user signed in to Railway with a different email than the one invited. Have them check both.
- **User is on Windows.** Stop and ask. The unicore baseline assumes macOS or Linux; WSL2 may work for the same commands but is not officially supported.
