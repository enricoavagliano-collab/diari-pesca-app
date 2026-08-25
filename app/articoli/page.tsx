"use client";

import { useState } from "react";
import Link from "next/link";
import { ARTICOLI } from "@/lib/articoli";

export default function ArticoliPage() {
  const [query, setQuery] = useState("");

  const filtered = query.trim()
    ? ARTICOLI.filter((a) => a.title.toLowerCase().includes(query.toLowerCase()))
    : ARTICOLI;

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-1" style={{ fontFamily: "Georgia, serif" }}>
          Articoli
        </h1>
        <p className="text-xs text-[#6B7E82] mb-4">{ARTICOLI.length} articoli dal blog</p>

        <div className="flex items-center gap-2 bg-white border border-[#E1DFD6] rounded-xl px-3.5 py-2.5 mb-4">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca un articolo…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        {filtered.length === 0 && (
          <p className="text-sm text-[#6B7E82]">Nessun articolo trovato per questa ricerca.</p>
        )}

        <div className="space-y-2.5">
          {filtered.map((a) => (
            <a
              key={a.url}
              href={a.url}
              target="_blank"
              rel="noopener noreferrer"
              className="block bg-white border border-[#E1DFD6] rounded-xl p-3.5"
            >
              <div className="flex items-start justify-between gap-3">
                <h3 className="text-[14px] leading-snug" style={{ fontFamily: "Georgia, serif" }}>
                  {a.title}
                </h3>
                <span className="text-[#6B7E82] text-sm flex-shrink-0 mt-0.5">↗</span>
              </div>
              <p className="text-[11px] text-[#6B7E82] mt-1.5">Leggi sul blog</p>
            </a>
          ))}
        </div>
      </div>
    </main>
  );
}

