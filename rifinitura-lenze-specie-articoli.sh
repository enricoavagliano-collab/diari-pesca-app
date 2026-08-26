#!/bin/bash
set -e
echo 'Rifinitura estetica: Specie, Articoli, Lenze secondo il nuovo mockup...'
mkdir -p "app/articoli"
mkdir -p "app/lenze"
mkdir -p "app/specie"
mkdir -p "lib"
cat > "lib/specie.ts" << 'SETUP_EOF_MARKER'
export type SpecieCategory = "mare" | "dolce";
export type Rating = 1 | 2 | 3; // 1 = non buono, 2 = buono, 3 = ottimo

export interface Specie {
  name: string;
  scientificName: string;
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
    scientificName: "Dicentrarchus labrax",
    category: "mare",
    months: [2, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Sarago",
    scientificName: "Diplodus sargus",
    category: "mare",
    months: [1, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Orata",
    scientificName: "Sparus aurata",
    category: "mare",
    months: [1, 1, 2, 2, 3, 3, 3, 2, 3, 3, 1, 1],
    note: "Esche bigattino, gambero, sarda, alici, anellidi vari e molluschi.",
  },
  {
    name: "Cefalo",
    scientificName: "Mugil cephalus",
    category: "mare",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, gambero, sarda, alici, pane.",
  },
  {
    name: "Cavedano",
    scientificName: "Squalius cephalus",
    category: "dolce",
    months: [1, 1, 3, 3, 3, 2, 2, 2, 3, 3, 2, 2],
    note: "Esche bigattino, verme, mais, mora.",
  },
  {
    name: "Carpa",
    scientificName: "Cyprinus carpio",
    category: "dolce",
    months: [2, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Carassio",
    scientificName: "Carassius carassius",
    category: "dolce",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Breme",
    scientificName: "Abramis brama",
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
import { Fish, Waves, Droplets } from "lucide-react";
import { getSpecieByCategory, MONTH_LABELS, RATING_LABELS, SpecieCategory, Rating } from "@/lib/specie";

function ratingColor(r: Rating): string {
  if (r === 3) return "bg-[#2CA6A4]";
  if (r === 2) return "bg-[#FF9A3C]";
  return "bg-white/10";
}

export default function SpeciePage() {
  const [category, setCategory] = useState<SpecieCategory>("mare");
  const specieList = getSpecieByCategory(category);

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Specie e periodi
        </h1>

        <div className="flex gap-1.5 mb-5">
          <button
            onClick={() => setCategory("mare")}
            className={`flex items-center gap-1.5 text-[12.5px] font-medium px-3 py-1.5 rounded-full border ${
              category === "mare"
                ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            <Waves size={14} strokeWidth={2} /> Mare / Foce
          </button>
          <button
            onClick={() => setCategory("dolce")}
            className={`flex items-center gap-1.5 text-[12.5px] font-medium px-3 py-1.5 rounded-full border ${
              category === "dolce"
                ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            <Droplets size={14} strokeWidth={2} /> Acqua dolce
          </button>
        </div>

        <div className="flex items-center gap-2.5 mb-5 text-[10.5px] text-[#8FA8B2]">
          <span className="flex items-center gap-1.5 bg-[#124E5A] border border-white/10 rounded-full px-2.5 py-1">
            <span className="w-2.5 h-2.5 rounded-sm bg-white/10 inline-block"></span> Non buono
          </span>
          <span className="flex items-center gap-1.5 bg-[#124E5A] border border-white/10 rounded-full px-2.5 py-1">
            <span className="w-2.5 h-2.5 rounded-sm bg-[#FF9A3C] inline-block"></span> Buono
          </span>
          <span className="flex items-center gap-1.5 bg-[#124E5A] border border-white/10 rounded-full px-2.5 py-1">
            <span className="w-2.5 h-2.5 rounded-sm bg-[#2CA6A4] inline-block"></span> Ottimo
          </span>
        </div>

        <div className="space-y-3">
          {specieList.map((specie) => (
            <div key={specie.name} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
              <div className="flex items-start gap-3 mb-3">
                <div className="w-11 h-11 rounded-lg bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                  <Fish size={20} strokeWidth={1.5} className="text-[#2CA6A4]" />
                </div>
                <div>
                  <h3 className="text-[16px]" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
                    {specie.name}
                  </h3>
                  <p className="text-[11px] text-[#8FA8B2] italic">{specie.scientificName}</p>
                </div>
              </div>

              {[specie.months.slice(0, 6), specie.months.slice(6, 12)].map((half, rowIdx) => (
                <div key={rowIdx} className="grid grid-cols-6 gap-1.5 mb-1.5">
                  {half.map((rating, i) => {
                    const monthIdx = rowIdx * 6 + i;
                    return (
                      <div key={monthIdx} className="text-center">
                        <div
                          className={`rounded-md h-6 ${ratingColor(rating)}`}
                          title={RATING_LABELS[rating]}
                        />
                        <div className="text-[9px] text-[#8FA8B2] mt-1">{MONTH_LABELS[monthIdx]}</div>
                      </div>
                    );
                  })}
                </div>
              ))}

              <p className="text-[12px] text-[#8FA8B2] italic leading-relaxed pt-2.5 mt-1.5 border-t border-white/10">
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
cat > "app/articoli/page.tsx" << 'SETUP_EOF_MARKER'
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

SETUP_EOF_MARKER
cat > "app/lenze/LenzeClient.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Waves, Link2, CircleDot, Weight, Fish as FishIcon, Plus } from "lucide-react";
import {
  LenzaCategory,
  Tecnica,
  TECNICHE,
  TECNICA_VARIANTI,
  getOfficialLenza,
  OFFICIAL_ASSETTI,
  LENZA_FIELDS_MARE,
  ASSETTO_FIELDS_FEEDER,
  LenzaSpec,
} from "@/lib/lenze-official";

interface LenzaEntry {
  id: string;
  title: string;
  data: Record<string, string>;
  createdAt: string;
}

function getDeviceId(): string {
  const key = "device_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

export default function LenzeClient({
  unlockedMare,
  unlockedFeeder,
  unlockedSensoAcqua,
}: {
  unlockedMare: boolean;
  unlockedFeeder: boolean;
  unlockedSensoAcqua: boolean;
}) {
  const [category, setCategory] = useState<LenzaCategory>("mare");
  const [subtab, setSubtab] = useState<"enrico" | "mie">("enrico");
  const [tecnica, setTecnica] = useState<Tecnica>("trattenuta");
  const [variante, setVariante] = useState<string>(TECNICA_VARIANTI["trattenuta"][0].id);

  const [mine, setMine] = useState<LenzaEntry[]>([]);
  const [formOpen, setFormOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [values, setValues] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const deviceId = typeof window !== "undefined" ? getDeviceId() : "";

  const loadMine = useCallback(
    (cat: LenzaCategory) => {
      if (!deviceId) return;
      fetch(`/api/lenze?deviceId=${deviceId}&category=${cat}`)
        .then((r) => r.json())
        .then((d) => {
          if (d.ok) setMine(d.entries);
        });
    },
    [deviceId]
  );

  useEffect(() => {
    loadMine(category);
  }, [category, loadMine]);

  useEffect(() => {
    // Quando cambia la tecnica, seleziona la prima variante disponibile
    setVariante(TECNICA_VARIANTI[tecnica][0].id);
  }, [tecnica]);

  function setField(key: string, value: string) {
    setValues((v) => ({ ...v, [key]: value }));
  }

  function copyToMine(spec: LenzaSpec) {
    setValues({
      madre: spec.madre,
      finale: spec.finale,
      galleggiante: spec.galleggiante,
      piombatura: spec.piombatura,
      amo: spec.amo,
    });
    setTitle(
      `${TECNICHE.find((t) => t.id === tecnica)?.label} — ${
        TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label
      } (copia)`
    );
    setSubtab("mie");
    setFormOpen(true);
  }

  async function save() {
    if (!title.trim()) return;
    setSaving(true);
    const res = await fetch("/api/lenze", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ deviceId, category, title, data: values }),
    });
    const d = await res.json();
    setSaving(false);
    if (d.ok) {
      setMine((m) => [d.entry, ...m]);
      setTitle("");
      setValues({});
      setFormOpen(false);
    }
  }

  async function remove(id: string) {
    const res = await fetch(`/api/lenze/${id}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ deviceId }),
    });
    const d = await res.json();
    if (d.ok) setMine((m) => m.filter((x) => x.id !== id));
  }

  const spec = category === "mare" ? getOfficialLenza(tecnica, variante) : null;
  const personalFields = category === "mare" ? LENZA_FIELDS_MARE : ASSETTO_FIELDS_FEEDER;
  const categoryUnlocked = category === "mare" ? unlockedMare || unlockedSensoAcqua : unlockedFeeder;

  return (
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Le mie lenze
        </h1>

        {/* Categoria principale */}
        <div className="flex gap-1.5 mb-3">
          <button
            onClick={() => setCategory("mare")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "mare"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🌊 Mare / Foce {!(unlockedMare || unlockedSensoAcqua) && "🔒"}
          </button>
          <button
            onClick={() => setCategory("feeder")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "feeder"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🎣 Feeder {!unlockedFeeder && "🔒"}
          </button>
        </div>

        {!categoryUnlocked ? (
          <div className="bg-[#124E5A] border border-white/10 rounded-xl p-6 text-center mt-4">
            <div className="text-3xl mb-3">🔒</div>
            <h2 className="font-medium text-[15px] mb-1.5">
              {category === "mare" ? "Sblocca con Mare e Foce o Il senso dell'acqua" : "Sblocca con Diario Feeder"}
            </h2>
            <p className="text-sm text-[#8FA8B2] leading-relaxed">
              Questa sezione fa parte dei contenuti del diario{" "}
              {category === "mare" ? "Mare e Foce (o de Il senso dell'acqua)" : "Feeder"} — inquadra il QR nella prima
              pagina della tua copia per sbloccarla.
            </p>
          </div>
        ) : (
          <>
            {/* Sotto-schede */}
        <div className="flex gap-1 mb-4 bg-[#0B1F2A] rounded-xl p-1">
          <button
            onClick={() => setSubtab("enrico")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "enrico" ? "bg-[#124E5A] text-[#F6F5F1]" : "text-[#8FA8B2]"
            }`}
          >
            Da Enrico
          </button>
          <button
            onClick={() => setSubtab("mie")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "mie" ? "bg-[#124E5A] text-[#F6F5F1]" : "text-[#8FA8B2]"
            }`}
          >
            Le mie
          </button>
        </div>

        {/* ===== DA ENRICO — MARE/FOCE ===== */}
        {subtab === "enrico" && category === "mare" && (
          <div>
            <div className="flex gap-1.5 overflow-x-auto pb-1 mb-3 -mx-1 px-1">
              {TECNICHE.map((t) => (
                <button
                  key={t.id}
                  onClick={() => setTecnica(t.id)}
                  className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
                    tecnica === t.id
                      ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                      : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            <div className="flex flex-wrap gap-1.5 mb-4">
              {TECNICA_VARIANTI[tecnica].map((v) => (
                <button
                  key={v.id}
                  onClick={() => setVariante(v.id)}
                  className={`text-[11.5px] px-2.5 py-1.5 rounded-lg border ${
                    variante === v.id
                      ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                      : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
                  }`}
                >
                  {v.label}
                </button>
              ))}
            </div>

            {spec && (
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {TECNICHE.find((t) => t.id === tecnica)?.label} —{" "}
                  {TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label}
                </h3>
                <p className="text-[11px] text-[#8FA8B2] mb-3">di Enrico Avagliano</p>

                <div className="space-y-2.5 pt-2.5 border-t border-white/10">
                  {[
                    { Icon: Waves, label: "Madre", value: spec.madre },
                    { Icon: Link2, label: "Finale", value: spec.finale },
                    { Icon: CircleDot, label: "Galleggiante", value: spec.galleggiante },
                    { Icon: FishIcon, label: "Amo", value: spec.amo },
                  ].map(({ Icon, label, value }) => (
                    <div key={label} className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                        <Icon size={15} strokeWidth={1.75} className="text-[#2CA6A4]" />
                      </div>
                      <span className="text-[12.5px] flex-1">{label}</span>
                      <span className="font-mono text-[12.5px] text-[#F6F5F1]">{value}</span>
                    </div>
                  ))}
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                      <Weight size={15} strokeWidth={1.75} className="text-[#2CA6A4]" />
                    </div>
                    <div className="flex-1">
                      <span className="text-[12.5px]">Piombatura</span>
                      <p className="text-[11.5px] text-[#8FA8B2] leading-relaxed mt-0.5">{spec.piombatura}</p>
                    </div>
                  </div>
                </div>

                <p className="text-[12px] text-[#8FA8B2] italic mt-3 leading-relaxed">{spec.nota}</p>

                <button
                  onClick={() => copyToMine(spec)}
                  className="w-full flex items-center justify-center gap-1.5 border border-[#2CA6A4] text-[#2CA6A4] rounded-full py-2 text-[12.5px] font-medium mt-3"
                >
                  <Plus size={14} /> Aggiungi alle mie
                </button>

                {unlockedSensoAcqua ? (
                  <div className="mt-3 pt-3 border-t border-white/10">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-[10.5px] text-[#FF9A3C] font-medium">
                        ✎ Disegno esclusivo — Il senso dell&apos;acqua
                      </span>
                    </div>
                    <div className="bg-[#0B1F2A] border border-dashed border-white/10 rounded-lg h-32 flex items-center justify-center text-[11px] text-[#8FA8B2]">
                      📐 Disegno del montaggio — in arrivo
                    </div>
                  </div>
                ) : (
                  <div className="mt-3 pt-3 border-t border-white/10 flex items-center gap-2.5 bg-[#0B1F2A] rounded-lg p-2.5">
                    <span className="text-lg flex-shrink-0">🔒</span>
                    <p className="text-[11px] text-[#8FA8B2] leading-relaxed">
                      Disegno del montaggio disponibile solo per chi ha Il senso dell&apos;acqua.
                    </p>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* ===== DA ENRICO — FEEDER ===== */}
        {subtab === "enrico" && category === "feeder" && (
          <div className="space-y-3">
            {OFFICIAL_ASSETTI.map((a, i) => (
              <div key={i} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {a.title}
                </h3>
                <p className="text-[11px] text-[#8FA8B2] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-white/10">
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Pasturatore</div>
                    <div className="font-mono text-[12.5px]">{a.pasturatore}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Terminale</div>
                    <div className="font-mono text-[12.5px]">{a.terminale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Lenza madre</div>
                    <div className="font-mono text-[12.5px]">{a.lenzaMadre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{a.amo}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Esche</div>
                    <div className="font-mono text-[12.5px]">{a.esche}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Pastura</div>
                    <div className="font-mono text-[12.5px]">{a.pastura}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ===== LE MIE (personali, sia mare che feeder) ===== */}
        {subtab === "mie" && (
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-xs text-[#8FA8B2]">{mine.length} salvate</span>
              <button
                onClick={() => setFormOpen((o) => !o)}
                className="w-8 h-8 rounded-full bg-[#2CA6A4] text-white text-lg flex items-center justify-center"
              >
                {formOpen ? "×" : "+"}
              </button>
            </div>

            {formOpen && (
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4 space-y-3">
                <div>
                  <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">Nome</label>
                  <input
                    className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                    placeholder={
                      category === "mare" ? "es. La mia bolognese da canale" : "es. Il mio assetto da corrente"
                    }
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                  />
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  {personalFields.map((f) => (
                    <div key={f.key}>
                      <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">{f.label}</label>
                      <input
                        className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                        value={values[f.key] || ""}
                        onChange={(e) => setField(f.key, e.target.value)}
                      />
                    </div>
                  ))}
                </div>
                <button
                  onClick={save}
                  disabled={saving || !title.trim()}
                  className="w-full bg-[#2CA6A4] text-[#0B1F2A] rounded-xl py-2.5 text-sm font-medium disabled:opacity-50"
                >
                  {saving ? "Salvataggio…" : "Salva"}
                </button>
              </div>
            )}

            {mine.length === 0 && !formOpen && (
              <p className="text-sm text-[#8FA8B2]">Nessuna lenza salvata ancora — inizia dal +</p>
            )}

            {mine.map((entry) => (
              <div key={entry.id} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-medium text-[15px]" style={{ fontFamily: "var(--font-fraunces)" }}>
                    {entry.title}
                  </h3>
                  <button
                    onClick={() => remove(entry.id)}
                    className="text-xs text-[#8FA8B2] hover:text-red-600 flex-shrink-0"
                  >
                    elimina
                  </button>
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {Object.entries(entry.data)
                    .filter(([, v]) => v)
                    .map(([k, v]) => (
                      <span
                        key={k}
                        className="text-[11px] bg-[#0B1F2A] border border-white/10 rounded-full px-2 py-0.5"
                      >
                        {v}
                      </span>
                    ))}
                </div>
              </div>
            ))}
          </div>
        )}
          </>
        )}
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
echo "Fatto: griglia mesi compatta con nomi scientifici, articoli con icona colorata, lenze con righe a icona e pulsante Aggiungi alle mie."