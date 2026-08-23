import { NextRequest, NextResponse } from "next/server";
import { findBookByCode } from "@/lib/books";
import { tryActivate } from "@/lib/activations";

export async function POST(req: NextRequest) {
  const { code, deviceId } = await req.json();

  if (!code || !deviceId) {
    return NextResponse.json(
      { ok: false, error: "Dati mancanti." },
      { status: 400 }
    );
  }

  const book = findBookByCode(code);
  if (!book) {
    return NextResponse.json(
      { ok: false, error: "Codice non valido." },
      { status: 404 }
    );
  }

  const result = await tryActivate(book.id, deviceId, book.maxActivations);
  if (!result.ok) {
    return NextResponse.json(
      { ok: false, error: result.reason },
      { status: 403 }
    );
  }

  const res = NextResponse.json({ ok: true, bookId: book.id, bookName: book.name });

  // Cookie di sblocco: 1 anno, leggibile lato client per mostrare lo stato "Sbloccato"
  res.cookies.set(`unlock_${book.id}`, "1", {
    maxAge: 60 * 60 * 24 * 365,
    path: "/",
    sameSite: "lax",
  });

  return res;
}

