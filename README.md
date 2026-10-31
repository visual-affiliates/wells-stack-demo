# wells-stack-demo

A small, stripped-down example of how I structure a multi-tenant app: one Next.js codebase, many businesses, and Postgres row-level security deciding who sees what.

I wrote this repository for my profile. My shipped products (Pilates Manager, Spa Manager App and others) are private because they are sold to clients, and none of their code, data or keys are here.

## What is inside

| Path | What it shows |
|---|---|
| docs/architecture.md | Request flow, roles and the rules I follow |
| supabase/migrations/001_tenants_rls.sql | Tenants, memberships and bookings with row-level security policies |
| src/lib/supabase-server.ts | Server client that runs as the signed-in user, never with a service-role key |
| src/app/api/bookings/route.ts | A route handler that validates input and lets the database enforce access |

## Stack

TypeScript · Next.js · Supabase (Postgres) · zod

## Note

This is an illustration, not a runnable product. It has not been deployed.

More of my live work: [github.com/visual-affiliates](https://github.com/visual-affiliates) · [williamwells.vn](https://williamwells.vn)

Powered by ⚡️ William Wells
