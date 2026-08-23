import { NextRequest, NextResponse } from "next/server";
import { addLenza, getLenze } from "@/lib/lenze-entries";
import { LenzaCategory } from "@/lib/lenze-official";

export async function POST(req: NextRequest) {
  const { deviceId, category, title, data } = await req.json();

  if (!deviceId || !category || !title) {
    return NextResponse.json({ ok: false, error: "Dati mancanti." }, { status: 400 });
  }

  const entry = await addLenza({ deviceId, category, title, data: data || {} });
  return NextResponse.json({ ok: true, entry });
}

export async function GET(req: NextRequest) {
  const deviceId = req.nextUrl.searchParams.get("deviceId");
  const category = req.nextUrl.searchParams.get("category") as LenzaCategory | null;

  if (!deviceId || !category) {
    return NextResponse.json({ ok: false, error: "Parametri mancanti." }, { status: 400 });
  }

  const entries = await getLenze(deviceId, category);
  return NextResponse.json({ ok: true, entries });
}

