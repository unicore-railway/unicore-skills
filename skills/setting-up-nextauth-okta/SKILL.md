---
name: setting-up-nextauth-okta
description: Use when a unicore internal service needs Okta SSO through NextAuth, including local env files and developer onboarding steps.
---

# Setting up NextAuth and Okta

Use this skill when the service needs unicore-standard authentication.

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

## Create the dev Okta app

In Okta:

1. Create an OIDC Web Application.
2. Set the sign-in redirect URI to `http://localhost:3000/api/auth/callback/okta`.
3. Set the sign-out redirect URI to `http://localhost:3000`.
4. Assign the correct internal group.
5. Record the Client ID, Client Secret, and Okta issuer URL.

Production uses a second Okta app later during Railway deployment.

The sign-out redirect URI exists so the app can support RP-initiated logout later if needed. It is not a requirement to perform federated logout in the baseline flow.

## Install auth dependencies

```bash
npm install next-auth @next-auth/prisma-adapter
```

Create `src/pages/api/auth/[...nextauth].ts`:

```ts
import NextAuth, { type NextAuthOptions } from 'next-auth';
import OktaProvider from 'next-auth/providers/okta';
import { PrismaAdapter } from '@next-auth/prisma-adapter';
import { prisma } from '@/lib/prisma';

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    OktaProvider({
      clientId: process.env.OKTA_CLIENT_ID!,
      clientSecret: process.env.OKTA_CLIENT_SECRET!,
      issuer: process.env.OKTA_ISSUER!,
    }),
  ],
  session: { strategy: 'database' },
};

export default NextAuth(authOptions);
```

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

Protect an API route like this:

```ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { getServerSession } from 'next-auth/next';
import { authOptions } from './auth/[...nextauth]';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const session = await getServerSession(req, res, authOptions);
  if (!session) return res.status(401).json({ error: 'Unauthorized' });
  res.status(200).json({ user: session.user });
}
```

Protect UI client-side with `useSession()`.

## Logout policy

Default behavior:

- call `signOut()` to end the app session
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

# NextAuth
# Generate with: openssl rand -base64 32
NEXTAUTH_SECRET=""
NEXTAUTH_URL="http://localhost:3000"

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
# generate NEXTAUTH_SECRET: openssl rand -base64 32
docker compose up -d
npm install
npm run db:migrate
npm run dev
```
