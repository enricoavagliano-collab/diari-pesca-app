#!/bin/bash
set -e
echo 'Rinnovo grafico completo: palette scura, navigazione fissa, copertine...'
mkdir -p "app"
mkdir -p "app/altro"
mkdir -p "app/articoli"
mkdir -p "app/diario"
mkdir -p "app/diario/[bookId]"
mkdir -p "app/lenze"
mkdir -p "app/maree"
mkdir -p "app/meteo"
mkdir -p "app/sblocca"
mkdir -p "app/specie"
mkdir -p "components"
mkdir -p "public/covers"
echo 'Creo/aggiorno i file di codice...'
cat > "app/layout.tsx" << 'SETUP_EOF_MARKER'
import type { Metadata, Viewport } from "next";
import { Fraunces, Inter, IBM_Plex_Mono } from "next/font/google";
import "./globals.css";
import BottomNav from "@/components/BottomNav";

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
  themeColor: "#0B1F2A",
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
      <body className="min-h-full flex flex-col bg-[#0B1F2A]">
        {children}
        <BottomNav />
      </body>
    </html>
  );
}

SETUP_EOF_MARKER
cat > "app/globals.css" << 'SETUP_EOF_MARKER'
@import "tailwindcss";

/* Palette "Libri di Pesca" — ispirata al mare e alla costa italiana */
:root {
  --background: #0B1F2A; /* Blu Profondo */
  --foreground: #F6F5F1; /* Sabbia Chiara (testo su sfondo scuro) */
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
  color: #8FA8B2;
}

SETUP_EOF_MARKER
cat > "app/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import Image from "next/image";
import { Fish, Waves, CloudSun, Anchor, CalendarDays, BookOpen, Newspaper, KeyRound } from "lucide-react";
import { BOOKS } from "@/lib/books";
import IOSInstallBanner from "@/components/IOSInstallBanner";

const COVERS: Record<string, string> = {
  feeder: "/covers/feeder.jpg",
  "mare-e-foce": "/covers/mare-e-foce.jpg",
  "senso-acqua": "/covers/senso-acqua.jpg",
};

const STRUMENTI = [
  { href: "/maree", Icon: Waves, label: "Maree e Luna" },
  { href: "/meteo", Icon: CloudSun, label: "Meteo" },
  { href: "/lenze", Icon: Anchor, label: "Le mie Lenze" },
  { href: "/specie", Icon: CalendarDays, label: "Specie e Periodi" },
  { href: "/diario", Icon: BookOpen, label: "Diario di Pesca" },
  { href: "/articoli", Icon: Newspaper, label: "Articoli e Blog" },
];

export default async function Home() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md">
        {/* Intestazione */}
        <div className="px-5 pt-6 pb-5 text-center">
          <Fish size={26} strokeWidth={1.5} className="mx-auto mb-2 text-[#F6F5F1]" />
          <h1
            className="text-[19px] tracking-wide"
            style={{ fontFamily: "var(--font-fraunces)", fontWeight: 600 }}
          >
            LIBRI DI PESCA
          </h1>
          <p className="text-[11px] text-[#8FA8B2] uppercase tracking-[0.12em] mt-0.5">
            La tua compagna di pesca
          </p>
        </div>

        <div className="px-5">
          {/* I miei libri */}
          <div className="flex items-center justify-between mb-2.5">
            <h2 className="text-[13px] uppercase tracking-[0.08em] text-[#8FA8B2] font-medium">
              I miei libri
            </h2>
            <Link href="/diario" className="text-[12px] text-[#2CA6A4]">
              Vedi tutti
            </Link>
          </div>

          <div className="flex gap-2.5 overflow-x-auto pb-1 mb-6 -mx-5 px-5">
            {books.map((book) => (
              <Link
                key={book.id}
                href={`/diario/${book.id}`}
                className="relative flex-shrink-0 w-28 rounded-lg overflow-hidden border border-white/10"
              >
                <div className="relative w-28 h-40">
                  <Image
                    src={COVERS[book.id]}
                    alt={book.name}
                    fill
                    sizes="112px"
                    className={`object-cover ${!book.unlocked ? "opacity-50" : ""}`}
                  />
                </div>
                <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent px-2 pt-4 pb-2">
                  <span
                    className={`text-[9.5px] px-1.5 py-0.5 rounded-full font-mono ${
                      book.unlocked ? "bg-[#7CB342]/30 text-[#B7E28C]" : "bg-white/15 text-[#F6F5F1]"
                    }`}
                  >
                    {book.unlocked ? "✓ Sbloccato" : "🔒 Bloccato"}
                  </span>
                </div>
              </Link>
            ))}
          </div>

          {/* Strumenti rapidi */}
          <h2 className="text-[13px] uppercase tracking-[0.08em] text-[#8FA8B2] font-medium mb-2.5">
            Strumenti rapidi
          </h2>
          <div className="grid grid-cols-2 gap-2.5 mb-6">
            {STRUMENTI.map(({ href, Icon, label }) => (
              <Link
                key={href}
                href={href}
                className="flex flex-col items-center justify-center gap-2 bg-[#124E5A] border border-white/10 rounded-xl py-4"
              >
                <Icon size={22} strokeWidth={1.6} className="text-[#2CA6A4]" />
                <span className="text-[11.5px] text-[#F6F5F1] text-center leading-tight px-1">{label}</span>
              </Link>
            ))}
          </div>

          <Link
            href="/sblocca"
            className="flex items-center justify-center gap-2 border border-dashed border-white/20 rounded-xl py-3 text-sm text-[#2CA6A4] font-medium mb-4"
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
cat > "app/diario/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import Image from "next/image";
import { BOOKS } from "@/lib/books";

const COVERS: Record<string, string> = {
  feeder: "/covers/feeder.jpg",
  "mare-e-foce": "/covers/mare-e-foce.jpg",
  "senso-acqua": "/covers/senso-acqua.jpg",
};

export default async function DiarioIndexPage() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <h1 className="text-[22px] mb-1" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          I tuoi libri
        </h1>
        <p className="text-[13px] text-[#8FA8B2] mb-5">
          Contenuti sbloccati con il QR nella prima pagina della tua copia
        </p>

        <div className="space-y-3">
          {books.map((book) => (
            <Link
              key={book.id}
              href={`/diario/${book.id}`}
              className="relative flex items-center gap-3 rounded-xl overflow-hidden border border-white/10 bg-[#124E5A]"
            >
              <div className="relative w-20 h-28 flex-shrink-0">
                <Image
                  src={COVERS[book.id]}
                  alt={book.name}
                  fill
                  sizes="80px"
                  className={`object-cover ${!book.unlocked ? "opacity-60" : ""}`}
                />
              </div>
              <div className="flex-1 py-3 pr-3">
                <h3 className="text-[15px] font-medium">{book.name}</h3>
                <span
                  className={`inline-block mt-1.5 text-[10px] px-2 py-0.5 rounded-full font-mono ${
                    book.unlocked ? "bg-[#7CB342]/20 text-[#9FD16A]" : "bg-white/10 text-[#8FA8B2]"
                  }`}
                >
                  {book.unlocked ? "✓ Sbloccato" : "🔒 Bloccato"}
                </span>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/altro/page.tsx" << 'SETUP_EOF_MARKER'
import Link from "next/link";
import { Anchor, CalendarDays, Newspaper, KeyRound, ChevronRight } from "lucide-react";

const VOCI = [
  { href: "/lenze", Icon: Anchor, title: "Le mie lenze", subtitle: "Con Mare e Foce o Diario Feeder" },
  { href: "/specie", Icon: CalendarDays, title: "Specie e periodi", subtitle: "Mare/Foce e Acqua dolce, mese per mese" },
  { href: "/articoli", Icon: Newspaper, title: "Articoli", subtitle: "Tutti i contenuti tecnici dal blog" },
  { href: "/sblocca", Icon: KeyRound, title: "Hai un codice?", subtitle: "Sbloccalo qui" },
];

export default function AltroPage() {
  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <h1 className="text-[22px] mb-5" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Altro
        </h1>

        <div className="space-y-2.5">
          {VOCI.map(({ href, Icon, title, subtitle }) => (
            <Link
              key={href}
              href={href}
              className="flex items-center gap-3 bg-[#124E5A] border border-white/10 rounded-xl p-3.5"
            >
              <div className="w-9 h-9 rounded-lg bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                <Icon size={18} strokeWidth={1.75} className="text-[#2CA6A4]" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-sm">{title}</h3>
                <p className="text-xs text-[#8FA8B2]">{subtitle}</p>
              </div>
              <ChevronRight size={16} className="text-[#8FA8B2] flex-shrink-0" />
            </Link>
          ))}
        </div>
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
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Maree e luna
        </h1>

        <div className="flex items-center gap-2 bg-[#124E5A] border border-white/10 rounded-xl px-3.5 py-2.5 mb-3">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca una località… es. Livorno, Gaeta"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        {searching && <p className="text-xs text-[#8FA8B2] mb-2">Cerco…</p>}

        {results.length > 0 && (
          <div className="bg-[#124E5A] border border-white/10 rounded-xl mb-3 overflow-hidden">
            {results.map((r) => (
              <button
                key={r.id}
                onClick={() => loadLocationData(r)}
                className="w-full text-left px-3.5 py-2.5 text-sm border-b border-white/10 last:border-0 hover:bg-[#0B1F2A]"
              >
                {r.name}
                <span className="text-[#8FA8B2]"> — {r.admin1 ? r.admin1 + ", " : ""}{r.country}</span>
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
                    ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                    : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
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
                    selected?.id === s.id ? "hover:bg-white/20" : "hover:bg-[#0B1F2A]"
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
          <p className="text-sm text-[#8FA8B2] mt-6">
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
                    ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                    : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
                }`}
              >
                {d.label}
              </button>
            ))}
          </div>
        )}

        {loadingTides && <p className="text-sm text-[#8FA8B2]">Carico le maree…</p>}

        {dataError && (
          <div className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5 text-sm text-[#8FA8B2] mb-4">
            {dataError}
          </div>
        )}

        {selected && !loadingTides && weekEvents && (
          <>
            <div className="bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-5 mb-2">
              <div className="text-[11px] uppercase tracking-widest text-[#FF9A3C] mb-1">
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
            <p className="text-[11px] text-[#8FA8B2] mb-4 px-1 leading-relaxed">
              ⓘ Previsioni di marea reali (WorldTides). Non sono un dato ufficiale di navigazione.
            </p>
          </>
        )}

        {selected && !loadingMoon && moon && (
          <>
            <div className="text-[11px] uppercase tracking-widest text-[#8FA8B2] mb-2">Luna</div>
            <div className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5 mb-2.5 flex items-center gap-3">
              <div className="text-2xl">🌔</div>
              <div>
                <div className="text-sm font-medium">{moon.phaseName}</div>
                <div className="text-[11px] text-[#8FA8B2]">{moon.illuminationPercent}% illuminata</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2.5 mb-2.5">
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.moonrise || "—"}</div>
                <div className="text-[10px] text-[#8FA8B2] uppercase mt-1">Alba lunare</div>
              </div>
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.moonset || "—"}</div>
                <div className="text-[10px] text-[#8FA8B2] uppercase mt-1">Tramonto lunare</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2.5">
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.upperTransit || "—"}</div>
                <div className="text-[10px] text-[#8FA8B2] uppercase mt-1">Transito superiore</div>
              </div>
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5 text-center">
                <div className="font-mono text-sm">{moon.lowerTransit || "—"}</div>
                <div className="text-[10px] text-[#8FA8B2] uppercase mt-1">Transito inferiore</div>
              </div>
            </div>
          </>
        )}
      </div>
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
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Meteo
        </h1>

        <div className="flex items-center gap-2 bg-[#124E5A] border border-white/10 rounded-xl px-3.5 py-2.5 mb-3">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca una località… es. Livorno, Gaeta"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        {searching && <p className="text-xs text-[#8FA8B2] mb-2">Cerco…</p>}

        {results.length > 0 && (
          <div className="bg-[#124E5A] border border-white/10 rounded-xl mb-3 overflow-hidden">
            {results.map((r) => (
              <button
                key={r.id}
                onClick={() => loadLocationData(r)}
                className="w-full text-left px-3.5 py-2.5 text-sm border-b border-white/10 last:border-0 hover:bg-[#0B1F2A]"
              >
                {r.name}
                <span className="text-[#8FA8B2]"> — {r.admin1 ? r.admin1 + ", " : ""}{r.country}</span>
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
                    ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                    : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
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
                    selected?.id === s.id ? "hover:bg-white/20" : "hover:bg-[#0B1F2A]"
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
          <p className="text-sm text-[#8FA8B2] mt-6">
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
                    : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
                }`}
              >
                {d.label}
              </button>
            ))}
          </div>
        )}

        {loading && <p className="text-sm text-[#8FA8B2]">Carico il meteo…</p>}

        {dataError && (
          <div className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5 text-sm text-[#8FA8B2] mb-4">
            {dataError}
          </div>
        )}

        {selected && !loading && todayWeather && (
          <>
            <div className="text-[11px] uppercase tracking-widest text-[#FF9A3C] mb-1">
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
                  <div className="text-[11px] uppercase tracking-widest text-[#8FA8B2] mb-2">
                    {group.label}
                  </div>
                  <div className="bg-[#124E5A] border border-white/10 rounded-xl overflow-hidden">
                    {groupSlots.map((s, i) => (
                      <div
                        key={s.time}
                        className={`flex items-center gap-3 px-3.5 py-2.5 ${
                          i > 0 ? "border-t border-white/10" : ""
                        }`}
                      >
                        <span className="font-mono text-[12.5px] text-[#8FA8B2] w-10 flex-shrink-0">
                          {s.time.slice(0, 5)}
                        </span>
                        <span className="text-base flex-shrink-0">{s.icon}</span>
                        <span className="text-[12.5px] flex-1">{s.tempC}°</span>
                        <span className="text-[12px] text-[#8FA8B2] flex-shrink-0">
                          {s.windSpeed}km/h {windDirectionLabel(s.windDirection)}
                        </span>
                        <span className="text-[12px] text-[#8FA8B2] flex-shrink-0 w-14 text-right">
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
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-white/10">
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Madre</div>
                    <div className="font-mono text-[12.5px]">{spec.madre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Finale</div>
                    <div className="font-mono text-[12.5px]">{spec.finale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Galleggiante</div>
                    <div className="font-mono text-[12.5px]">{spec.galleggiante}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{spec.amo}</div>
                  </div>
                  <div className="col-span-2">
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Piombatura</div>
                    <div className="text-[12.5px] leading-relaxed">{spec.piombatura}</div>
                  </div>
                </div>
                <p className="text-[12px] text-[#8FA8B2] italic mt-3 leading-relaxed">{spec.nota}</p>

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
cat > "app/specie/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useState } from "react";
import Link from "next/link";
import { getSpecieByCategory, MONTH_LABELS, RATING_LABELS, SpecieCategory, Rating } from "@/lib/specie";

function ratingColor(r: Rating): string {
  if (r === 3) return "bg-[#2CA6A4] text-white";
  if (r === 2) return "bg-[#FF9A3C]/25 text-[#FFC98A]";
  return "bg-[#0B1F2A] text-[#8FA8B2]";
}

export default function SpeciePage() {
  const [category, setCategory] = useState<SpecieCategory>("mare");
  const specieList = getSpecieByCategory(category);

  return (
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
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
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🌊 Mare / Foce
          </button>
          <button
            onClick={() => setCategory("dolce")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "dolce"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            💧 Acqua dolce
          </button>
        </div>

        <div className="flex items-center gap-3 mb-4 text-[10.5px] text-[#8FA8B2]">
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#0B1F2A] inline-block"></span> Non buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#FF9A3C]/25 inline-block"></span> Buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#2CA6A4] inline-block"></span> Ottimo
          </span>
        </div>

        <div className="space-y-4">
          {specieList.map((specie) => (
            <div key={specie.name} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
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
                    <div className="text-[9.5px] text-[#8FA8B2] mt-1">{MONTH_LABELS[i]}</div>
                  </div>
                ))}
              </div>
              <p className="text-[12px] text-[#8FA8B2] italic leading-relaxed pt-2.5 border-t border-white/10">
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
          {filtered.map((a) => (
            <a
              key={a.url}
              href={a.url}
              target="_blank"
              rel="noopener noreferrer"
              className="block bg-[#124E5A] border border-white/10 rounded-xl p-3.5"
            >
              <div className="flex items-start justify-between gap-3 mb-1">
                <span className="text-[10px] font-mono uppercase tracking-wide text-[#FF9A3C]">
                  {a.tag}
                </span>
                <span className="text-[#8FA8B2] text-sm flex-shrink-0">↗</span>
              </div>
              <h3 className="text-[14px] leading-snug" style={{ fontFamily: "var(--font-fraunces)" }}>
                {a.title}
              </h3>
              <p className="text-[11px] text-[#8FA8B2] mt-1.5">Leggi sul blog</p>
            </a>
          ))}
        </div>
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
      <main className="min-h-screen flex items-center justify-center bg-[#0B1F2A]">
        <p className="text-[#8FA8B2]">Libro non trovato.</p>
      </main>
    );
  }

  if (!unlocked) {
    return (
      <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
        <div className="w-full max-w-md p-5 pb-24 text-center pt-20">
          <div className="text-4xl mb-4">🔒</div>
          <h1 className="text-lg font-medium mb-2">{book.name}</h1>
          <p className="text-sm text-[#8FA8B2] mb-6">
            Inquadra il QR nella prima pagina della tua copia per sbloccare i contenuti.
          </p>
          <Link href="/" className="text-sm text-[#2CA6A4] underline">
            ← Torna alla home
          </Link>
        </div>
      </main>
    );
  }

  const template = DIARIO_TEMPLATES[bookId as "feeder" | "mare-e-foce"];
  const pdf = PDF_FOLDERS[bookId];

  return (
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
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
          <div className="w-10 h-10 rounded-lg bg-[#FF9A3C] text-[#0F2D3D] flex items-center justify-center text-lg flex-shrink-0">
            📁
          </div>
          <div className="flex-1">
            <h3 className="text-sm font-semibold">I tuoi 4 PDF — {book.name}</h3>
            <p className="text-[11px] text-[#a9bcc2]">{pdf.topics}</p>
          </div>
          <span className="text-[11px] bg-[#2CA6A4] px-2.5 py-1.5 rounded-md flex-shrink-0">
            Apri
          </span>
        </a>

        <DiarioForm bookId={bookId as BookId} template={template} />
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
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
            className="w-full text-center bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-sm text-white placeholder-white/40 outline-none focus:border-[#FF9A3C]"
          />
          <button
            type="submit"
            disabled={submitting || !manualCode.trim()}
            className="w-full bg-[#FF9A3C] text-[#0F2D3D] font-semibold rounded-lg py-3 text-sm disabled:opacity-50"
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
          className="w-8 h-8 rounded-full bg-[#2CA6A4] text-white text-lg flex items-center justify-center"
        >
          {formOpen ? "×" : "+"}
        </button>
      </div>

      {formOpen && (
        <div className="space-y-3">
          {template.map((section, i) => (
            <div key={i} className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5">
              <h4 className="text-[11px] uppercase tracking-widest text-[#2CA6A4] mb-2.5 pb-2 border-b border-white/10">
                {section.title}
              </h4>

              {"fields" in section && (
                <div className="grid grid-cols-2 gap-2.5">
                  {section.fields.map((f) => (
                    <div key={f.key} className={f.type === "textarea" ? "col-span-2" : ""}>
                      {f.label && (
                        <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">
                          {f.label}
                        </label>
                      )}
                      {f.type === "textarea" ? (
                        <textarea
                          className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A] h-16"
                          placeholder={f.placeholder}
                          value={values[f.key] || ""}
                          onChange={(e) => setField(f.key, e.target.value)}
                        />
                      ) : (
                        <input
                          type={f.type}
                          className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A]"
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
                        <th key={c.key} className="text-left text-[9px] uppercase text-[#8FA8B2] pb-1">
                          {c.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {[0, 1, 2].map((row) => (
                      <tr key={row}>
                        {section.columns.map((c) => (
                          <td key={c.key} className="border-t border-white/10 py-1">
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
                        <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">
                          {b.label}
                        </label>
                        <input
                          className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A]"
                          placeholder="note"
                          value={values[b.key] || ""}
                          onChange={(e) => setField(b.key, e.target.value)}
                        />
                      </div>
                    ))}
                  </div>
                  {section.extraField && (
                    <div className="mt-2.5">
                      <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">
                        {section.extraField.label}
                      </label>
                      <textarea
                        className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A] h-16"
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

      <p className="text-[11px] uppercase tracking-widest text-[#8FA8B2] pt-2">
        Voci precedenti ({entries.length})
      </p>

      {entries.length === 0 && (
        <p className="text-sm text-[#8FA8B2]">Nessuna voce ancora — inizia dal +</p>
      )}

      {entries.map((entry) => (
        <div key={entry.id} className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5">
          <div className="flex justify-between items-start mb-1.5">
            <span className="text-xs text-[#8FA8B2] font-mono">
              {new Date(entry.createdAt).toLocaleDateString("it-IT", {
                day: "2-digit",
                month: "2-digit",
                year: "numeric",
              })}
            </span>
            <button
              onClick={() => remove(entry.id)}
              className="text-xs text-[#8FA8B2] hover:text-red-600"
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
                  className="text-[11px] bg-[#0B1F2A] border border-white/10 rounded-full px-2 py-0.5"
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
cat > "components/BottomNav.tsx" << 'SETUP_EOF_MARKER'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Waves, CloudSun, BookOpen, MoreHorizontal } from "lucide-react";

const TABS = [
  { href: "/", label: "Home", Icon: Home },
  { href: "/maree", label: "Maree", Icon: Waves },
  { href: "/meteo", label: "Meteo", Icon: CloudSun },
  { href: "/diario", label: "Diario", Icon: BookOpen },
  { href: "/altro", label: "Altro", Icon: MoreHorizontal },
];

export default function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-[#0B1F2A] border-t border-white/10">
      <div className="max-w-md mx-auto flex" style={{ paddingBottom: "max(6px, env(safe-area-inset-bottom))" }}>
        {TABS.map(({ href, label, Icon }) => {
          const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className="flex-1 flex flex-col items-center gap-1 py-2.5"
            >
              <Icon
                size={20}
                strokeWidth={active ? 2.25 : 1.75}
                className={active ? "text-[#FF9A3C]" : "text-[#8FA8B2]"}
              />
              <span className={`text-[10.5px] ${active ? "text-[#FF9A3C] font-medium" : "text-[#8FA8B2]"}`}>
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
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
echo 'Creo le copertine placeholder...'
echo "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wF12AuuwF12AuuwF12AuuwMTNgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLGOTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQGTFQODAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAY5MW3MmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLDJiwyYsMmLHBgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwF12AuuwMQ2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMcmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYDJgMmAyYHAZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABrbYFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFgLAWAsBYCwFjHJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOgyY6DJjoMmOhxddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsBddgLrsDEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABjdmem1F2Oii7HRRdjooux0UXY6KLsdFF2Oii7HRRdjooux0UXY6KLsdFF2Oii7HRRdjooux0UXY6KLsdFF2Oii7HRRdjooux0UXY6KLsdFF2Oii7HRRdjooux0UXY6KLsdFF2Oii7HRRdjooux0UXY6KLsdFF2Oii7HRRdjooux0UXY6KLsdFF2Oii7HRRdjooux0UXY6KLsdFF2OinBhkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2oBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBRdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoBdALoDEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABjdmttqLsWUXYsouxZRdiyi7FlF2LKLsWUXYsouxZRdiyi7FlF2LKLsWUXYsouxZRdiyi7FlF2LKLsWUXYsouxZRdiyi7FlF2LKLsWUXYsouxZRdiyi7FlF2LKLsWUXYsouxZRdiyi7FlF2LKLsWUXYsouxZRdiyi7FlF2LKLsWUXYsouxZRdiyi7FlF2LKLsWU4MMgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAXQZougUXQKLoFF0Ci6BRdAougUXQKLoFF0Ci6BRdAougUXQKLoFF0Ci6BRdAougUXQKLoFF0Ci6BRdAougUXQKLoFF0Ci6BRdAougUXQKLoFF0Ci6BRdAougUXQKLoFF0Ci6BRdAougUXQKLoFF0Ci6BRdAougUxDYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2AuwF2B//2Q==" | base64 -d > "public/covers/feeder.jpg"
echo "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" | base64 -d > "public/covers/mare-e-foce.jpg"
echo "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFcWHhiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwGLAYsBiwLgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAF1lwGJZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcALLgBZcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFcWe0GLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFBixQYsUGLFC4MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACuLPbgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgMWLgXCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFAKAUAoBQCgFC6y4PAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuAFlwAsuABk8sBYCwFgLAWAsBYCwFgLAWAsBYCw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" | base64 -d > "public/covers/senso-acqua.jpg"
echo 'Installo lucide-react (icone)...'
npm install lucide-react
echo "Fatto: nuova palette scura, barra di navigazione fissa, pagine Diario e Altro, copertine placeholder."