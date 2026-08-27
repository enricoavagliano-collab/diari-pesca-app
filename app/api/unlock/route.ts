import { NextRequest, NextResponse } from "next/server";
import { findBookByCode } from "@/lib/books";
import { tryActivate } from "@/lib/activations";
import { subscribeToBrevo, type BookKey } from "@/lib/brevo";

function toBrevoBook(bookId: string): BookKey | null {
  if (bookId === "feeder") return "feeder";
  if (bookId === "mare-e-foce") return "marefoce";
  return null; // "senso-acqua": nessuna lista Brevo ancora, si salta
}

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

  // Collega l'email già data al gate d'ingresso alla lista Brevo di
  // questo libro specifico (best-effort: se fallisce non blocca lo sblocco).
  // DEBUG TEMPORANEO: brevoDebug nella risposta serve solo per diagnosticare
  // perche i contatti non arrivano su Brevo - va rimosso una volta risolto.
  const visitorEmail = req.cookies.get("visitor_email")?.value;
  const brevoBook = toBrevoBook(book.id);
  let brevoDebug = "non tentato";

  if (!visitorEmail) {
    brevoDebug = "cookie visitor_email assente nella richiesta";
  } else if (!brevoBook) {
    brevoDebug = `nessuna lista Brevo mappata per bookId '${book.id}'`;
  } else {
    try {
      const brevoResult = await subscribeToBrevo(visitorEmail, brevoBook);
      brevoDebug = brevoResult.ok
        ? `OK (email: ${visitorEmail}, lista: ${brevoBook})`
        : `ERRORE status ${brevoResult.status}: ${brevoResult.error}`;
    } catch (err) {
      brevoDebug = `ECCEZIONE: ${err instanceof Error ? err.message : String(err)}`;
    }
  }

  const res = NextResponse.json({
    ok: true,
    bookId: book.id,
    bookName: book.name,
    brevoDebug,
  });

  // Cookie di sblocco: 1 anno, leggibile lato client per mostrare lo stato "Sbloccato"
  res.cookies.set(`unlock_${book.id}`, "1", {
    maxAge: 60 * 60 * 24 * 365,
    path: "/",
    sameSite: "lax",
  });

  return res;
}
