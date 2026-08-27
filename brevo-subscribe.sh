#!/bin/bash
set -e

echo "=== Creazione endpoint Brevo /api/brevo/subscribe ==="

mkdir -p lib
mkdir -p app/api/brevo/subscribe

# -----------------------------------------------------------------------
# lib/brevo.ts — helper condiviso per chiamare l'API Brevo
# -----------------------------------------------------------------------
cat > lib/brevo.ts << 'EOF'
// Helper server-side per aggiungere un contatto a Brevo.
// La API key NON deve mai essere esposta al client: questo file va
// importato solo da route handler lato server (app/api/.../route.ts).

type BookKey = "feeder" | "marefoce";

const LIST_ID_BY_BOOK: Record<BookKey, string | undefined> = {
  feeder: process.env.BREVO_LIST_ID_FEEDER,
  marefoce: process.env.BREVO_LIST_ID_MAREFOCE,
};

export interface SubscribeResult {
  ok: boolean;
  status: number;
  error?: string;
}

export async function subscribeToBrevo(
  email: string,
  book: BookKey
): Promise<SubscribeResult> {
  const apiKey = process.env.BREVO_API_KEY;
  const listId = LIST_ID_BY_BOOK[book];

  if (!apiKey) {
    return { ok: false, status: 500, error: "BREVO_API_KEY mancante" };
  }
  if (!listId) {
    return { ok: false, status: 500, error: `Lista Brevo non configurata per '${book}'` };
  }

  const res = await fetch("https://api.brevo.com/v3/contacts", {
    method: "POST",
    headers: {
      "api-key": apiKey,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      email,
      listIds: [Number(listId)],
      // Se il contatto esiste già, lo aggiorna invece di fallire con 400
      updateEnabled: true,
      attributes: {
        LIBRO: book === "feeder" ? "Feeder" : "Mare e Foce",
        FONTE: "app_diari_pesca",
      },
    }),
  });

  if (res.ok || res.status === 204) {
    return { ok: true, status: res.status };
  }

  // Brevo risponde 400 con code "duplicate_parameter" se il contatto
  // esiste già con updateEnabled=false; con updateEnabled=true questo
  // in teoria non dovrebbe accadere, ma lo gestiamo comunque.
  let errorText = "";
  try {
    const data = await res.json();
    errorText = data?.message || JSON.stringify(data);
  } catch {
    errorText = await res.text();
  }

  return { ok: false, status: res.status, error: errorText };
}

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export type { BookKey };
EOF

# -----------------------------------------------------------------------
# app/api/brevo/subscribe/route.ts — endpoint chiamato dal form in-app
# -----------------------------------------------------------------------
cat > app/api/brevo/subscribe/route.ts << 'EOF'
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
EOF

echo "=== File creati: ==="
echo "  lib/brevo.ts"
echo "  app/api/brevo/subscribe/route.ts"
echo ""
echo "=== PROSSIMI PASSI (da fare tu su Vercel, non nel codice) ==="
echo "1. Vercel → Settings → Environment Variables, aggiungi:"
echo "     BREVO_API_KEY        = <la tua chiave xkeysib-...>"
echo "     BREVO_LIST_ID_FEEDER = 7"
echo "     BREVO_LIST_ID_MAREFOCE = 6"
echo "2. git add -A && git commit -m 'add brevo subscribe endpoint' && git push"
echo "3. Vercel ripubblica automaticamente"
echo ""
echo "Nota: la UI del modulo email (il form che l'utente compila nell'app,"
echo "con email + checkbox di consenso) NON è ancora in questo script —"
echo "la facciamo nel prossimo passaggio, una volta confermato dove deve"
echo "comparire esattamente nel flusso (subito dopo lo sblocco del libro)."
