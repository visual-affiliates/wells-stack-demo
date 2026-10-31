# Architecture

One Next.js app serves many tenants (studios, spas, clubs). Every row in the database belongs to a tenant, and Postgres row-level security decides who can see or change it. Application code never filters by tenant on its own, so a missed filter cannot leak data.

## Request flow

1. The browser calls a Next.js route handler with the user's session cookie.
2. The handler builds a Supabase server client from that cookie (src/lib/supabase-server.ts).
3. The query runs as the signed-in user. Row-level security policies (supabase/migrations/001_tenants_rls.sql) allow or deny each row.
4. The handler returns JSON. A denied row looks the same as a missing row.

## Roles

| Role | Can do |
|---|---|
| owner | Everything inside their tenant |
| staff | Read all bookings in their tenant, update their status |
| client | Read and create only their own bookings |

## Rules this demo follows

- No service-role key in request handlers. Only the user's own session touches data.
- Policy helpers are security definer functions with a fixed search_path.
- Input is validated with zod before it reaches the database.
- Schema changes are migrations, never edits in a dashboard.

This is a stripped-down illustration written for this repository. It is not the code of any shipped product.
