import { NextRequest, NextResponse } from "next/server";
import { deleteLenza } from "@/lib/lenze-entries";

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { deviceId } = await req.json();

  if (!deviceId) {
    return NextResponse.json({ ok: false, error: "Dispositivo mancante." }, { status: 400 });
  }

  const ok = await deleteLenza(id, deviceId);
  if (!ok) {
    return NextResponse.json({ ok: false, error: "Lenza non trovata." }, { status: 404 });
  }

  return NextResponse.json({ ok: true });
}

