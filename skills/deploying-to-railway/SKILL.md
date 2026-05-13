---
name: deploying-to-railway
description: Use when a unicore service is ready to connect to Railway, configure production settings, and attach its railway.unicore-tools.io domain.
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

## Create the Railway project

In Railway:

1. Create a new project and connect it to the GitHub repo `unicore-railway/my-service` (not an empty project — connect the repo immediately).
2. Let Railway create the `web` service.
3. Add a PostgreSQL service in the same Railway project.

Keep `web` and `postgres` in one Railway project.

## Create the production Okta app

A **separate** Okta app for production. Never reuse the dev app's credentials in prod — the redirect URIs differ, and rotating one shouldn't take down the other. Same two-path approach as in `setting-up-nextauth-okta`.

### If you are not the Okta admin

Send the admin this request, replacing `<service-name>`:

> Hi, I need a production Okta OIDC Web Application for `<service-name>`. Settings:
>
> - **App name**: `<service-name> (prod)`
> - **App type**: OIDC — Web Application
> - **Sign-in redirect URI**: `https://<service-name>.railway.unicore-tools.io/api/auth/callback/okta`
> - **Sign-out redirect URI**: `https://<service-name>.railway.unicore-tools.io`
> - **Assigned group**: the internal unicore group used for internal tools (same group as the dev app)
>
> Please send the **Client ID** and **Client Secret** through 1Password / Bitwarden — secret is sensitive.

When the admin replies, paste the values directly into Railway's variables UI for the `web` service (see the next section). Do not store the production Client Secret in any repo file — Railway is the only source of truth.

### If you are the Okta admin

Repeat the dev-app steps from `setting-up-nextauth-okta` with these differences:

- App integration name: `<service-name> (prod)`
- Sign-in redirect URI: `https://<service-name>.railway.unicore-tools.io/api/auth/callback/okta`
- Sign-out redirect URI: `https://<service-name>.railway.unicore-tools.io`

Send the Client ID and Client Secret through a secure channel.

## Production variables

Set these on the `web` service:

| Key | Value |
| --- | --- |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `AUTH_SECRET` | fresh `openssl rand -base64 32` output |
| `AUTH_URL` | `https://<service>.railway.unicore-tools.io` |
| `AUTH_TRUST_HOST` | `true` (Railway terminates TLS in front of the app) |
| `OKTA_CLIENT_ID` | production Okta app client ID |
| `OKTA_CLIENT_SECRET` | production Okta app client secret |
| `OKTA_ISSUER` | `https://universe.okta.com` |

Railway variables are the source of truth for production secrets. Names follow the Auth.js v5 convention (`AUTH_*`); the legacy `NEXTAUTH_*` names are no longer used.

## Build and start commands

Use:

- Build: `npm ci && npx prisma generate && npx prisma migrate deploy && npm run build`
- Start: `npm start`

`prisma migrate deploy` is expected on each deploy.

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

1. Add `<service>.railway.unicore-tools.io` as a custom domain.
2. Create the CNAME record in the `unicore-tools.io` DNS zone.
3. Wait for the certificate to issue.
4. Confirm `AUTH_URL` and the production Okta callback URLs match the custom domain.

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
