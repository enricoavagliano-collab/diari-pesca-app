#!/bin/bash
set -e
echo 'Aggiungo la sezione Specie e periodi migliori (aperta a tutti)...'
mkdir -p "app"
mkdir -p "app/specie"
mkdir -p "lib"
cat > "lib/specie.ts" << 'SETUP_EOF_MARKER'
export type SpecieCategory = "mare" | "dolce";
export type Rating = 1 | 2 | 3; // 1 = non buono, 2 = buono, 3 = ottimo

export interface Specie {
  name: string;
  category: SpecieCategory;
  months: Rating[]; // 12 valori, Gennaio → Dicembre
  note: string;
}

export const MONTH_LABELS = [
  "Gen", "Feb", "Mar", "Apr", "Mag", "Giu",
  "Lug", "Ago", "Set", "Ott", "Nov", "Dic",
];

export const RATING_LABELS: Record<Rating, string> = {
  1: "Non buono",
  2: "Buono",
  3: "Ottimo",
};

export const SPECIE: Specie[] = [
  {
    name: "Spigola",
    category: "mare",
    months: [2, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Sarago",
    category: "mare",
    months: [1, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Orata",
    category: "mare",
    months: [1, 1, 2, 2, 3, 3, 3, 2, 3, 3, 1, 1],
    note: "Esche bigattino, gambero, sarda, alici, anellidi vari e molluschi.",
  },
  {
    name: "Cefalo",
    category: "mare",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, gambero, sarda, alici, pane.",
  },
  {
    name: "Cavedano",
    category: "dolce",
    months: [1, 1, 3, 3, 3, 2, 2, 2, 3, 3, 2, 2],
    note: "Esche bigattino, verme, mais, mora.",
  },
  {
    name: "Carpa",
    category: "dolce",
    months: [2, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Carassio",
    category: "dolce",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Breme",
    category: "dolce",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 2],
    note: "Esche bigattino, verme, mais.",
  },
];

export function getSpecieByCategory(category: SpecieCategory): Specie[] {
  return SPECIE.filter((s) => s.category === category);
}

SETUP_EOF_MARKER
cat > "app/specie/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useState } from "react";
import Link from "next/link";
import { getSpecieByCategory, MONTH_LABELS, RATING_LABELS, SpecieCategory, Rating } from "@/lib/specie";

function ratingColor(r: Rating): string {
  if (r === 3) return "bg-[#2C6E71] text-white";
  if (r === 2) return "bg-[#D98E4A]/25 text-[#8a5a26]";
  return "bg-[#eeece3] text-[#6B7E82]";
}

export default function SpeciePage() {
  const [category, setCategory] = useState<SpecieCategory>("mare");
  const specieList = getSpecieByCategory(category);

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "Georgia, serif" }}>
          Specie e periodi migliori
        </h1>

        <div className="flex gap-1.5 mb-5">
          <button
            onClick={() => setCategory("mare")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "mare"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🌊 Mare / Foce
          </button>
          <button
            onClick={() => setCategory("dolce")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "dolce"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            💧 Acqua dolce
          </button>
        </div>

        <div className="flex items-center gap-3 mb-4 text-[10.5px] text-[#6B7E82]">
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#eeece3] inline-block"></span> Non buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#D98E4A]/25 inline-block"></span> Buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#2C6E71] inline-block"></span> Ottimo
          </span>
        </div>

        <div className="space-y-4">
          {specieList.map((specie) => (
            <div key={specie.name} className="bg-white border border-[#E1DFD6] rounded-xl p-4">
              <h3 className="font-medium text-[16px] mb-3" style={{ fontFamily: "Georgia, serif" }}>
                {specie.name}
              </h3>
              <div className="grid grid-cols-6 gap-1.5 mb-3">
                {specie.months.map((rating, i) => (
                  <div key={i} className="text-center">
                    <div
                      className={`rounded-md py-2 text-[13px] font-semibold ${ratingColor(rating)}`}
                      title={RATING_LABELS[rating]}
                    >
                      {"🐟".repeat(rating)}
                    </div>
                    <div className="text-[9.5px] text-[#6B7E82] mt-1">{MONTH_LABELS[i]}</div>
                  </div>
                ))}
              </div>
              <p className="text-[12px] text-[#6B7E82] italic leading-relaxed pt-2.5 border-t border-[#E1DFD6]">
                {specie.note}
              </p>
            </div>
          ))}
        </div>
      </div>
    </main>
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
          href="/meteo"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🌬️
          </div>
          <div>
            <h3 className="font-semibold text-sm">Meteo</h3>
            <p className="text-xs text-[#6B7E82]">Vento, pressione, condizioni</p>
          </div>
        </Link>

        <Link
          href="/specie"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🐟
          </div>
          <div>
            <h3 className="font-semibold text-sm">Specie e periodi</h3>
            <p className="text-xs text-[#6B7E82]">Mare/Foce e Acqua dolce, mese per mese</p>
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
echo "Fatto: 8 specie (4 Mare/Foce, 4 Acqua dolce) con griglia mensile, sezione universale."