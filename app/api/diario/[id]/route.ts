import { NextRequest, NextResponse } from "next/server";
import { deleteEntry, updateEntry } from "@/lib/diario-entries";

export async function PUT(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { deviceId, data } = await req.json();

  if (!deviceId || !data) {
    return NextResponse.json({ ok: false, error: "Dati mancanti." }, { status: 400 });
  }

  const entry = await updateEntry(id, deviceId, data);
  if (!entry) {
    return NextResponse.json({ ok: false, error: "Voce non trovata." }, { status: 404 });
  }

  return NextResponse.json({ ok: true, entry });
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { deviceId } = await req.json();

  if (!deviceId) {
    return NextResponse.json({ ok: false, error: "Dispositivo mancante." }, { status: 400 });
  }

  const ok = await deleteEntry(id, deviceId);
  if (!ok) {
    return NextResponse.json({ ok: false, error: "Voce non trovata." }, { status: 404 });
  }

  return NextResponse.json({ ok: true });
}

