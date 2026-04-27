---
name: setting-up-nextauth-okta
description: Use when a unicore internal service needs Okta SSO through NextAuth, including local env files and developer onboarding steps.
---

# Setting up NextAuth and Okta

Use this skill when the service needs unicore-standard authentication.

## Create the dev Okta app

In Okta:

1. Create an OIDC Web Application.
2. Set the sign-in redirect URI to `http://localhost:3000/api/auth/callback/okta`.
3. Set the sign-out redirect URI to `http://localhost:3000`.
4. Assign the correct internal group.
5. Record the Client ID, Client Secret, and Okta issuer URL.

Production uses a second Okta app later during Railway deployment.

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
