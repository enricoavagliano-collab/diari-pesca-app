import { NextRequest, NextResponse } from "next/server";
import { addEntry, getEntries } from "@/lib/diario-entries";
import { BookId } from "@/lib/books";

export async function POST(req: NextRequest) {
  const { bookId, deviceId, data } = await req.json();

  if (!bookId || !deviceId || !data) {
    return NextResponse.json({ ok: false, error: "Dati mancanti." }, { status: 400 });
  }

  const entry = await addEntry({ bookId: bookId as BookId, deviceId, data });
  return NextResponse.json({ ok: true, entry });
}

export async function GET(req: NextRequest) {
  const bookId = req.nextUrl.searchParams.get("bookId") as BookId | null;
  const deviceId = req.nextUrl.searchParams.get("deviceId");

  if (!bookId || !deviceId) {
    return NextResponse.json({ ok: false, error: "Parametri mancanti." }, { status: 400 });
  }

  const entries = await getEntries(bookId, deviceId);
  return NextResponse.json({ ok: true, entries });
}

