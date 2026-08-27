#!/bin/bash
set -e

echo "=== Fix: blocco dopo invio email + testo checkbox ==="

cat > app/entra/page.tsx << 'EOF'
"use client";

import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Fish } from "lucide-react";

function EntraContent() {
  const params = useSearchParams();
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
      // Ricaricamento pieno (non router.push): garantisce che il server
      // veda subito il cookie appena impostato, senza le ambiguità della
      // cache di navigazione di Next.js che in alcuni casi lasciava la
      // pagina bloccata finché non si aggiornava manualmente.
      window.location.href = next;
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
              Acconsento all&apos;uso della mia email per accedere all&apos;app e
              ricevere aggiornamenti su contenuti e nuovi libri
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

echo "=== File corretto: app/entra/page.tsx ==="
echo ""
echo "Ricorda: bash fix-blocco-entra-e-testo.sh, poi:"
echo "git add -A && git commit -m 'fix blocco dopo invio email + testo checkbox' && git push"
echo ""
echo "NOTA: se avevi già eseguito fix-testo-consenso-entra.sh in precedenza,"
echo "nessun problema: questo script sovrascrive comunque tutto correttamente."
