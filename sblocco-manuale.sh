#!/bin/bash
set -e
echo 'Aggiungo lo sblocco manuale con codice, per chi non passa dal QR...'
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
            placeholder="es. FEEDER-2026-DEMO"
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
cat > "app/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import { BOOKS } from "@/lib/books";

export default async function Home() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5">
        <div className="bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-5 mb-5">
          <p className="text-[10px] uppercase tracking-widest text-[#D98E4A] mb-1">
            Diari di Pesca
          </p>
          <h1 className="text-xl font-medium">Il tuo hub di lettura</h1>
        </div>

        <p className="text-[11px] uppercase tracking-widest text-[#6B7E82] mb-2">
          I tuoi libri
        </p>

        <div className="space-y-3">
          {books.map((book) => (
            <Link
              key={book.id}
              href={`/diario/${book.id}`}
              className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3"
            >
              <div className="w-11 h-15 rounded bg-[#2C6E71] text-white flex items-center justify-center text-sm font-medium flex-shrink-0">
                {book.name.slice(0, 2).toUpperCase()}
              </div>
              <div className="flex-1">
                <h3 className="font-medium text-sm">{book.name}</h3>
                <p className="text-xs text-[#6B7E82]">
                  {book.unlocked ? "Contenuti disponibili" : "Da sbloccare col QR"}
                </p>
              </div>
              <span
                className={`text-[10px] px-2 py-1 rounded-full font-mono ${
                  book.unlocked
                    ? "bg-[#e6f0ef] text-[#2C6E71]"
                    : "bg-[#f0eee6] text-[#6B7E82]"
                }`}
              >
                {book.unlocked ? "Sbloccato" : "🔒 QR"}
              </span>
            </Link>
          ))}
        </div>

        <p className="text-[11px] uppercase tracking-widest text-[#6B7E82] mb-2 mt-6">
          Strumenti — aperti a tutti
        </p>

        <Link
          href="/maree"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🌊
          </div>
          <div>
            <h3 className="font-semibold text-sm">Maree e luna</h3>
            <p className="text-xs text-[#6B7E82]">Qualunque località, oggi o nei prossimi giorni</p>
          </div>
        </Link>

        <Link
          href="/lenze"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🎣
          </div>
          <div>
            <h3 className="font-semibold text-sm">Le mie lenze</h3>
            <p className="text-xs text-[#6B7E82]">Con Mare e Foce o Diario Feeder</p>
          </div>
        </Link>

        <Link
          href="/sblocca"
          className="mt-6 flex items-center justify-center gap-2 border border-dashed border-[#E1DFD6] rounded-xl py-3 text-sm text-[#2C6E71] font-medium"
        >
          🔑 Hai un codice? Sbloccalo qui
        </Link>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
echo "Fatto: link Hai un codice? in home, con campo per inserirlo a mano."