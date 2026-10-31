import { NextResponse } from "next/server";
import { z } from "zod";
import { supabaseServer } from "@/lib/supabase-server";

const Body = z.object({
  tenantId: z.string().uuid(),
  startsAt: z.string().datetime(),
});

// Creates a booking for the signed-in client.
// There is no tenant check here on purpose: the insert policy in
// supabase/migrations/001_tenants_rls.sql rejects any tenant the user does not belong to.
export async function POST(req: Request) {
  const parsed = Body.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "bad_request" }, { status: 400 });
  }

  const db = await supabaseServer();
  const { data: auth } = await db.auth.getUser();
  if (!auth.user) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { data, error } = await db
    .from("bookings")
    .insert({
      tenant_id: parsed.data.tenantId,
      client_id: auth.user.id,
      starts_at: parsed.data.startsAt,
    })
    .select("id")
    .single();

  if (error) {
    return NextResponse.json({ error: "forbidden" }, { status: 403 });
  }
  return NextResponse.json({ id: data.id }, { status: 201 });
}
