#!/bin/bash
set -e
echo 'Rinnovo grafico: font veri, icone vere, linea di marea firma...'
mkdir -p "app"
mkdir -p "app/articoli"
mkdir -p "app/diario/[bookId]"
mkdir -p "app/lenze"
mkdir -p "app/maree"
mkdir -p "app/meteo"
mkdir -p "app/specie"
mkdir -p "components"
cat > "app/layout.tsx" << 'SETUP_EOF_MARKER'
import type { Metadata, Viewport } from "next";
import { Fraunces, Inter, IBM_Plex_Mono } from "next/font/google";
import "./globals.css";

const fraunces = Fraunces({
  subsets: ["latin"],
  variable: "--font-fraunces",
  weight: ["400", "500", "600"],
});

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  weight: ["400", "500", "600"],
});

const plexMono = IBM_Plex_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  weight: ["400", "500"],
});

export const metadata: Metadata = {
  title: "Libri di Pesca",
  description: "Companion app per i libri di Enrico Avagliano",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Libri di Pesca",
  },
  icons: {
    icon: [
      { url: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/icons/apple-touch-icon.png", sizes: "180x180" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#0F2D3D",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="it"
      className={`${fraunces.variable} ${inter.variable} ${plexMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}

SETUP_EOF_MARKER
cat > "app/globals.css" << 'SETUP_EOF_MARKER'
@import "tailwindcss";

/* Colori fissi del brand: l'app ha sempre lo stesso aspetto,
   indipendentemente dalla modalità chiara/scura del dispositivo. */
:root {
  --background: #F6F5F1;
  --foreground: #16232B;
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --font-sans: var(--font-inter);
  --font-display: var(--font-fraunces);
  --font-mono: var(--font-mono);
}

body {
  background: var(--background);
  color: var(--foreground);
  font-family: var(--font-inter), Arial, Helvetica, sans-serif;
}

input,
textarea {
  color: var(--foreground);
  font-family: var(--font-inter), Arial, Helvetica, sans-serif;
}

input::placeholder,
textarea::placeholder {
  color: #6B7E82;
}

SETUP_EOF_MARKER
cat > "app/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import { Waves, Anchor, Wind, CalendarDays, Newspaper, KeyRound } from "lucide-react";
import { BOOKS } from "@/lib/books";
import IOSInstallBanner from "@/components/IOSInstallBanner";

const TOOLS = [
  {
    href: "/maree",
    Icon: Waves,
    title: "Maree e luna",
    subtitle: "Qualunque località, oggi o nei prossimi giorni",
  },
  {
    href: "/lenze",
    Icon: Anchor,
    title: "Le mie lenze",
    subtitle: "Con Mare e Foce o Diario Feeder",
  },
  {
    href: "/meteo",
    Icon: Wind,
    title: "Meteo",
    subtitle: "Vento, pressione, condizioni",
  },
  {
    href: "/specie",
    Icon: CalendarDays,
    title: "Specie e periodi",
    subtitle: "Mare/Foce e Acqua dolce, mese per mese",
  },
  {
    href: "/articoli",
    Icon: Newspaper,
    title: "Articoli",
    subtitle: "Tutti i contenuti tecnici dal blog",
  },
];

export default async function Home() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md pb-16">
        {/* Intestazione + linea di marea (elemento firma) */}
        <div className="bg-[#0F2D3D] text-[#F6F5F1] px-5 pt-6 pb-7">
          <p className="text-[10px] uppercase tracking-[0.15em] text-[#D98E4A] mb-1.5 font-medium">
            Libri di Pesca
          </p>
          <h1
            className="text-[22px] leading-snug"
            style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}
          >
            Tutta la pesca a portata di click
          </h1>
        </div>
        <svg
          className="w-full block -mt-px"
          viewBox="0 0 400 20"
          preserveAspectRatio="none"
          style={{ height: 18 }}
        >
          <path
            d="M0,10 C33,3 67,17 100,10 C133,3 167,17 200,10 C233,3 267,17 300,10 C333,3 367,17 400,10 L400,20 L0,20 Z"
            fill="#0F2D3D"
          />
        </svg>

        <div className="p-5 pt-4">
          <p className="text-[11px] uppercase tracking-[0.1em] text-[#6B7E82] mb-2.5 font-medium">
            I tuoi libri
          </p>

          <div className="space-y-2.5">
            {books.map((book) => (
              <Link
                key={book.id}
                href={`/diario/${book.id}`}
                className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 shadow-[0_1px_2px_rgba(15,45,61,0.04)] transition-transform active:scale-[0.98]"
              >
                <div
                  className="w-11 h-14 rounded-md bg-[#2C6E71] text-white flex items-center justify-center text-sm flex-shrink-0"
                  style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}
                >
                  {book.name.slice(0, 2).toUpperCase()}
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-sm">{book.name}</h3>
                  <p className="text-xs text-[#6B7E82]">
                    {book.unlocked ? "Contenuti disponibili" : "Da sbloccare col QR"}
                  </p>
                </div>
                <span
                  className={`text-[10px] px-2 py-1 rounded-full font-mono flex-shrink-0 ${
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

          <p className="text-[11px] uppercase tracking-[0.1em] text-[#6B7E82] mb-2.5 mt-6 font-medium">
            Strumenti — aperti a tutti
          </p>

          <div className="space-y-2.5">
            {TOOLS.map(({ href, Icon, title, subtitle }) => (
              <Link
                key={href}
                href={href}
                className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 shadow-[0_1px_2px_rgba(15,45,61,0.04)] transition-transform active:scale-[0.98]"
              >
                <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center flex-shrink-0">
                  <Icon size={18} strokeWidth={1.75} className="text-[#2C6E71]" />
                </div>
                <div>
                  <h3 className="font-semibold text-sm">{title}</h3>
                  <p className="text-xs text-[#6B7E82]">{subtitle}</p>
                </div>
              </Link>
            ))}
          </div>

          <Link
            href="/sblocca"
            className="mt-6 flex items-center justify-center gap-2 border border-dashed border-[#E1DFD6] rounded-xl py-3 text-sm text-[#2C6E71] font-medium"
          >
            <KeyRound size={15} strokeWidth={2} />
            Hai un codice? Sbloccalo qui
          </Link>
        </div>
      </div>
      <IOSInstallBanner />
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/meteo/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";

interface GeoResult {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  country: string;
  admin1?: string;
  timezone: string;
}

interface HourSlot {
  time: string;
  tempC: number;
  windSpeed: number;
  windDirection: number;
  pressure: number;
  description: string;
  icon: string;
}

interface DayWeather {
  date: string;
  slots: HourSlot[];
}

const SAVED_KEY = "meteo_locations";

function loadSaved(): GeoResult[] {
  if (typeof window === "undefined") return [];
  try {
    return JSON.parse(localStorage.getItem(SAVED_KEY) || "[]");
  } catch {
    return [];
  }
}

function saveLocation(loc: GeoResult) {
  const saved = loadSaved().filter((l) => l.id !== loc.id);
  saved.unshift(loc);
  localStorage.setItem(SAVED_KEY, JSON.stringify(saved.slice(0, 6)));
}

function removeLocation(id: number) {
  const saved = loadSaved().filter((l) => l.id !== id);
  localStorage.setItem(SAVED_KEY, JSON.stringify(saved));
}

function windDirectionLabel(degrees: number): string {
  const dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"];
  return dirs[Math.round(degrees / 45) % 8];
}

function nextDays(count: number): { iso: string; label: string }[] {
  const days = [];
  const dayLabels = ["Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"];
  for (let i = 0; i < count; i++) {
    const d = new Date();
    d.setDate(d.getDate() + i);
    const iso = d.toLocaleDateString("sv-SE");
    const label = i === 0 ? "Oggi" : i === 1 ? "Domani" : `${dayLabels[d.getDay()]} ${d.getDate()}`;
    days.push({ iso, label });
  }
  return days;
}

export default function MeteoPage() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<GeoResult[]>([]);
  const [searching, setSearching] = useState(false);
  const [selected, setSelected] = useState<GeoResult | null>(null);
  const [saved, setSaved] = useState<GeoResult[]>([]);
  const [selectedDate, setSelectedDate] = useState(nextDays(1)[0].iso);
  const [weekDays, setWeekDays] = useState<DayWeather[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [dataError, setDataError] = useState<string | null>(null);

  useEffect(() => {
    setSaved(loadSaved());
  }, []);

  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([]);
      return;
    }
    setSearching(true);
    const t = setTimeout(() => {
      fetch(`/api/geocode?q=${encodeURIComponent(query)}`)
        .then((r) => r.json())
        .then((d) => setResults(d.ok ? d.results : []))
        .finally(() => setSearching(false));
    }, 350);
    return () => clearTimeout(t);
  }, [query]);

  const loadLocationData = useCallback((loc: GeoResult) => {
    setSelected(loc);
    setQuery("");
    setResults([]);
    setDataError(null);
    saveLocation(loc);
    setSaved(loadSaved());

    setLoading(true);
    fetch(`/api/meteo?lat=${loc.latitude}&lon=${loc.longitude}`)
      .then((r) => r.json())
      .then((d) => {
        if (!d.ok) {
          setDataError(d.error || "Meteo non disponibile per questa località.");
          setWeekDays(null);
          return;
        }
        setWeekDays(d.days);
      })
      .catch(() => setDataError("Errore nel recupero del meteo. Riprova."))
      .finally(() => setLoading(false));
  }, []);

  const todayWeather = weekDays?.find((d) => d.date === selectedDate) || null;

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Meteo
        </h1>

        <div className="flex items-center gap-2 bg-white border border-[#E1DFD6] rounded-xl px-3.5 py-2.5 mb-3">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca una località… es. Livorno, Gaeta"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        {searching && <p className="text-xs text-[#6B7E82] mb-2">Cerco…</p>}

        {results.length > 0 && (
          <div className="bg-white border border-[#E1DFD6] rounded-xl mb-3 overflow-hidden">
            {results.map((r) => (
              <button
                key={r.id}
                onClick={() => loadLocationData(r)}
                className="w-full text-left px-3.5 py-2.5 text-sm border-b border-[#E1DFD6] last:border-0 hover:bg-[#F6F5F1]"
              >
                {r.name}
                <span className="text-[#6B7E82]"> — {r.admin1 ? r.admin1 + ", " : ""}{r.country}</span>
              </button>
            ))}
          </div>
        )}

        {saved.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-4">
            {saved.map((s) => (
              <div
                key={s.id}
                className={`flex items-center gap-1 pl-2.5 pr-1 py-1 rounded-full border text-[11px] font-mono ${
                  selected?.id === s.id
                    ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                    : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                }`}
              >
                <button onClick={() => loadLocationData(s)}>📍 {s.name}</button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    removeLocation(s.id);
                    setSaved(loadSaved());
                  }}
                  className={`w-4 h-4 rounded-full flex items-center justify-center text-[10px] ml-0.5 ${
                    selected?.id === s.id ? "hover:bg-white/20" : "hover:bg-[#eeece3]"
                  }`}
                  aria-label={`Rimuovi ${s.name}`}
                >
                  ×
                </button>
              </div>
            ))}
          </div>
        )}

        {!selected && (
          <p className="text-sm text-[#6B7E82] mt-6">
            Cerca una località per vedere vento, pressione e condizioni.
          </p>
        )}

        {selected && (
          <div className="flex gap-1.5 overflow-x-auto pb-1 mb-4 -mx-1 px-1">
            {nextDays(6).map((d) => (
              <button
                key={d.iso}
                onClick={() => setSelectedDate(d.iso)}
                className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
                  selectedDate === d.iso
                    ? "bg-[#0F2D3D] text-white border-[#0F2D3D]"
                    : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                }`}
              >
                {d.label}
              </button>
            ))}
          </div>
        )}

        {loading && <p className="text-sm text-[#6B7E82]">Carico il meteo…</p>}

        {dataError && (
          <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-sm text-[#6B7E82] mb-4">
            {dataError}
          </div>
        )}

        {selected && !loading && todayWeather && (
          <>
            <div className="text-[11px] uppercase tracking-widest text-[#D98E4A] mb-1">
              {selected.name}
            </div>
            <h2 className="text-[19px] font-medium mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
              {nextDays(6).find((d) => d.iso === selectedDate)?.label || "Oggi"}
            </h2>

            {(
              [
                { label: "Notte", hours: ["00:00", "02:00", "04:00"] },
                { label: "Mattina", hours: ["06:00", "08:00", "10:00"] },
                { label: "Pomeriggio", hours: ["12:00", "14:00", "16:00"] },
                { label: "Sera", hours: ["18:00", "20:00", "22:00"] },
              ] as const
            ).map((group) => {
              const groupSlots = todayWeather.slots.filter((s) => (group.hours as readonly string[]).includes(s.time));
              if (groupSlots.length === 0) return null;
              return (
                <div key={group.label} className="mb-4">
                  <div className="text-[11px] uppercase tracking-widest text-[#6B7E82] mb-2">
                    {group.label}
                  </div>
                  <div className="bg-white border border-[#E1DFD6] rounded-xl overflow-hidden">
                    {groupSlots.map((s, i) => (
                      <div
                        key={s.time}
                        className={`flex items-center gap-3 px-3.5 py-2.5 ${
                          i > 0 ? "border-t border-[#E1DFD6]" : ""
                        }`}
                      >
                        <span className="font-mono text-[12.5px] text-[#6B7E82] w-10 flex-shrink-0">
                          {s.time.slice(0, 5)}
                        </span>
                        <span className="text-base flex-shrink-0">{s.icon}</span>
                        <span className="text-[12.5px] flex-1">{s.tempC}°</span>
                        <span className="text-[12px] text-[#6B7E82] flex-shrink-0">
                          {s.windSpeed}km/h {windDirectionLabel(s.windDirection)}
                        </span>
                        <span className="text-[12px] text-[#6B7E82] flex-shrink-0 w-14 text-right">
                          {s.pressure}hPa
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
          </>
        )}
      </div>
    </main>
  );
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
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
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
              <h3 className="font-medium text-[16px] mb-3" style={{ fontFamily: "var(--font-fraunces)" }}>
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
cat > "app/lenze/LenzeClient.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import {
  LenzaCategory,
  Tecnica,
  TECNICHE,
  TECNICA_VARIANTI,
  getOfficialLenza,
  OFFICIAL_ASSETTI,
  LENZA_FIELDS_MARE,
  ASSETTO_FIELDS_FEEDER,
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
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
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
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🌊 Mare / Foce {!(unlockedMare || unlockedSensoAcqua) && "🔒"}
          </button>
          <button
            onClick={() => setCategory("feeder")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "feeder"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🎣 Feeder {!unlockedFeeder && "🔒"}
          </button>
        </div>

        {!categoryUnlocked ? (
          <div className="bg-white border border-[#E1DFD6] rounded-xl p-6 text-center mt-4">
            <div className="text-3xl mb-3">🔒</div>
            <h2 className="font-medium text-[15px] mb-1.5">
              {category === "mare" ? "Sblocca con Mare e Foce o Il senso dell'acqua" : "Sblocca con Diario Feeder"}
            </h2>
            <p className="text-sm text-[#6B7E82] leading-relaxed">
              Questa sezione fa parte dei contenuti del diario{" "}
              {category === "mare" ? "Mare e Foce (o de Il senso dell'acqua)" : "Feeder"} — inquadra il QR nella prima
              pagina della tua copia per sbloccarla.
            </p>
          </div>
        ) : (
          <>
            {/* Sotto-schede */}
        <div className="flex gap-1 mb-4 bg-[#eeece3] rounded-xl p-1">
          <button
            onClick={() => setSubtab("enrico")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "enrico" ? "bg-white text-[#16232B]" : "text-[#6B7E82]"
            }`}
          >
            Da Enrico
          </button>
          <button
            onClick={() => setSubtab("mie")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "mie" ? "bg-white text-[#16232B]" : "text-[#6B7E82]"
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
                      ? "bg-[#0F2D3D] text-white border-[#0F2D3D]"
                      : "bg-white border-[#E1DFD6] text-[#6B7E82]"
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
                      ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                      : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                  }`}
                >
                  {v.label}
                </button>
              ))}
            </div>

            {spec && (
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {TECNICHE.find((t) => t.id === tecnica)?.label} —{" "}
                  {TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label}
                </h3>
                <p className="text-[11px] text-[#6B7E82] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-[#E1DFD6]">
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Madre</div>
                    <div className="font-mono text-[12.5px]">{spec.madre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Finale</div>
                    <div className="font-mono text-[12.5px]">{spec.finale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Galleggiante</div>
                    <div className="font-mono text-[12.5px]">{spec.galleggiante}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{spec.amo}</div>
                  </div>
                  <div className="col-span-2">
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Piombatura</div>
                    <div className="text-[12.5px] leading-relaxed">{spec.piombatura}</div>
                  </div>
                </div>
                <p className="text-[12px] text-[#6B7E82] italic mt-3 leading-relaxed">{spec.nota}</p>

                {unlockedSensoAcqua ? (
                  <div className="mt-3 pt-3 border-t border-[#E1DFD6]">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-[10.5px] text-[#D98E4A] font-medium">
                        ✎ Disegno esclusivo — Il senso dell&apos;acqua
                      </span>
                    </div>
                    <div className="bg-[#F6F5F1] border border-dashed border-[#E1DFD6] rounded-lg h-32 flex items-center justify-center text-[11px] text-[#6B7E82]">
                      📐 Disegno del montaggio — in arrivo
                    </div>
                  </div>
                ) : (
                  <div className="mt-3 pt-3 border-t border-[#E1DFD6] flex items-center gap-2.5 bg-[#F6F5F1] rounded-lg p-2.5">
                    <span className="text-lg flex-shrink-0">🔒</span>
                    <p className="text-[11px] text-[#6B7E82] leading-relaxed">
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
              <div key={i} className="bg-white border border-[#E1DFD6] rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {a.title}
                </h3>
                <p className="text-[11px] text-[#6B7E82] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-[#E1DFD6]">
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Pasturatore</div>
                    <div className="font-mono text-[12.5px]">{a.pasturatore}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Terminale</div>
                    <div className="font-mono text-[12.5px]">{a.terminale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Lenza madre</div>
                    <div className="font-mono text-[12.5px]">{a.lenzaMadre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{a.amo}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Esche</div>
                    <div className="font-mono text-[12.5px]">{a.esche}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Pastura</div>
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
              <span className="text-xs text-[#6B7E82]">{mine.length} salvate</span>
              <button
                onClick={() => setFormOpen((o) => !o)}
                className="w-8 h-8 rounded-full bg-[#2C6E71] text-white text-lg flex items-center justify-center"
              >
                {formOpen ? "×" : "+"}
              </button>
            </div>

            {formOpen && (
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-4 space-y-3">
                <div>
                  <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">Nome</label>
                  <input
                    className="w-full border border-[#E1DFD6] rounded-md px-2.5 py-2 text-sm bg-[#F6F5F1]"
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
                      <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">{f.label}</label>
                      <input
                        className="w-full border border-[#E1DFD6] rounded-md px-2.5 py-2 text-sm bg-[#F6F5F1]"
                        value={values[f.key] || ""}
                        onChange={(e) => setField(f.key, e.target.value)}
                      />
                    </div>
                  ))}
                </div>
                <button
                  onClick={save}
                  disabled={saving || !title.trim()}
                  className="w-full bg-[#0F2D3D] text-white rounded-xl py-2.5 text-sm font-medium disabled:opacity-50"
                >
                  {saving ? "Salvataggio…" : "Salva"}
                </button>
              </div>
            )}

            {mine.length === 0 && !formOpen && (
              <p className="text-sm text-[#6B7E82]">Nessuna lenza salvata ancora — inizia dal +</p>
            )}

            {mine.map((entry) => (
              <div key={entry.id} className="bg-white border border-[#E1DFD6] rounded-xl p-4">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-medium text-[15px]" style={{ fontFamily: "var(--font-fraunces)" }}>
                    {entry.title}
                  </h3>
                  <button
                    onClick={() => remove(entry.id)}
                    className="text-xs text-[#6B7E82] hover:text-red-600 flex-shrink-0"
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
                        className="text-[11px] bg-[#F6F5F1] border border-[#E1DFD6] rounded-full px-2 py-0.5"
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
cat > "app/maree/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";

interface GeoResult {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  country: string;
  admin1?: string;
  timezone: string;
}

interface TideExtreme {
  time: string;
  type: "alta" | "bassa";
  height: number;
  stimato: boolean;
}

interface WeekTideEvent extends TideExtreme {
  date: string; // YYYY-MM-DD
}

interface MoonData {
  phaseName: string;
  illuminationPercent: number;
  moonrise: string | null;
  moonset: string | null;
  upperTransit: string | null;
  lowerTransit: string | null;
}

const SAVED_KEY = "maree_locations";

function loadSaved(): GeoResult[] {
  if (typeof window === "undefined") return [];
  try {
    return JSON.parse(localStorage.getItem(SAVED_KEY) || "[]");
  } catch {
    return [];
  }
}

function saveLocation(loc: GeoResult) {
  const saved = loadSaved().filter((l) => l.id !== loc.id);
  saved.unshift(loc);
  localStorage.setItem(SAVED_KEY, JSON.stringify(saved.slice(0, 6)));
}

function removeLocation(id: number) {
  const saved = loadSaved().filter((l) => l.id !== id);
  localStorage.setItem(SAVED_KEY, JSON.stringify(saved));
}

function nextDays(count: number): { iso: string; label: string }[] {
  const days = [];
  const dayLabels = ["Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"];
  for (let i = 0; i < count; i++) {
    const d = new Date();
    d.setDate(d.getDate() + i);
    const iso = d.toLocaleDateString("sv-SE");
    const label = i === 0 ? "Oggi" : i === 1 ? "Domani" : `${dayLabels[d.getDay()]} ${d.getDate()}`;
    days.push({ iso, label });
  }
  return days;
}

export default function MareePage() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<GeoResult[]>([]);
  const [searching, setSearching] = useState(false);
  const [selected, setSelected] = useState<GeoResult | null>(null);
  const [saved, setSaved] = useState<GeoResult[]>([]);
  const [selectedDate, setSelectedDate] = useState(nextDays(1)[0].iso);

  const [weekEvents, setWeekEvents] = useState<WeekTideEvent[] | null>(null);
  const [moon, setMoon] = useState<MoonData | null>(null);
  const [loadingTides, setLoadingTides] = useState(false);
  const [loadingMoon, setLoadingMoon] = useState(false);
  const [dataError, setDataError] = useState<string | null>(null);

  useEffect(() => {
    setSaved(loadSaved());
  }, []);

  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([]);
      return;
    }
    setSearching(true);
    const t = setTimeout(() => {
      fetch(`/api/geocode?q=${encodeURIComponent(query)}`)
        .then((r) => r.json())
        .then((d) => setResults(d.ok ? d.results : []))
        .finally(() => setSearching(false));
    }, 350);
    return () => clearTimeout(t);
  }, [query]);

  const fetchMoon = useCallback((loc: GeoResult, dateIso: string) => {
    setLoadingMoon(true);
    fetch(`/api/maree/moon?lat=${loc.latitude}&lon=${loc.longitude}&tz=${encodeURIComponent(loc.timezone)}&date=${dateIso}`)
      .then((r) => r.json())
      .then((d) => setMoon(d.ok ? d.moon : null))
      .catch(() => setMoon(null))
      .finally(() => setLoadingMoon(false));
  }, []);

  // Le maree si scaricano UNA SOLA VOLTA per località (1 credito copre 7 giorni) —
  // cambiare giorno non fa nuove richieste, filtra solo i dati già scaricati.
  const loadLocationData = useCallback(
    (loc: GeoResult) => {
      setSelected(loc);
      setQuery("");
      setResults([]);
      setDataError(null);
      saveLocation(loc);
      setSaved(loadSaved());

      setLoadingTides(true);
      fetch(`/api/maree/tides?lat=${loc.latitude}&lon=${loc.longitude}`)
        .then((r) => r.json())
        .then((d) => {
          if (!d.ok) {
            setDataError(d.error || "Maree non disponibili per questa località.");
            setWeekEvents(null);
            return;
          }
          setWeekEvents(d.events);
        })
        .catch(() => setDataError("Errore nel recupero delle maree. Riprova."))
        .finally(() => setLoadingTides(false));

      fetchMoon(loc, selectedDate);
    },
    [fetchMoon, selectedDate]
  );

  const changeDay = useCallback(
    (dateIso: string) => {
      setSelectedDate(dateIso);
      if (selected) fetchMoon(selected, dateIso);
    },
    [selected, fetchMoon]
  );

  const todayTides: TideExtreme[] = weekEvents
    ? weekEvents.filter((e) => e.date === selectedDate).map(({ time, type, height, stimato }) => ({ time, type, height, stimato }))
    : [];

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Maree e luna
        </h1>

        <div className="flex items-center gap-2 bg-white border border-[#E1DFD6] rounded-xl px-3.5 py-2.5 mb-3">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca una località… es. Livorno, Gaeta"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        {searching && <p className="text-xs text-[#6B7E82] mb-2">Cerco…</p>}

        {results.length > 0 && (
          <div className="bg-white border border-[#E1DFD6] rounded-xl mb-3 overflow-hidden">
            {results.map((r) => (
              <button
                key={r.id}
                onClick={() => loadLocationData(r)}
                className="w-full text-left px-3.5 py-2.5 text-sm border-b border-[#E1DFD6] last:border-0 hover:bg-[#F6F5F1]"
              >
                {r.name}
                <span className="text-[#6B7E82]"> — {r.admin1 ? r.admin1 + ", " : ""}{r.country}</span>
              </button>
            ))}
          </div>
        )}

        {saved.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-4">
            {saved.map((s) => (
              <div
                key={s.id}
                className={`flex items-center gap-1 pl-2.5 pr-1 py-1 rounded-full border text-[11px] font-mono ${
                  selected?.id === s.id
                    ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                    : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                }`}
              >
                <button onClick={() => loadLocationData(s)}>📍 {s.name}</button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    removeLocation(s.id);
                    setSaved(loadSaved());
                  }}
                  className={`w-4 h-4 rounded-full flex items-center justify-center text-[10px] ml-0.5 ${
                    selected?.id === s.id ? "hover:bg-white/20" : "hover:bg-[#eeece3]"
                  }`}
                  aria-label={`Rimuovi ${s.name}`}
                >
                  ×
                </button>
              </div>
            ))}
          </div>
        )}

        {!selected && (
          <p className="text-sm text-[#6B7E82] mt-6">
            Cerca una località costiera per vedere maree e dati lunari.
          </p>
        )}

        {selected && (
          <div className="flex gap-1.5 overflow-x-auto pb-1 mb-4 -mx-1 px-1">
            {nextDays(6).map((d) => (
              <button
                key={d.iso}
                onClick={() => changeDay(d.iso)}
                className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
                  selectedDate === d.iso
                    ? "bg-[#0F2D3D] text-white border-[#0F2D3D]"
                    : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                }`}
              >
                {d.label}
              </button>
            ))}
          </div>
        )}

        {loadingTides && <p className="text-sm text-[#6B7E82]">Carico le maree…</p>}

        {dataError && (
          <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-sm text-[#6B7E82] mb-4">
            {dataError}
          </div>
        )}

        {selected && !loadingTides && weekEvents && (
          <>
            <div className="bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-5 mb-2">
              <div className="text-[11px] uppercase tracking-widest text-[#D98E4A] mb-1">
                {selected.name}
              </div>
              <h2 className="text-[19px] font-medium mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
                {nextDays(6).find((d) => d.iso === selectedDate)?.label || "Oggi"}
              </h2>
              {todayTides.length === 0 ? (
                <p className="text-sm text-[#a9bcc2]">Nessun dato di marea per questo giorno.</p>
              ) : (
                <div className="flex flex-wrap gap-4">
                  {todayTides.map((t, i) => (
                    <div key={i} className="text-center">
                      <div className="font-mono text-[17px]">{t.time}</div>
                      <div className="text-[10px] text-[#a9bcc2] uppercase tracking-wide mt-0.5">
                        {t.type === "alta" ? "Alta" : "Bassa"} · {t.height}m
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <p className="text-[11px] text-[#6B7E82] mb-4 px-1 leading-relaxed">
              ⓘ Previsioni di marea reali (WorldTides). Non sono un dato ufficiale di navigazione.
            </p>
          </>
        )}

        {selected && !loadingMoon && moon && (
          <>
            <div className="text-[11px] uppercase tracking-widest text-[#6B7E82] mb-2">Luna</div>
            <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 mb-2.5 flex items-center gap-3">
              <div className="text-2xl">🌔</div>
              <div>
                <div className="text-sm font-medium">{moon.phaseName}</div>
                <div className="text-[11px] text-[#6B7E82]">{moon.illuminationPercent}% illuminata</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2.5 mb-2.5">
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.moonrise || "—"}</div>
                <div className="text-[10px] text-[#6B7E82] uppercase mt-1">Alba lunare</div>
              </div>
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.moonset || "—"}</div>
                <div className="text-[10px] text-[#6B7E82] uppercase mt-1">Tramonto lunare</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2.5">
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.upperTransit || "—"}</div>
                <div className="text-[10px] text-[#6B7E82] uppercase mt-1">Transito superiore</div>
              </div>
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.lowerTransit || "—"}</div>
                <div className="text-[10px] text-[#6B7E82] uppercase mt-1">Transito inferiore</div>
              </div>
            </div>
          </>
        )}
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/diario/[bookId]/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import { BOOKS, BookId } from "@/lib/books";
import { DIARIO_TEMPLATES } from "@/lib/diario-templates";
import DiarioForm from "@/components/DiarioForm";

// Link Drive reali forniti da Enrico + argomenti dei 4 PDF per libro
const PDF_FOLDERS: Record<string, { link: string; topics: string }> = {
  feeder: {
    link: "https://drive.google.com/drive/folders/1x3cVL9F61G6g7b6Q3gmwp7dLVxY9AZfV",
    topics: "Feeder generale, Pasturazione, Attrezzatura, Lenze Feeder",
  },
  "mare-e-foce": {
    link: "https://drive.google.com/drive/folders/1Q2wTAyLYlg0hmYlo9l-H-1ZRWANmzS5a",
    topics: "Mare e Foce, Maree, Luna, Lenze",
  },
};

export default async function DiarioBookPage({
  params,
}: {
  params: Promise<{ bookId: string }>;
}) {
  const { bookId } = await params;
  const book = BOOKS[bookId as BookId];
  const cookieStore = await cookies();
  const unlocked = cookieStore.get(`unlock_${bookId}`)?.value === "1";

  if (!book || !(bookId in DIARIO_TEMPLATES)) {
    return (
      <main className="min-h-screen flex items-center justify-center bg-[#F6F5F1]">
        <p className="text-[#6B7E82]">Libro non trovato.</p>
      </main>
    );
  }

  if (!unlocked) {
    return (
      <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
        <div className="w-full max-w-md p-5 text-center pt-20">
          <div className="text-4xl mb-4">🔒</div>
          <h1 className="text-lg font-medium mb-2">{book.name}</h1>
          <p className="text-sm text-[#6B7E82] mb-6">
            Inquadra il QR nella prima pagina della tua copia per sbloccare i contenuti.
          </p>
          <Link href="/" className="text-sm text-[#2C6E71] underline">
            ← Torna alla home
          </Link>
        </div>
      </main>
    );
  }

  const template = DIARIO_TEMPLATES[bookId as "feeder" | "mare-e-foce"];
  const pdf = PDF_FOLDERS[bookId];

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          {book.name}
        </h1>

        <a
          href={pdf.link}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-3 bg-[#0F2D3D] text-white rounded-xl p-3.5 mb-5"
        >
          <div className="w-10 h-10 rounded-lg bg-[#D98E4A] text-[#0F2D3D] flex items-center justify-center text-lg flex-shrink-0">
            📁
          </div>
          <div className="flex-1">
            <h3 className="text-sm font-semibold">I tuoi 4 PDF — {book.name}</h3>
            <p className="text-[11px] text-[#a9bcc2]">{pdf.topics}</p>
          </div>
          <span className="text-[11px] bg-[#2C6E71] px-2.5 py-1.5 rounded-md flex-shrink-0">
            Apri
          </span>
        </a>

        <DiarioForm bookId={bookId as BookId} template={template} />
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/articoli/page.tsx" << 'SETUP_EOF_MARKER'
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
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
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
              <h3 className="text-[14px] leading-snug" style={{ fontFamily: "var(--font-fraunces)" }}>
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

SETUP_EOF_MARKER
cat > "components/DiarioForm.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState } from "react";
import { BookId } from "@/lib/books";
import { DiarioTemplate } from "@/lib/diario-templates";

function getDeviceId(): string {
  const key = "device_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

interface Entry {
  id: string;
  createdAt: string;
  data: Record<string, string>;
}

export default function DiarioForm({
  bookId,
  template,
}: {
  bookId: BookId;
  template: DiarioTemplate;
}) {
  const [formOpen, setFormOpen] = useState(false);
  const [values, setValues] = useState<Record<string, string>>({});
  const [entries, setEntries] = useState<Entry[]>([]);
  const [saving, setSaving] = useState(false);

  const deviceId = typeof window !== "undefined" ? getDeviceId() : "";

  useEffect(() => {
    if (!deviceId) return;
    fetch(`/api/diario?bookId=${bookId}&deviceId=${deviceId}`)
      .then((r) => r.json())
      .then((d) => {
        if (d.ok) setEntries(d.entries);
      });
  }, [bookId, deviceId]);

  function setField(key: string, value: string) {
    setValues((v) => ({ ...v, [key]: value }));
  }

  async function save() {
    setSaving(true);
    const res = await fetch("/api/diario", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ bookId, deviceId, data: values }),
    });
    const d = await res.json();
    setSaving(false);
    if (d.ok) {
      setEntries((e) => [d.entry, ...e]);
      setValues({});
      setFormOpen(false);
    }
  }

  async function remove(id: string) {
    const res = await fetch(`/api/diario/${id}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ deviceId }),
    });
    const d = await res.json();
    if (d.ok) setEntries((e) => e.filter((x) => x.id !== id));
  }

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <h2 className="font-medium text-lg" style={{ fontFamily: "var(--font-fraunces)" }}>
          Il tuo diario digitale
        </h2>
        <button
          onClick={() => setFormOpen((o) => !o)}
          className="w-8 h-8 rounded-full bg-[#2C6E71] text-white text-lg flex items-center justify-center"
        >
          {formOpen ? "×" : "+"}
        </button>
      </div>

      {formOpen && (
        <div className="space-y-3">
          {template.map((section, i) => (
            <div key={i} className="bg-white border border-[#E1DFD6] rounded-xl p-3.5">
              <h4 className="text-[11px] uppercase tracking-widest text-[#2C6E71] mb-2.5 pb-2 border-b border-[#E1DFD6]">
                {section.title}
              </h4>

              {"fields" in section && (
                <div className="grid grid-cols-2 gap-2.5">
                  {section.fields.map((f) => (
                    <div key={f.key} className={f.type === "textarea" ? "col-span-2" : ""}>
                      {f.label && (
                        <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">
                          {f.label}
                        </label>
                      )}
                      {f.type === "textarea" ? (
                        <textarea
                          className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1] h-16"
                          placeholder={f.placeholder}
                          value={values[f.key] || ""}
                          onChange={(e) => setField(f.key, e.target.value)}
                        />
                      ) : (
                        <input
                          type={f.type}
                          className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1]"
                          placeholder={f.placeholder}
                          value={values[f.key] || ""}
                          onChange={(e) => setField(f.key, e.target.value)}
                        />
                      )}
                    </div>
                  ))}
                </div>
              )}

              {"type" in section && section.type === "table" && (
                <table className="w-full text-xs">
                  <thead>
                    <tr>
                      {section.columns.map((c) => (
                        <th key={c.key} className="text-left text-[9px] uppercase text-[#6B7E82] pb-1">
                          {c.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {[0, 1, 2].map((row) => (
                      <tr key={row}>
                        {section.columns.map((c) => (
                          <td key={c.key} className="border-t border-[#E1DFD6] py-1">
                            <input
                              className="w-full bg-transparent text-xs"
                              value={values[`${c.key}_${row}`] || ""}
                              onChange={(e) => setField(`${c.key}_${row}`, e.target.value)}
                            />
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}

              {"type" in section && section.type === "boxes" && (
                <>
                  <div className="grid grid-cols-2 gap-2.5">
                    {section.boxes.map((b) => (
                      <div key={b.key}>
                        <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">
                          {b.label}
                        </label>
                        <input
                          className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1]"
                          placeholder="note"
                          value={values[b.key] || ""}
                          onChange={(e) => setField(b.key, e.target.value)}
                        />
                      </div>
                    ))}
                  </div>
                  {section.extraField && (
                    <div className="mt-2.5">
                      <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">
                        {section.extraField.label}
                      </label>
                      <textarea
                        className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1] h-16"
                        value={values[section.extraField.key] || ""}
                        onChange={(e) => setField(section.extraField!.key, e.target.value)}
                      />
                    </div>
                  )}
                </>
              )}
            </div>
          ))}

          <button
            onClick={save}
            disabled={saving}
            className="w-full bg-[#0F2D3D] text-white rounded-xl py-3 text-sm font-medium disabled:opacity-50"
          >
            {saving ? "Salvataggio…" : "Salva voce nel diario"}
          </button>
        </div>
      )}

      <p className="text-[11px] uppercase tracking-widest text-[#6B7E82] pt-2">
        Voci precedenti ({entries.length})
      </p>

      {entries.length === 0 && (
        <p className="text-sm text-[#6B7E82]">Nessuna voce ancora — inizia dal +</p>
      )}

      {entries.map((entry) => (
        <div key={entry.id} className="bg-white border border-[#E1DFD6] rounded-xl p-3.5">
          <div className="flex justify-between items-start mb-1.5">
            <span className="text-xs text-[#6B7E82] font-mono">
              {new Date(entry.createdAt).toLocaleDateString("it-IT", {
                day: "2-digit",
                month: "2-digit",
                year: "numeric",
              })}
            </span>
            <button
              onClick={() => remove(entry.id)}
              className="text-xs text-[#6B7E82] hover:text-red-600"
            >
              elimina
            </button>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {Object.entries(entry.data)
              .filter(([, v]) => v)
              .slice(0, 6)
              .map(([k, v]) => (
                <span
                  key={k}
                  className="text-[11px] bg-[#F6F5F1] border border-[#E1DFD6] rounded-full px-2 py-0.5"
                >
                  {v}
                </span>
              ))}
          </div>
        </div>
      ))}
    </div>
  );
}

SETUP_EOF_MARKER
cat > "package.json" << 'SETUP_EOF_MARKER'
{
  "name": "diari-pesca-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint"
  },
  "dependencies": {
    "astronomy-engine": "^2.1.19",
    "lucide-react": "^1.34.0",
    "next": "16.3.2",
    "postgres": "^3.4.9",
    "react": "19.2.8",
    "react-dom": "19.2.8"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "eslint-config-next": "16.3.2",
    "tailwindcss": "^4",
    "typescript": "^5"
  }
}

SETUP_EOF_MARKER
echo 'Installo lucide-react (icone)...'
npm install lucide-react
echo "Fatto: Fraunces/Inter/IBM Plex Mono, icone vere in home, linea di marea sotto l intestazione."