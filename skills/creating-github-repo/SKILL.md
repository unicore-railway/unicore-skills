---
name: creating-github-repo
description: Use when publishing a new unicore service to GitHub. Covers private repo creation under unicore-railway, the single-branch workflow, and the commit message convention.
---

# Creating the GitHub repo

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

The `--private` flag is required.
The `git branch -M main` step is also required so Railway auto-deploy targets the same default branch.

## Single `main` branch — no PRs, no CI

These are vibe-coded internal tools, often built by non-engineers. The workflow is intentionally simple:

- All work goes directly on `main`.
- No feature branches, no pull requests, no branch protection.
- No GitHub Actions CI — **Railway is the only deploy gate.**

**How is bad code caught then?** Railway runs `npm run build` on every push to `main` as part of its deploy pipeline. If the build fails, the new version doesn't go live and the previous deploy keeps serving traffic. That is the safety net.

To avoid wasting Railway deploys on broken builds, **run the local checks before pushing**:

```bash
npm run typecheck && npm run lint && npm run test && npm run build
```

If all four pass locally, the Railway deploy will almost always succeed.

## Commit message convention

Use [Conventional Commits](https://www.conventionalcommits.org/): a short prefix that names the *kind* of change, then a one-line summary in the imperative tense ("add", not "added").

The four prefixes you will actually use:

- `feat:` — a new feature, page, or capability the user can see
- `fix:` — a bug fix
- `chore:` — maintenance: scaffolding, dependency bumps, config tweaks, internal refactors with no user-facing change
- `docs:` — README, code comments, or other documentation

**Examples:**

```text
feat: add vendor onboarding form
fix: handle missing Okta email claim gracefully
chore: bump prisma to 5.20
docs: explain how to add a health check
```

**Rules of thumb:**

- Keep the subject line under ~70 characters.
- Use the imperative tense ("add", not "added" or "adds").
- One commit = one logical change. If you find yourself writing "and" in the subject, split the commit.
- Skip the body for trivial commits. For non-trivial ones, add a short paragraph explaining *why* the change was needed.

This convention is unenforced — there is no commit-lint hook — but agents and reviewers should follow it. Consistent prefixes make `git log` readable and make it easy to spot what changed in any given window.

## Day-to-day workflow

Once the service is live, the recurring loop for shipping a change is:

1. **Keep `npm run dev` running** in one terminal. It hot-reloads on save and serves at `http://localhost:3000` — that is your live preview. Open the browser side-by-side with your editor.

2. **Edit and save.** Watch the preview to confirm the change actually works before recording it in git. Use the dev server as a safety check, not just a final demo.

3. **Run the local checks** when you have a logical chunk ready (or right before pushing — pick one habit and stick with it):

   ```bash
   npm run typecheck && npm run lint && npm run test && npm run build
   ```

   Skipping this is the most common cause of failed Railway deploys.

4. **Commit** with a Conventional Commits prefix (see the section above):

   ```bash
   git add -A
   git commit -m "feat: add vendor onboarding form"
   ```

5. **Push to GitHub:**

   ```bash
   git push
   ```

   ⚠️ **`git push` is the deploy.** There is no staging environment in this workflow. The moment the commit lands on `main`, Railway pulls it, runs `npm run build`, and — if the build succeeds and `/api/health` returns `200` — replaces the live version. If anything fails, the previous deploy keeps serving and you'll see a red status in the Railway dashboard.

6. **Watch the deploy** in the Railway dashboard's deploy log for ~30–90 seconds. A green deploy plus a healthy `/api/health` means production is now serving your change.

If you want to commit work-in-progress without deploying it, that is fine — local commits are private until you `git push`. You can stack several commits locally and push them together as a batch.
