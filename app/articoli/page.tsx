"use client";

import { useState } from "react";
import Link from "next/link";
import { Wrench, Fish, Worm, CircleGauge, MapPin, NotebookText } from "lucide-react";
import { ARTICOLI, TAGS, Tag } from "@/lib/articoli";

const TAG_STYLES: Record<Tag, { Icon: typeof Wrench; bg: string }> = {
  Tecnica: { Icon: Wrench, bg: "#2CA6A4" },
  Specie: { Icon: Fish, bg: "#5B9BD5" },
  Esche: { Icon: Worm, bg: "#C97B4A" },
  Attrezzatura: { Icon: CircleGauge, bg: "#8FA8B2" },
  Spot: { Icon: MapPin, bg: "#7CB342" },
  Diario: { Icon: NotebookText, bg: "#8FA8B2" },
};

function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, ""); // toglie gli accenti (é→e, ò→o, ecc.)
}

// Due parole "corrispondono" se condividono la stessa radice, ignorando l'ultima lettera
// (gestisce singolare/plurale italiano: "spigola" ↔ "spigole", "canna" ↔ "canne", ecc.)
// o se una è il prefisso dell'altra (ricerca parziale mentre si scrive).
function wordsMatch(word: string, queryWord: string): boolean {
  const minLen = Math.min(word.length, queryWord.length);
  if (minLen < 3) return false; // parole troppo corte: evitiamo falsi positivi (es. "a", "il")
  if (word.includes(queryWord) || queryWord.includes(word)) return true;
  if (minLen < 4) return false;
  return word.slice(0, minLen - 1) === queryWord.slice(0, minLen - 1);
}

function titleMatchesQuery(title: string, query: string): boolean {
  const titleWords = normalize(title).split(/\W+/).filter(Boolean);
  const queryWords = normalize(query).split(/\s+/).filter(Boolean);
  return queryWords.every((qw) => titleWords.some((tw) => wordsMatch(tw, qw)));
}

export default function ArticoliPage() {
  const [query, setQuery] = useState("");
  const [activeTag, setActiveTag] = useState<Tag | null>(null);

  const filtered = ARTICOLI.filter((a) => {
    const matchesTag = !activeTag || a.tag === activeTag;
    if (!matchesTag) return false;
    if (!query.trim()) return true;
    return titleMatchesQuery(a.title, query);
  });

  return (
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
          Articoli
        </h1>
        <p className="text-xs text-[#8FA8B2] mb-4">{ARTICOLI.length} articoli dal blog</p>

        <div className="flex items-center gap-2 bg-[#124E5A] border border-white/10 rounded-xl px-3.5 py-2.5 mb-3">
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
                ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
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
                  ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                  : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
              }`}
            >
              {t}
            </button>
          ))}
        </div>

        {filtered.length === 0 && (
          <p className="text-sm text-[#8FA8B2]">Nessun articolo trovato per questa ricerca.</p>
        )}

        <div className="space-y-2.5">
          {filtered.map((a) => {
            const style = TAG_STYLES[a.tag];
            const TagIcon = style.Icon;
            return (
              <a
                key={a.url}
                href={a.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-3 bg-[#124E5A] border border-white/10 rounded-xl p-3.5"
              >
                <div
                  className="w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0"
                  style={{ backgroundColor: style.bg }}
                >
                  <TagIcon size={19} strokeWidth={1.75} className="text-[#0B1F2A]" />
                </div>
                <div className="flex-1 min-w-0">
                  <span className="text-[10px] font-mono uppercase tracking-wide" style={{ color: style.bg }}>
                    {a.tag}
                  </span>
                  <h3 className="text-[14px] leading-snug mt-0.5" style={{ fontFamily: "var(--font-fraunces)" }}>
                    {a.title}
                  </h3>
                </div>
                <span className="text-[#8FA8B2] text-sm flex-shrink-0">↗</span>
              </a>
            );
          })}
        </div>
      </div>
    </main>
  );
}

