# กิดตัง · Kidtang v3 (Web)

Thai bill-splitting app — Next.js 15 rebuild. See [FEATURES.md](FEATURES.md) for the full spec.

## Tech stack

Next.js 15 (App Router) · TypeScript · Tailwind CSS v4 · shadcn/ui (Radix) · Magic UI
(in-repo) · Motion · Supabase (Postgres + Auth + Realtime) · next-intl (th/en) ·
Zustand · React Hook Form + Zod · Recharts · qrcode · @react-pdf/renderer ·
html-to-image · Web Push (VAPID).

## Requirements

- **Node.js ≥ 20** (Next.js 15 requires it; see `.nvmrc`). Node 16 will not build.
  ```bash
  nvm use        # picks up .nvmrc (22)
  ```

## Getting started

```bash
npm install
cp .env.local .env.local   # already populated with the shared Supabase project
npm run dev                # http://localhost:3000  → redirects to /th/login
```

Scripts: `npm run dev` · `npm run build` · `npm run start` · `npm run typecheck`.

## Environment

`.env.local` holds the client + server keys (Supabase URL/anon key, LINE channel,
VAPID). To enable everything, also set:

- `SUPABASE_SERVICE_ROLE_KEY` — required for the public share route and Web Push.
- `VAPID_PRIVATE_KEY` — required to send Web Push.
- `LINE_CHANNEL_SECRET` — already set; needed for the LINE OAuth token exchange.

## Project structure

```
src/
  app/[locale]/            # i18n routes: (auth), (app), line-web-return
  app/api/                 # auth/callback, line-auth, push
  components/{ui,magic,shared,home,bill,group,friends,me}
  lib/{supabase,utils}     # clients + bill engine (bill-utils), promptpay, format
  repositories/            # server-side Supabase queries + row→type mappers
  stores/                  # Zustand (bills/groups/friends)
  i18n/  messages/         # next-intl (th default, en)
  middleware.ts            # Supabase session + auth guard + i18n routing
supabase/                  # existing schema.sql (v8) + migrations (reused)
```

## Supabase notes

- The app targets the **existing schema** (`supabase/schema.sql`). Bill status uses
  `draft | pending_payment | completed`; the UI maps these to draft/open/settled.
- **Public share page** (`/bills/[id]/share`, no auth): it reads via the service-role
  client (`createServiceClient`). Either set `SUPABASE_SERVICE_ROLE_KEY`, or add a
  public-read RLS policy `allow_public_read_bill` on `bills`/`bill_members`/`bill_items`.
- OAuth (Google/LINE) and Web Push are code-complete but require the provider
  redirect URLs + keys configured in the Supabase/LINE consoles to fully exercise.
```
