#!/bin/bash
set -e

echo "=== Rimuovo il debug temporaneo (problema risolto: IP autorizzati Brevo) ==="

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

python3 << 'PYEOF'
path = "app/sblocca/page.tsx"
with open(path, "r") as f:
    content = f.read()

old = '''            setBookName(data.bookName);
            setMessage(
              `${data.bookName} sbloccato su questo dispositivo.` +
                (data.brevoDebug ? ` [DEBUG Brevo: ${data.brevoDebug}]` : "")
            );
            setTimeout(() => router.push("/"), 8000); // rallentato temporaneamente per leggere il debug Brevo'''

new = '''            setBookName(data.bookName);
            setMessage(`${data.bookName} sbloccato su questo dispositivo.`);
            setTimeout(() => router.push("/"), 1800);'''

if old in content:
    content = content.replace(old, new)
    with open(path, "w") as f:
        f.write(content)
    print("app/sblocca/page.tsx ripulito.")
else:
    print("app/sblocca/page.tsx: debug non trovato (forse già pulito), nessuna modifica.")
PYEOF

echo ""
echo "=== File ripuliti: ==="
echo "  app/api/unlock/route.ts"
echo "  app/sblocca/page.tsx"
echo ""
echo "Ricorda: bash rimuovi-debug-brevo.sh, poi:"
echo "git add -A && git commit -m 'rimuove debug temporaneo brevo' && git push"
