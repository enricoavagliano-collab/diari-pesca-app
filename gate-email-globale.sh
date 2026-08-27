#!/bin/bash
set -e

echo "=== Creazione gate email globale per l'app ==="

mkdir -p app/entra
mkdir -p app/api/email-gate

# -----------------------------------------------------------------------
# middleware.ts — intercetta ogni richiesta, richiede l'email prima di
# qualsiasi cosa (Home, Articoli, Meteo, Maree, Diario, Sblocca, ecc.)
# -----------------------------------------------------------------------
cat > middleware.ts << 'EOF'
import { NextRequest, NextResponse } from "next/server";

// Percorsi sempre raggiungibili senza email: la pagina del gate stessa,
// tutte le API (servono anche prima che l'email sia data, es. per darla),
// e gli asset statici/PWA.
const PUBLIC_PREFIXES = [
  "/entra",
  "/api",
  "/_next",
  "/icons",
  "/covers",
  "/favicon.ico",
  "/manifest.json",
  "/sw.js",
];

function isPublic(pathname: string): boolean {
  return PUBLIC_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );
}

export function middleware(req: NextRequest) {
  const { pathname, search } = req.nextUrl;

  if (isPublic(pathname)) {
    return NextResponse.next();
  }

  const emailOk = req.cookies.get("email_ok")?.value === "1";
  if (emailOk) {
    return NextResponse.next();
  }

  const url = req.nextUrl.clone();
  url.pathname = "/entra";
  url.search = "";
  url.searchParams.set("next", pathname + search);
  return NextResponse.redirect(url);
}

export const config = {
  matcher: ["/((?!_next/static|_next/image).*)"],
};
EOF

# -----------------------------------------------------------------------
# app/api/email-gate/route.ts — salva email+consenso, NON chiama ancora
# Brevo (il libro non è ancora noto): lo farà /api/unlock più avanti.
# -----------------------------------------------------------------------
cat > app/api/email-gate/route.ts << 'EOF'
import { NextRequest, NextResponse } from "next/server";
import { isValidEmail } from "@/lib/brevo";

export async function POST(req: NextRequest) {
  let body: { email?: string; consent?: boolean };

  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Body non valido" }, { status: 400 });
  }

  const { email, consent } = body;

  if (!email || !isValidEmail(email)) {
    return NextResponse.json({ error: "Email non valida" }, { status: 400 });
  }
  if (!consent) {
    return NextResponse.json(
      { error: "Devi accettare per continuare." },
      { status: 400 }
    );
  }

  const res = NextResponse.json({ ok: true });

  // Sblocca la navigazione nell'app (letto dal middleware)
  res.cookies.set("email_ok", "1", {
    maxAge: 60 * 60 * 24 * 365 * 5,
    path: "/",
    sameSite: "lax",
  });

  // Ricordiamo l'email per collegarla alla lista Brevo giusta quando,
  // più avanti, l'utente inserisce il codice del suo libro specifico.
  res.cookies.set("visitor_email", email, {
    maxAge: 60 * 60 * 24 * 365 * 5,
    path: "/",
    sameSite: "lax",
  });

  return res;
}
EOF

# -----------------------------------------------------------------------
# app/entra/page.tsx — schermata di ingresso: email + consenso
# -----------------------------------------------------------------------
cat > app/entra/page.tsx << 'EOF'
"use client";

import { Suspense, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { Fish } from "lucide-react";

function EntraContent() {
  const params = useSearchParams();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [consent, setConsent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");

    if (!consent) {
      setError("Devi accettare per continuare.");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/email-gate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, consent }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        setError(data.error || "Errore, riprova.");
        setLoading(false);
        return;
      }

      const next = params.get("next") || "/";
      router.push(next);
      router.refresh();
    } catch {
      setError("Errore di connessione. Riprova.");
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pt-20 text-center">
        <Fish size={28} strokeWidth={1.5} className="mx-auto mb-3" />
        <h1
          className="text-[19px] mb-2"
          style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}
        >
          Benvenuto nella tua app di pesca
        </h1>
        <p className="text-sm text-[#8FA8B2] mb-6">
          Inserisci la tua email per iniziare a usare l&apos;app.
        </p>

        <form onSubmit={handleSubmit} className="flex flex-col gap-3 text-left">
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="La tua email"
            className="bg-[#124E5A] border border-white/10 rounded-lg px-3 py-2.5 text-sm text-[#F6F5F1] placeholder:text-[#8FA8B2]"
          />
          <label className="flex items-start gap-2 text-[11.5px] text-[#8FA8B2]">
            <input
              type="checkbox"
              checked={consent}
              onChange={(e) => setConsent(e.target.checked)}
              className="mt-0.5"
            />
            <span>
              Acconsento a ricevere via email i PDF omaggio e aggiornamenti sui
              prossimi libri
            </span>
          </label>

          {error && <p className="text-[12px] text-[#FF9A3C]">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="bg-[#2CA6A4] rounded-lg py-2.5 text-sm font-medium mt-1 disabled:opacity-50"
          >
            {loading ? "Un attimo…" : "Entra nell'app"}
          </button>
        </form>
      </div>
    </main>
  );
}

export default function EntraPage() {
  return (
    <Suspense fallback={null}>
      <EntraContent />
    </Suspense>
  );
}
EOF

echo "=== File creati: ==="
echo "  middleware.ts"
echo "  app/api/email-gate/route.ts"
echo "  app/entra/page.tsx"
echo ""
echo "Ora aggiorno /api/unlock per collegare l'email già data alla lista"
echo "Brevo corretta (Feeder o Mare e Foce) nel momento in cui il libro"
echo "viene sbloccato per la prima volta."

cat > app/api/unlock/route.ts << 'EOF'
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

  const res = NextResponse.json({ ok: true, bookId: book.id, bookName: book.name });

  // Cookie di sblocco: 1 anno, leggibile lato client per mostrare lo stato "Sbloccato"
  res.cookies.set(`unlock_${book.id}`, "1", {
    maxAge: 60 * 60 * 24 * 365,
    path: "/",
    sameSite: "lax",
  });

  // Collega l'email già data al gate d'ingresso alla lista Brevo di
  // questo libro specifico (best-effort: se fallisce non blocca lo sblocco).
  const visitorEmail = req.cookies.get("visitor_email")?.value;
  const brevoBook = toBrevoBook(book.id);
  if (visitorEmail && brevoBook) {
    try {
      await subscribeToBrevo(visitorEmail, brevoBook);
    } catch (err) {
      console.error("Errore invio a Brevo dopo sblocco:", err);
    }
  }

  return res;
}
EOF

echo "  app/api/unlock/route.ts (aggiornato)"
echo ""
echo "=== PROSSIMI PASSI ==="
echo "1. Testa in locale/preview prima di andare in produzione: con il"
echo "   middleware attivo, OGNI pagina (Home, Articoli, Meteo, Maree,"
echo "   Diario, Sblocca) richiede prima l'email. Verifica che il flusso"
echo "   QR -> /sblocca?codice=... funzioni ancora: ora passerà prima da"
echo "   /entra, poi torna automaticamente a /sblocca con lo stesso codice."
echo "2. git add -A && git commit -m 'gate email globale + collegamento Brevo allo sblocco libro' && git push"
echo ""
echo "Nota: nessuna nuova variabile d'ambiente necessaria, riusa"
echo "BREVO_API_KEY / BREVO_LIST_ID_FEEDER / BREVO_LIST_ID_MAREFOCE già impostate."
