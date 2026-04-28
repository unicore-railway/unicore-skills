---
name: setting-up-trpc
description: Use when a unicore Next.js service needs the tRPC layer for type-safe app-internal API calls. Adds tRPC v11, TanStack Query, the server router with auth-protected procedures, the [trpc].ts catch-all handler, and the typed client. Required — every app-internal endpoint must go through tRPC.
---

# Setting up tRPC

Use this skill after `setting-up-nextauth-okta` so the tRPC context can use the Auth.js v5 session.

_Last verified against tRPC v11 tooling: **2026-04-28**._

## Baseline policy

**All app-internal API calls go through tRPC.** The only raw `pages/api/*` routes that remain in a unicore service are:

- `/api/health` — called by Railway, not by the app itself
- `/api/auth/*` — managed by Auth.js

Do not add new raw `pages/api/*` handlers for app data. Do not call them with `useEffect` + `fetch` or with bare `fetch`. Use `trpc.<router>.<procedure>.useQuery(...)` / `.useMutation(...)` instead.

Why:

- end-to-end types between server procedures and React components — no hand-maintained API client
- automatic request batching
- one place (`protectedProcedure`) enforces "must be signed in" across every endpoint
- Zod input validation with structured error responses

## Install

```bash
npm install @trpc/server @trpc/client @trpc/next @trpc/react-query @tanstack/react-query superjson
```

`superjson` is the default transformer so procedures can return `Date`, `BigInt`, `Map`, and `Set` without manual serialization. Pin all versions in `package.json` after install.

## Server: init and procedures

Create `src/server/trpc.ts`:

```ts
import { initTRPC, TRPCError } from '@trpc/server';
import type { CreateNextContextOptions } from '@trpc/server/adapters/next';
import superjson from 'superjson';
import { ZodError } from 'zod';
import { auth } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function createContext(opts: CreateNextContextOptions) {
  const session = await auth(opts.req, opts.res);
  return { session, prisma };
}

export type Context = Awaited<ReturnType<typeof createContext>>;

const t = initTRPC.context<Context>().create({
  transformer: superjson,
  errorFormatter({ shape, error }) {
    return {
      ...shape,
      data: {
        ...shape.data,
        zodError: error.cause instanceof ZodError ? error.cause.flatten() : null,
      },
    };
  },
});

export const router = t.router;
export const publicProcedure = t.procedure;

const requireAuth = t.middleware(({ ctx, next }) => {
  if (!ctx.session?.user) {
    throw new TRPCError({ code: 'UNAUTHORIZED' });
  }
  return next({ ctx: { ...ctx, session: ctx.session } });
});

export const protectedProcedure = t.procedure.use(requireAuth);
```

`publicProcedure` should be rare in internal tools. Default to `protectedProcedure` unless you have a specific reason.

## Server: root router

Create `src/server/router.ts`:

```ts
import { router, protectedProcedure } from './trpc';

export const appRouter = router({
  me: protectedProcedure.query(({ ctx }) => ctx.session.user),
});

export type AppRouter = typeof appRouter;
```

When the API grows, split this into `src/server/routers/<module>.ts` files and compose them in `appRouter`. Don't wait for it to become unwieldy — split the moment a module has more than three or four procedures.

## Server: HTTP handler

Create `src/pages/api/trpc/[trpc].ts`:

```ts
import { createNextApiHandler } from '@trpc/server/adapters/next';
import { appRouter } from '@/server/router';
import { createContext } from '@/server/trpc';

export default createNextApiHandler({
  router: appRouter,
  createContext,
});
```

This is the only catch-all tRPC handler. Do not create additional `pages/api/*` files for app data.

## Client setup

Create `src/lib/trpc.ts`:

```ts
import { createTRPCNext } from '@trpc/next';
import { httpBatchLink } from '@trpc/client';
import superjson from 'superjson';
import type { AppRouter } from '@/server/router';

export const trpc = createTRPCNext<AppRouter>({
  config() {
    return {
      transformer: superjson,
      links: [httpBatchLink({ url: '/api/trpc' })],
    };
  },
  ssr: false,
});
```

`ssr: false` matches the SPA-plus-API baseline — fetches happen on the client, never during render.

## Wrap the app

Update `src/pages/_app.tsx`:

```tsx
import type { AppProps } from 'next/app';
import { SessionProvider } from 'next-auth/react';
import { trpc } from '@/lib/trpc';

function App({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  );
}

export default trpc.withTRPC(App);
```

`trpc.withTRPC` installs both the QueryClient and the tRPC provider — no manual `<QueryClientProvider>` is needed.

## Using tRPC in a page

```tsx
import { trpc } from '@/lib/trpc';

export default function Home() {
  const meQuery = trpc.me.useQuery();

  if (meQuery.isLoading) return <p>Loading…</p>;
  if (meQuery.error) return <p>Error: {meQuery.error.message}</p>;

  return <pre>{JSON.stringify(meQuery.data, null, 2)}</pre>;
}
```

For mutations:

```tsx
const updateName = trpc.user.updateName.useMutation({
  onSuccess: () => meQuery.refetch(),
});

updateName.mutate({ name: 'Roman' });
```

## Input validation

Validate every input with Zod. Never accept `unknown` from the client.

```ts
import { z } from 'zod';
import { router, protectedProcedure } from './trpc';

export const userRouter = router({
  updateName: protectedProcedure
    .input(z.object({ name: z.string().min(1).max(80) }))
    .mutation(async ({ ctx, input }) => {
      return ctx.prisma.user.update({
        where: { id: ctx.session.user.id },
        data: { name: input.name },
      });
    }),
});
```

The `errorFormatter` in `src/server/trpc.ts` already surfaces Zod issues to the client as `error.data.zodError`.

## Authorization beyond "is signed in"

`protectedProcedure` only enforces "user has a session." When a procedure needs more (admin only, owner only, role gate), build a new middleware that consumes `ctx.session.user` and throws `TRPCError({ code: 'FORBIDDEN' })` when the rule fails. Do not duplicate the check inside procedure bodies.

## What to avoid

- Calling app-internal endpoints with raw `fetch` or `useEffect` + `fetch`.
- Adding new files under `pages/api/*` for app data. (`/api/health` and `/api/auth/*` are the only exceptions.)
- Returning `any` from procedures — kills the end-to-end types.
- Skipping Zod input validation.
