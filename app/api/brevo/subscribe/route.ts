import { NextRequest, NextResponse } from "next/server";
import { subscribeToBrevo, isValidEmail, type BookKey } from "@/lib/brevo";

export async function POST(req: NextRequest) {
  let body: { email?: string; book?: string; consent?: boolean };

  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Body non valido" }, { status: 400 });
  }

  const { email, book, consent } = body;

  if (!email || !isValidEmail(email)) {
    return NextResponse.json({ error: "Email non valida" }, { status: 400 });
  }

  if (book !== "feeder" && book !== "marefoce") {
    return NextResponse.json(
      { error: "Parametro 'book' mancante o non valido (atteso 'feeder' o 'marefoce')" },
      { status: 400 }
    );
  }

  if (!consent) {
    return NextResponse.json(
      { error: "Consenso mancante: la checkbox deve essere confermata" },
      { status: 400 }
    );
  }

  const result = await subscribeToBrevo(email, book as BookKey);

  if (!result.ok) {
    console.error("Errore Brevo:", result.error);
    return NextResponse.json(
      { error: "Errore durante l'iscrizione, riprova." },
      { status: 502 }
    );
  }

  return NextResponse.json({ ok: true });
}
