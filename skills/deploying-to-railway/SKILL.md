---
name: deploying-to-railway
description: Use when a unicore service is ready to connect to Railway, configure production settings, and attach its railway.unicore-tools.io domain.
---

# Deploying to Railway

Use this skill when the repository, database, and auth wiring are ready and the service needs a production deployment.

## Create the Railway project

In Railway:

1. Create a new project from the GitHub repo `universe-unicore/my-service`.
2. Let Railway create the `web` service.
3. Add a PostgreSQL service in the same Railway project.

Keep `web` and `postgres` in one Railway project.

## Create the production Okta app

Create a second OIDC Web Application:

- Sign-in redirect: `https://<service>.railway.unicore-tools.io/api/auth/callback/okta`
- Sign-out redirect: `https://<service>.railway.unicore-tools.io`

## Production variables

Set these on the `web` service:

| Key | Value |
| --- | --- |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `NEXTAUTH_SECRET` | fresh `openssl rand -base64 32` output |
| `NEXTAUTH_URL` | `https://<service>.railway.unicore-tools.io` |
| `OKTA_CLIENT_ID` | production Okta app client ID |
| `OKTA_CLIENT_SECRET` | production Okta app client secret |
| `OKTA_ISSUER` | `https://universe.okta.com` |

Railway variables are the source of truth for production secrets.

## Build and start commands

Use:

- Build: `npm ci && npx prisma generate && npx prisma migrate deploy && npm run build`
- Start: `npm start`

`prisma migrate deploy` is expected on each deploy.

## Auto-deploy

- Deploy automatically on pushes to `main`
- Use production only
- Do not create staging or preview environments by default

## Custom domain

1. Add `<service>.railway.unicore-tools.io` as a custom domain.
2. Create the CNAME record in the `unicore-tools.io` DNS zone.
3. Wait for the certificate to issue.
4. Confirm `NEXTAUTH_URL` and the production Okta callback URLs match the custom domain.

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
