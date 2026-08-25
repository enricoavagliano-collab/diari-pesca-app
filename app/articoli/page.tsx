"use client";

import { useState } from "react";
import Link from "next/link";
import { ARTICOLI, TAGS, Tag } from "@/lib/articoli";

function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, ""); // toglie gli accenti (é→e, ò→o, ecc.)
}

export default function ArticoliPage() {
  const [query, setQuery] = useState("");
  const [activeTag, setActiveTag] = useState<Tag | null>(null);

  const filtered = ARTICOLI.filter((a) => {
    const matchesTag = !activeTag || a.tag === activeTag;
    if (!matchesTag) return false;
    if (!query.trim()) return true;
    const titleNorm = normalize(a.title);
    const words = normalize(query).split(/\s+/).filter(Boolean);
    return words.every((w) => titleNorm.includes(w));
  });

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

        <div className="flex items-center gap-2 bg-white border border-[#E1DFD6] rounded-xl px-3.5 py-2.5 mb-3">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca un articolo…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        <div className="flex gap-1.5 overflow-x-auto pb-1 mb-4 -mx-1 px-1">
          <button
            onClick={() => setActiveTag(null)}
            className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
              activeTag === null
                ? "bg-[#0F2D3D] text-white border-[#0F2D3D]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            Tutti
          </button>
          {TAGS.map((t) => (
            <button
              key={t}
              onClick={() => setActiveTag(t)}
              className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
                activeTag === t
                  ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                  : "bg-white border-[#E1DFD6] text-[#6B7E82]"
              }`}
            >
              {t}
            </button>
          ))}
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
              <div className="flex items-start justify-between gap-3 mb-1">
                <span className="text-[10px] font-mono uppercase tracking-wide text-[#D98E4A]">
                  {a.tag}
                </span>
                <span className="text-[#6B7E82] text-sm flex-shrink-0">↗</span>
              </div>
              <h3 className="text-[14px] leading-snug" style={{ fontFamily: "Georgia, serif" }}>
                {a.title}
              </h3>
              <p className="text-[11px] text-[#6B7E82] mt-1.5">Leggi sul blog</p>
            </a>
          ))}
        </div>
      </div>
    </main>
  );
}

