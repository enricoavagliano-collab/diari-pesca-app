#!/bin/bash
set -e
echo 'Aggiungo il banner Aggiungi a Home per iPhone...'
mkdir -p "app"
mkdir -p "components"
cat > "components/IOSInstallBanner.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState } from "react";

const DISMISS_KEY = "ios_install_banner_dismissed";

export default function IOSInstallBanner() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const isIOS = /iPad|iPhone|iPod/.test(window.navigator.userAgent);
    // @ts-expect-error: 'standalone' esiste solo su Safari iOS, non nel tipo standard di Navigator
    const isStandalone = window.navigator.standalone === true;
    const dismissed = localStorage.getItem(DISMISS_KEY) === "1";

    if (isIOS && !isStandalone && !dismissed) {
      setShow(true);
    }
  }, []);

  function dismiss() {
    localStorage.setItem(DISMISS_KEY, "1");
    setShow(false);
  }

  if (!show) return null;

  return (
    <div className="fixed bottom-4 left-4 right-4 max-w-md mx-auto bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-4 shadow-lg z-50 flex items-start gap-3">
      <span className="text-xl flex-shrink-0">📲</span>
      <div className="flex-1 text-[12.5px] leading-relaxed">
        <strong>Aggiungi questa app alla tua Home:</strong> tocca l&apos;icona Condividi{" "}
        <span aria-hidden>⬆️</span> qui sotto, poi &quot;Aggiungi a Home&quot;.
      </div>
      <button
        onClick={dismiss}
        aria-label="Chiudi"
        className="text-[#a9bcc2] text-lg leading-none flex-shrink-0"
      >
        ×
      </button>
    </div>
  );
}

SETUP_EOF_MARKER
cat > "app/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import { BOOKS } from "@/lib/books";
import IOSInstallBanner from "@/components/IOSInstallBanner";

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
      <IOSInstallBanner />
    </main>
  );
}

SETUP_EOF_MARKER
echo "Fatto: su iPhone (Safari, non ancora installata) compare un banner con le istruzioni."