---
name: setting-up-nextauth-okta
description: Use when adding auth, login, logout, registration, or access control to a unicore service. Covers Okta SSO via Auth.js (NextAuth v5), local env setup, and onboarding steps. Triggers on "add login", "restrict access", "only logged-in users", "add authentication", or any request to protect pages or routes.
---

# Setting up Auth.js (NextAuth v5) and Okta

Use this skill when the service needs unicore-standard authentication.

_Last verified against Auth.js v5 (`next-auth@5.x` / `@auth/prisma-adapter`) tooling: **2026-04-28**._

## Baseline auth policy

The default unicore policy is:

- Okta is the identity provider
- the app uses Okta to authenticate users, then relies on its own server-side session
- the app does not assume Okta access tokens or refresh tokens are available for downstream API calls
- logout signs the user out of the app first; federated Okta logout is optional and should be added only when there is a clear product need

This keeps the baseline simple:

- local app sessions are the source of truth for whether the user is signed in to the app
- Okta is the source of truth for identity
- provider-token lifecycle management is out of scope unless the app explicitly needs it

## Why Auth.js v5

The unicore baseline is on Auth.js v5 (`next-auth@5.x` + `@auth/prisma-adapter`). The legacy `@next-auth/prisma-adapter` package is no longer used. v5 changes that matter for this skill:

- Provider, adapter, and session config moved into a single `NextAuth(config)` call that returns `{ handlers, auth, signIn, signOut }`.
- Server-side session checks use `auth(req, res)` instead of `getServerSession(req, res, authOptions)`.
- Env vars renamed: `NEXTAUTH_SECRET` → `AUTH_SECRET`, `NEXTAUTH_URL` → `AUTH_URL`.
- The auth route handler is App-Router-style. The unicore stack is otherwise Pages Router; this one route is the only App Router file in the project.

## Create the dev Okta app

The unicore policy is **one Okta app per environment per service**: a separate dev (local) app and a separate prod app, never shared. This section creates the dev one. The prod app comes later, in `deploying-to-railway`.

Three values end up in `.env.local` from this step:

- `OKTA_CLIENT_ID`
- `OKTA_CLIENT_SECRET` — sensitive; treat like a password
- `OKTA_ISSUER` — for unicore this is always `https://universe.okta.com` (the default Okta authorization server for the `universe` org; no custom auth server is used)

How you obtain the Client ID and Client Secret depends on whether you have Okta admin rights.

### If you are not the Okta admin (most users)

PMs, finance, legal, and ops typically do **not** have admin rights on `universe.okta.com`. Send the Okta admin a request like this — copy, paste, replace `<service-name>`:

> Hi, I'm setting up a new internal unicore service called `<service-name>`. Could you create an Okta OIDC Web Application for it with these settings?
>
> - **App name**: `<service-name> (dev)`
> - **App type**: OIDC — Web Application
> - **Sign-in redirect URI**: `http://localhost:3000/api/auth/callback/okta`
> - **Sign-out redirect URI**: `http://localhost:3000`
> - **Assigned group**: the internal unicore group you normally use for internal tools
>
> Please send me the **Client ID** and **Client Secret** through 1Password / Bitwarden (or another secure channel) — the secret is sensitive, please not plaintext Slack or email.

Who to ask: the Okta admin at Universe Group is typically someone on the IT or security team. If you don't know who, ask **Roman Shevchuk** (`roman.shevchuk@uni.tech`) and he'll route you to the right person.

When the admin replies, paste the Client ID and Client Secret into `.env.local`. Don't commit them — `.env*.local` is gitignored already.

### If you are the Okta admin

In the Okta admin console for the `universe` org:

1. Applications → Applications → **Create App Integration**.
2. Sign-in method: **OIDC — OpenID Connect**.
3. Application type: **Web Application**. Click **Next**.
4. App integration name: `<service-name> (dev)`.
5. Sign-in redirect URI: `http://localhost:3000/api/auth/callback/okta`.
6. Sign-out redirect URI: `http://localhost:3000`.
7. **Assignments** → assign the internal unicore group used for internal tools.
8. Click **Save**.
9. On the app's **General** tab, copy the **Client ID** and reveal/copy the **Client secret**.
10. Send both values to the requester through a secure channel (1Password / Bitwarden / encrypted note), never plaintext Slack or email.

The sign-out redirect URI exists so the app can support RP-initiated logout later if needed. It is not a requirement to perform federated logout in the baseline flow.

## Local Okta alternative — Keycloak

If Okta dev credentials aren't available yet (new team member waiting on Okta app creation, working offline, or want a fully self-contained local setup), use **Keycloak** as a drop-in OIDC replacement. Same OIDC flow, same env vars, no Okta account needed.

Keycloak is preferred over simpler mock OIDC servers because it supports groups — which matters when auth procedures need to check group membership later.

Add to `docker-compose.yml`:

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.1
    command: start-dev --import-realm
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
    ports:
      - "8080:8080"
    volumes:
      - ./keycloak:/opt/keycloak/data/import
```

Create `keycloak/realm.json`:

```json
{
  "realm": "unicore-dev",
  "enabled": true,
  "clients": [
    {
      "clientId": "dev-app",
      "secret": "dev-secret",
      "redirectUris": ["http://localhost:3000/*"],
      "webOrigins": ["http://localhost:3000"],
      "publicClient": false,
      "protocol": "openid-connect",
      "standardFlowEnabled": true,
      "directAccessGrantsEnabled": false,
      "protocolMappers": [
        {
          "name": "groups",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-group-membership-mapper",
          "consentRequired": false,
          "config": {
            "claim.name": "groups",
            "full.path": "false",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "userinfo.token.claim": "true"
          }
        }
      ]
    }
  ],
  "groups": [
    { "name": "unicore-users" }
  ],
  "users": [
    {
      "username": "testuser",
      "email": "testuser@unicore.local",
      "firstName": "Test",
      "lastName": "User",
      "enabled": true,
      "credentials": [{ "type": "password", "value": "password", "temporary": false }],
      "groups": ["unicore-users"]
    }
  ]
}
```

Set these in `.env.local` when using Keycloak:

```bash
OKTA_CLIENT_ID="dev-app"
OKTA_CLIENT_SECRET="dev-secret"
OKTA_ISSUER="http://localhost:8080/realms/unicore-dev"
```

The Okta provider in Auth.js works with any OIDC-compliant issuer — no code changes needed to switch between Keycloak and real Okta.

## Install auth dependencies

```bash
npm install next-auth@beta @auth/prisma-adapter
```

`next-auth@beta` is the v5 release channel. Pin the resolved version in `package.json` once installed.

## Extend env validation

Add auth keys to `src/lib/env.ts`:

```ts
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().url(),
  AUTH_SECRET: z.string().min(32),
  AUTH_URL: z.string().url().optional(),
  AUTH_TRUST_HOST: z.coerce.boolean().optional(),
  OKTA_CLIENT_ID: z.string().min(1),
  OKTA_CLIENT_SECRET: z.string().min(1),
  OKTA_ISSUER: z.string().url(),
});

export const env = schema.parse(process.env);
```

`AUTH_URL` is optional locally (Auth.js auto-detects `http://localhost:3000`) and required in production. `AUTH_TRUST_HOST` is required when running behind a proxy (Railway).

## Auth setup

Create `src/lib/auth.ts`:

```ts
import NextAuth from 'next-auth';
import Okta from 'next-auth/providers/okta';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { prisma } from '@/lib/prisma';
import { env } from '@/lib/env';
import type { HealthCheckResult } from '@/lib/health';

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  providers: [
    Okta({
      clientId: env.OKTA_CLIENT_ID,
      clientSecret: env.OKTA_CLIENT_SECRET,
      issuer: env.OKTA_ISSUER,
    }),
  ],
  session: { strategy: 'database' },
});

export async function checkAuthHealth(): Promise<HealthCheckResult> {
  const url = `${env.OKTA_ISSUER.replace(/\/$/, '')}/.well-known/openid-configuration`;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(2000) });
    return res.ok
      ? { name: 'auth', status: 'ok' }
      : { name: 'auth', status: 'degraded', message: `Okta returned ${res.status}` };
  } catch (e) {
    return {
      name: 'auth',
      status: 'degraded',
      message: e instanceof Error ? e.message : String(e),
    };
  }
}
```

`checkAuthHealth` reports `degraded` (not `down`) on Okta connectivity issues so a brief upstream blip does not flap the whole service health.

## JWT path — DB-less apps

For services without a database (simple auth gates, landing pages, redirect servers), use `session: { strategy: 'jwt' }` instead of `PrismaAdapter`. No `DATABASE_URL` or Prisma required.

Install without the adapter:

```bash
npm install next-auth@beta
```

**Do not include auth env vars in `src/lib/env.ts`.** Auth.js v5's `[...nextauth]/route.ts` is an App Router file, and Next.js evaluates App Router modules at build time. If auth vars are in the zod schema, the build fails because `OKTA_CLIENT_ID` etc. are not present in the build environment. Read them via `process.env` directly in `auth.ts` instead.

`src/lib/env.ts` for a DB-less service — omit all auth vars:

```ts
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
});

export const env = schema.parse(process.env);
```

`src/lib/auth.ts` — use `process.env` directly, no PrismaAdapter:

```ts
import NextAuth from 'next-auth';
import Okta from 'next-auth/providers/okta';
import type { HealthCheckResult } from '@/lib/health';

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    Okta({
      clientId: process.env.OKTA_CLIENT_ID!,
      clientSecret: process.env.OKTA_CLIENT_SECRET!,
      issuer: process.env.OKTA_ISSUER!,
    }),
  ],
  session: { strategy: 'jwt' },
});

export async function checkAuthHealth(): Promise<HealthCheckResult> {
  const issuer = process.env.OKTA_ISSUER ?? '';
  const url = `${issuer.replace(/\/$/, '')}/.well-known/openid-configuration`;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(2000) });
    return res.ok
      ? { name: 'auth', status: 'ok' }
      : { name: 'auth', status: 'degraded', message: `Okta returned ${res.status}` };
  } catch (e) {
    return {
      name: 'auth',
      status: 'degraded',
      message: e instanceof Error ? e.message : String(e),
    };
  }
}
```

Health check in `src/pages/api/health.ts` — no `checkPrismaHealth`:

```ts
const checks: HealthCheck[] = [
  async () => ({ name: 'app', status: 'ok' }),
  checkAuthHealth,
];
```

`.env.example` for a DB-less service — no `DATABASE_URL`:

```bash
# Auth.js v5
AUTH_SECRET=""
# AUTH_URL="http://localhost:3000"

# Okta dev app (or Keycloak — see local dev alternative above)
OKTA_CLIENT_ID=""
OKTA_CLIENT_SECRET=""
OKTA_ISSUER="https://universe.okta.com"
```

README onboarding snippet for a DB-less service:

```bash
cp .env.example .env.local
# fill in OKTA_CLIENT_ID / OKTA_CLIENT_SECRET
# generate AUTH_SECRET: openssl rand -base64 32
npm install
npm run dev
```

## Auth route handler (App Router exception)

Auth.js v5 expects an App-Router-style route handler. Create the only App Router file in the project at `src/app/api/auth/[...nextauth]/route.ts`:

```ts
import { handlers } from '@/lib/auth';

export const { GET, POST } = handlers;
```

This requires the `src/app/` directory to exist. If `create-next-app` was run with `--no-app`, create `src/app/` manually — do not add a layout, page, or any other App Router files. Pages Router remains the host for everything else.

## Register the auth health check

Update `src/pages/api/health.ts` to include `checkAuthHealth`:

```ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { runHealthChecks, type HealthCheck } from '@/lib/health';
import { checkPrismaHealth } from '@/lib/prisma';
import { checkAuthHealth } from '@/lib/auth';

const checks: HealthCheck[] = [
  async () => ({ name: 'app', status: 'ok' }),
  checkPrismaHealth,
  checkAuthHealth,
];

export default async function handler(_req: NextApiRequest, res: NextApiResponse) {
  const result = await runHealthChecks(checks);
  res.status(result.status === 'down' ? 503 : 200).json(result);
}
```

Every new dependency follows this same pattern: export a `checkXHealth` from its module, append it to the array.

## App wiring

Wrap the app in `src/pages/_app.tsx`:

```tsx
import type { AppProps } from 'next/app';
import { SessionProvider } from 'next-auth/react';

export default function App({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  );
}
```

Protect a Pages Router API route with the v5 `auth()` helper:

```ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { auth } from '@/lib/auth';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const session = await auth(req, res);
  if (!session) return res.status(401).json({ error: 'Unauthorized' });
  res.status(200).json({ user: session.user });
}
```

Protect UI client-side with `useSession()` from `next-auth/react` (unchanged from v4).

## Logout policy

Default behavior:

- call `signOut()` from `next-auth/react` to end the app session
- treat this as local app logout
- do not assume the user is also signed out of Okta

This is the safer default for internal tools because it avoids turning every logout into full SSO logout across unrelated apps.

Only add federated logout if the product explicitly needs:

- "log me out of Okta too"
- stronger shared-device behavior
- SSO logout across multiple participating apps

If federated logout is added later:

- use the Okta OIDC logout endpoint
- make sure the post-logout redirect URI is configured in the Okta app
- document clearly that this signs the user out of the Okta session, not just the local app session

## Provider-token policy

By default, this auth flow treats Okta as a one-time identity provider.

That means:

- do not build features that depend on stored `access_token`, `refresh_token`, or `id_token`
- do not assume the app refreshes provider tokens
- do not assume logout revokes provider tokens

If a future app needs to call Okta or another upstream service on behalf of the user, add an explicit token lifecycle design first:

- why the provider token is needed
- where it is stored
- how refresh works
- how revocation/logout should behave
- what happens when the upstream token expires

## Local env files

Use:

- `.env.local` for each developer's local values
- `.env.example` as the committed reference for every key

Make sure `.gitignore` contains:

```text
.env*.local
```

Use this `.env.example` baseline:

```bash
# Postgres (local container runtime via docker compose — keep as-is unless you changed docker-compose.yml)
DATABASE_URL="postgresql://dev:dev@localhost:5432/myservice?schema=public"

# Auth.js v5
# Generate with: openssl rand -base64 32
AUTH_SECRET=""
# AUTH_URL is optional locally — Auth.js auto-detects http://localhost:3000.
# In production it must be set to the public URL.
# AUTH_URL="http://localhost:3000"

# Okta dev app — ask the unicore lead / Okta admin for these
OKTA_CLIENT_ID=""
OKTA_CLIENT_SECRET=""
OKTA_ISSUER="https://universe.okta.com"
```

## README onboarding snippet

Add this to the service repo `README.md`:

```bash
cp .env.example .env.local
# fill in OKTA_CLIENT_ID / OKTA_CLIENT_SECRET from the shared team note
# generate AUTH_SECRET: openssl rand -base64 32
docker compose up -d
npm install
npm run db:migrate
npm run dev
```
