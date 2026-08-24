#!/bin/bash
set -e
echo 'Tolgo il codice demo dal placeholder del campo sblocco...'
cat > "app/sblocca/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { Suspense, useEffect, useState, useCallback } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";

function getDeviceId(): string {
  const key = "device_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

function SbloccaContent() {
  const params = useSearchParams();
  const router = useRouter();
  const [status, setStatus] = useState<"loading" | "ok" | "error" | "manual">("loading");
  const [message, setMessage] = useState("Sto verificando il codice…");
  const [bookName, setBookName] = useState("");
  const [manualCode, setManualCode] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const tryUnlock = useCallback(
    (code: string) => {
      setSubmitting(true);
      setStatus("loading");
      setMessage("Sto verificando il codice…");
      const deviceId = getDeviceId();

      fetch("/api/unlock", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code, deviceId }),
      })
        .then((r) => r.json())
        .then((data) => {
          if (data.ok) {
            setStatus("ok");
            setBookName(data.bookName);
            setMessage(`${data.bookName} sbloccato su questo dispositivo.`);
            setTimeout(() => router.push("/"), 1800);
          } else {
            setStatus("manual");
            setMessage(data.error || "Codice non valido. Riprova.");
          }
        })
        .catch(() => {
          setStatus("manual");
          setMessage("Errore di connessione. Riprova.");
        })
        .finally(() => setSubmitting(false));
    },
    [router]
  );

  useEffect(() => {
    const code = params.get("codice");
    if (!code) {
      setStatus("manual");
      setMessage("Inserisci il codice stampato nella prima pagina del tuo libro.");
      return;
    }
    tryUnlock(code);
  }, [params, tryUnlock]);

  function handleManualSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (manualCode.trim()) tryUnlock(manualCode.trim());
  }

  return (
    <div className="max-w-sm w-full text-center">
      {status === "loading" && <div className="text-4xl mb-4">⏳</div>}
      {status === "ok" && <div className="text-4xl mb-4">✓</div>}
      {(status === "error" || status === "manual") && <div className="text-4xl mb-4">🔑</div>}

      <h1 className="text-xl font-medium mb-2">{status === "ok" ? bookName : "Sblocco libro"}</h1>
      <p className="text-[#a9bcc2] text-sm mb-5">{message}</p>

      {status === "manual" && (
        <form onSubmit={handleManualSubmit} className="space-y-3">
          <input
            type="text"
            value={manualCode}
            onChange={(e) => setManualCode(e.target.value)}
            placeholder="Inserisci il codice"
            autoCapitalize="characters"
            className="w-full text-center bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-sm text-white placeholder-white/40 outline-none focus:border-[#D98E4A]"
          />
          <button
            type="submit"
            disabled={submitting || !manualCode.trim()}
            className="w-full bg-[#D98E4A] text-[#0F2D3D] font-semibold rounded-lg py-3 text-sm disabled:opacity-50"
          >
            {submitting ? "Verifico…" : "Sblocca"}
          </button>
        </form>
      )}

      <Link href="/" className="block text-xs text-[#a9bcc2] underline mt-6">
        ← Torna alla home
      </Link>
    </div>
  );
}

export default function SbloccaPage() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-[#0F2D3D] text-[#F6F5F1] p-6">
      <Suspense fallback={<div className="text-sm text-[#a9bcc2]">Caricamento…</div>}>
        <SbloccaContent />
      </Suspense>
    </main>
  );
}

SETUP_EOF_MARKER
echo "Fatto."