---
name: deploying-to-railway
description: Use when a unicore service is ready to connect to Railway, configure production settings, and attach its unicore-railway.io domain.
---

# Deploying to Railway

Use this skill when the repository, database, and auth wiring are ready and the service needs a production deployment.

## Prerequisites

You must be a member of the **Universe Unicore** Railway workspace (the company's paid plan). All unicore services live there.

If you don't have access yet, ask **Roman Shevchuk** (`roman.shevchuk@uni.tech`) to add you to the workspace.

Make sure the **Universe Unicore** workspace is selected in Railway before creating the project — otherwise the project lands in a personal workspace and won't be on the paid plan.

## Deployment method — always GitHub-connected

**Never use `railway up`.** That command uploads files directly from your local machine and bypasses the GitHub-connected deploy pipeline. It breaks auto-deploy, leaves no audit trail in git, and is easy to forget to run when things change.

The only sanctioned deploy path is:
1. Push to `main` on GitHub.
2. Railway detects the push and runs the build automatically.

This means the Railway service **must be connected to the GitHub repo before the first real deploy**.

## Naming

The Railway project name must match the GitHub repo name exactly (e.g. if the repo is `unicore-railway/vendor-portal`, the Railway project is also `vendor-portal`). This keeps the two in sync and makes it obvious which Railway project belongs to which repo.

## Create the Railway project

```bash
railway init --name <service-name>
railway add --database postgresql
```

**Connect the GitHub repo via the Railway dashboard** — the CLI (`railway add --repo`) fails with an auth error because the Railway token doesn't carry the GitHub OAuth scope. In the dashboard: open the project → Add Service → GitHub Repo → select `unicore-railway/<service-name>`.

Keep `web` and `postgres` in one Railway project.

## Verify the Okta app redirect URI

The Okta app was created in `setting-up-nextauth-okta` with the production redirect URI already included. Before deploying, confirm the app's sign-in redirect URIs contain:

```
https://<service-name>.unicore-railway.io/api/auth/callback/okta
```

If the production URL changed (e.g. a custom domain was chosen instead of the default), update the Okta app's redirect URIs to match. The Okta admin can edit them in Applications → `<service-name>` → General → **Edit**.

## Production variables

Set these on the `web` service:

| Key | Value |
| --- | --- |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `AUTH_SECRET` | fresh `openssl rand -base64 32` output |
| `AUTH_URL` | `https://<service>.unicore-railway.io` |
| `AUTH_TRUST_HOST` | `true` (Railway terminates TLS in front of the app) |
| `OKTA_CLIENT_ID` | from the shared Okta app (same as dev) |
| `OKTA_CLIENT_SECRET` | from the shared Okta app (same as dev) |
| `OKTA_ISSUER` | `https://universe.okta.com` |

Railway variables are the source of truth for production secrets. Names follow the Auth.js v5 convention (`AUTH_*`); the legacy `NEXTAUTH_*` names are no longer used.

## Build and start commands

Use:

- Build: `npm ci && npm run build` — for services without Prisma
- Build: `npm ci && npx prisma generate && npx prisma migrate deploy && npm run build` — for services with Prisma
- Start: `npm start`

Use the Prisma build command only when the service has a database. `prisma migrate deploy` is expected on each deploy.

## Auto-deploy

- Deploy automatically on pushes to `main` — this is the **only** deploy mechanism
- Use production only
- Do not create staging or preview environments by default
- Never use `railway up` — see "Deployment method" above

## Healthcheck

Configure the Railway `web` service to use `/api/health` as its healthcheck path.

This endpoint is defined in `bootstrapping-nextjs-service` and extended by every dependency skill (`setting-up-prisma-postgres`, `setting-up-nextauth-okta`). It returns:

- `200` with `{ status: 'ok' | 'degraded', checks: [...] }` when the app and every registered dependency are reachable
- `503` with `{ status: 'down', checks: [...] }` when any dependency is `down`

Railway uses this signal to gate traffic during deploys — a failed healthcheck keeps the previous version serving instead of replacing it with a broken one.

## Custom domain

`unicore-railway.io` is purchased and managed by Railway, so DNS is handled automatically — no manual CNAME step needed.

**Custom domain management requires workspace admin access.** The CLI (`railway domain`) fails with an auth error for non-owners. Use the Railway dashboard: open the service → Settings → Domains → Add Domain → enter `<service-name>.unicore-railway.io`.

Wait for the certificate to issue, then confirm `AUTH_URL` and the production Okta callback URLs match the custom domain.

Once the domain is live, add the production URL and Railway project link to the top of the project's `README.md`:

```markdown
**Production:** https://<service-name>.unicore-railway.io
**Railway:** https://railway.com/project/<projectId>/service/<serviceId>?environmentId=<environmentId>
```

Get the IDs from the CLI:

```bash
railway status
```

This prints the project ID, service ID, and environment ID for the linked service. The Railway link gives any developer a one-click jump to logs, variables, and deploy history without hunting through the dashboard.

Commit and push:

```bash
git add README.md
git commit -m "docs: add production URL and Railway project link"
git push
```

## Logging baseline

Current observability baseline:

- `console.log`
- `console.error`
- Railway deploy logs
- Railway live logs

Not standardized yet:

- Sentry
- external structured log shipping
- uptime monitoring
