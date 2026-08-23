#!/bin/bash
set -e
echo 'Creo le cartelle...'
mkdir -p "app"
mkdir -p "app/api/geocode"
mkdir -p "app/api/maree"
mkdir -p "app/maree"
mkdir -p "lib"
echo 'Aggiungo/aggiorno i file...'
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
cat > "lib/moon.ts" << 'SETUP_EOF_MARKER'
import * as Astronomy from "astronomy-engine";

export interface MoonData {
  phaseName: string;
  illuminationPercent: number;
  moonrise: string | null; // HH:mm locale, null se non sorge in quel giorno
  moonset: string | null;
  upperTransit: string | null; // "transito superiore" — la luna è più alta in cielo
  lowerTransit: string | null; // "transito inferiore" — la luna è opposta, sotto l'orizzonte
}

const PHASE_NAMES = [
  { max: 1, name: "Luna nuova" },
  { max: 49, name: "Luna crescente" },
  { max: 51, name: "Primo quarto" },
  { max: 99, name: "Gibbosa crescente" },
  { max: 100.01, name: "Luna piena" },
];

function phaseNameFromAngle(phaseAngleDeg: number, illumination: number): string {
  // phaseAngleDeg: 0 = luna nuova, 180 = luna piena, cresce 0→360 in un ciclo
  const waxing = phaseAngleDeg < 180;
  if (illumination < 1.5) return "Luna nuova";
  if (illumination > 98.5) return "Luna piena";
  if (Math.abs(illumination - 50) < 3) {
    return waxing ? "Primo quarto" : "Ultimo quarto";
  }
  if (illumination < 50) {
    return waxing ? "Luna crescente" : "Luna calante";
  }
  return waxing ? "Gibbosa crescente" : "Gibbosa calante";
}

function formatTime(date: Date | null, timezone: string): string | null {
  if (!date) return null;
  return date.toLocaleTimeString("it-IT", {
    hour: "2-digit",
    minute: "2-digit",
    timeZone: timezone,
  });
}

export function getMoonData(
  lat: number,
  lon: number,
  date: Date,
  timezone: string
): MoonData {
  const observer = new Astronomy.Observer(lat, lon, 0);

  // Fase e illuminazione
  const illumInfo = Astronomy.Illumination(Astronomy.Body.Moon, date);
  const illuminationPercent = Math.round(illumInfo.phase_fraction * 100);
  const phaseAngle = Astronomy.MoonPhase(date); // 0-360

  // Alba/tramonto lunare: cerca eventi nelle 24h a partire da inizio giornata locale
  const startOfDay = new Date(date);
  startOfDay.setUTCHours(0, 0, 0, 0);

  let moonrise: Date | null = null;
  let moonset: Date | null = null;
  try {
    const riseEvent = Astronomy.SearchRiseSet(
      Astronomy.Body.Moon,
      observer,
      +1,
      startOfDay,
      1
    );
    moonrise = riseEvent ? riseEvent.date : null;
  } catch {
    moonrise = null;
  }
  try {
    const setEvent = Astronomy.SearchRiseSet(
      Astronomy.Body.Moon,
      observer,
      -1,
      startOfDay,
      1
    );
    moonset = setEvent ? setEvent.date : null;
  } catch {
    moonset = null;
  }

  // Transito superiore (culminazione, la luna passa per il meridiano, punto più alto)
  // e transito inferiore (12h circa dopo/prima, punto opposto)
  let upperTransit: Date | null = null;
  let lowerTransit: Date | null = null;
  try {
    const upper = Astronomy.SearchHourAngle(
      Astronomy.Body.Moon,
      observer,
      0,
      startOfDay,
      1
    );
    upperTransit = upper ? upper.time.date : null;
  } catch {
    upperTransit = null;
  }
  try {
    const lower = Astronomy.SearchHourAngle(
      Astronomy.Body.Moon,
      observer,
      12,
      startOfDay,
      1
    );
    lowerTransit = lower ? lower.time.date : null;
  } catch {
    lowerTransit = null;
  }

  return {
    phaseName: phaseNameFromAngle(phaseAngle, illuminationPercent),
    illuminationPercent,
    moonrise: formatTime(moonrise, timezone),
    moonset: formatTime(moonset, timezone),
    upperTransit: formatTime(upperTransit, timezone),
    lowerTransit: formatTime(lowerTransit, timezone),
  };
}

SETUP_EOF_MARKER
cat > "lib/geocode.ts" << 'SETUP_EOF_MARKER'
export interface GeocodeResult {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  country: string;
  admin1?: string; // regione
  timezone: string;
}

export async function searchLocations(query: string): Promise<GeocodeResult[]> {
  const url = new URL("https://geocoding-api.open-meteo.com/v1/search");
  url.searchParams.set("name", query);
  url.searchParams.set("count", "6");
  url.searchParams.set("language", "it");
  url.searchParams.set("format", "json");

  const res = await fetch(url.toString());
  if (!res.ok) return [];

  const data = await res.json();
  if (!data.results) return [];

  return data.results.map((r: {
    id: number;
    name: string;
    latitude: number;
    longitude: number;
    country?: string;
    admin1?: string;
    timezone: string;
  }) => ({
    id: r.id,
    name: r.name,
    latitude: r.latitude,
    longitude: r.longitude,
    country: r.country || "",
    admin1: r.admin1,
    timezone: r.timezone,
  }));
}

SETUP_EOF_MARKER
cat > "lib/tides.ts" << 'SETUP_EOF_MARKER'
export interface TideExtreme {
  time: string; // HH:mm locale
  type: "alta" | "bassa";
  height: number; // metri, relativo al livello medio del mare (non è un datum di navigazione)
}

export interface TideForecast {
  today: TideExtreme[];
  hourlySeries: { time: string; height: number }[]; // per disegnare il grafico
  timezone: string;
}

export async function getTideForecast(
  lat: number,
  lon: number
): Promise<TideForecast | null> {
  const url = new URL("https://marine-api.open-meteo.com/v1/marine");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set("hourly", "sea_level_height_msl");
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", "1");
  url.searchParams.set("past_days", "1"); // serve un'ora prima per rilevare un picco a mezzanotte

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  const times: string[] = data?.hourly?.time || [];
  const heights: (number | null)[] = data?.hourly?.sea_level_height_msl || [];
  const timezone: string = data?.timezone || "UTC";

  if (times.length === 0 || heights.every((h) => h === null)) return null;

  // Isola solo le ore di "oggi" (il timezone locale, non UTC)
  const todayStr = new Date().toLocaleDateString("sv-SE", { timeZone: timezone }); // YYYY-MM-DD

  const series = times
    .map((t, i) => ({ time: t, height: heights[i] }))
    .filter((p): p is { time: string; height: number } => p.height !== null);

  // Trova i picchi locali (massimi e minimi) confrontando ogni punto con i vicini
  const extremes: TideExtreme[] = [];
  for (let i = 1; i < series.length - 1; i++) {
    const prev = series[i - 1].height;
    const curr = series[i].height;
    const next = series[i + 1].height;
    const isDay = series[i].time.startsWith(todayStr);
    if (!isDay) continue;

    if (curr > prev && curr > next) {
      extremes.push({
        time: formatLocalTime(series[i].time),
        type: "alta",
        height: Math.round(curr * 100) / 100,
      });
    } else if (curr < prev && curr < next) {
      extremes.push({
        time: formatLocalTime(series[i].time),
        type: "bassa",
        height: Math.round(curr * 100) / 100,
      });
    }
  }

  const hourlySeries = series
    .filter((p) => p.time.startsWith(todayStr))
    .map((p) => ({ time: formatLocalTime(p.time), height: p.height }));

  return { today: extremes, hourlySeries, timezone };
}

function formatLocalTime(isoLike: string): string {
  // Open-Meteo con timezone=auto restituisce già l'ora locale, es. "2026-08-23T14:00"
  const match = isoLike.match(/T(\d{2}:\d{2})/);
  return match ? match[1] : isoLike;
}

SETUP_EOF_MARKER
cat > "app/api/geocode/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { searchLocations } from "@/lib/geocode";

export async function GET(req: NextRequest) {
  const query = req.nextUrl.searchParams.get("q");
  if (!query || query.trim().length < 2) {
    return NextResponse.json({ ok: true, results: [] });
  }

  const results = await searchLocations(query.trim());
  return NextResponse.json({ ok: true, results });
}

SETUP_EOF_MARKER
cat > "app/api/maree/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { getTideForecast } from "@/lib/tides";
import { getMoonData } from "@/lib/moon";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");
  const timezone = req.nextUrl.searchParams.get("tz") || "Europe/Rome";

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json(
      { ok: false, error: "Coordinate mancanti o non valide." },
      { status: 400 }
    );
  }

  const [tides, moon] = await Promise.all([
    getTideForecast(lat, lon),
    Promise.resolve(getMoonData(lat, lon, new Date(), timezone)),
  ]);

  return NextResponse.json({ ok: true, tides, moon });
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

export default function MareePage() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<GeoResult[]>([]);
  const [searching, setSearching] = useState(false);
  const [selected, setSelected] = useState<GeoResult | null>(null);
  const [saved, setSaved] = useState<GeoResult[]>([]);
  const [tides, setTides] = useState<TideExtreme[] | null>(null);
  const [moon, setMoon] = useState<MoonData | null>(null);
  const [loadingData, setLoadingData] = useState(false);
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
    setLoadingData(true);
    setDataError(null);
    saveLocation(loc);
    setSaved(loadSaved());

    fetch(`/api/maree?lat=${loc.latitude}&lon=${loc.longitude}&tz=${encodeURIComponent(loc.timezone)}`)
      .then((r) => r.json())
      .then((d) => {
        if (!d.ok) {
          setDataError("Dati non disponibili per questa località.");
          return;
        }
        setTides(d.tides?.today || null);
        setMoon(d.moon || null);
        if (!d.tides) {
          setDataError("Maree non disponibili qui (probabilmente zona non costiera).");
        }
      })
      .catch(() => setDataError("Errore nel recupero dei dati. Riprova."))
      .finally(() => setLoadingData(false));
  }, []);

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "Georgia, serif" }}>
          Maree e luna
        </h1>

        {/* Barra di ricerca */}
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

        {/* Località salvate */}
        {saved.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-4">
            {saved.map((s) => (
              <button
                key={s.id}
                onClick={() => loadLocationData(s)}
                className={`text-[11px] font-mono px-2.5 py-1 rounded-full border ${
                  selected?.id === s.id
                    ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                    : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                }`}
              >
                📍 {s.name}
              </button>
            ))}
          </div>
        )}

        {!selected && (
          <p className="text-sm text-[#6B7E82] mt-6">
            Cerca una località costiera per vedere maree e dati lunari di oggi.
          </p>
        )}

        {loadingData && <p className="text-sm text-[#6B7E82]">Carico i dati…</p>}

        {dataError && (
          <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-sm text-[#6B7E82] mb-4">
            {dataError}
          </div>
        )}

        {selected && !loadingData && tides && (
          <div className="bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-5 mb-4">
            <div className="text-[11px] uppercase tracking-widest text-[#D98E4A] mb-1">
              {selected.name}
            </div>
            <h2 className="text-[19px] font-medium mb-4" style={{ fontFamily: "Georgia, serif" }}>
              Oggi
            </h2>
            {tides.length === 0 ? (
              <p className="text-sm text-[#a9bcc2]">
                Nessun picco di marea rilevabile oggi in questa zona (escursione minima, tipico del Mediterraneo).
              </p>
            ) : (
              <div className="flex flex-wrap gap-4">
                {tides.map((t, i) => (
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
        )}

        {selected && !loadingData && moon && (
          <>
            <div className="text-[11px] uppercase tracking-widest text-[#6B7E82] mb-2">
              Luna
            </div>
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
            <p className="text-xs text-[#6B7E82]">Qualunque località, dati di oggi</p>
          </div>
        </Link>

        <div className="mt-6 p-3 border border-dashed border-[#E1DFD6] rounded-xl text-xs text-[#6B7E82] leading-relaxed">
          🔧 Per testare: apri{" "}
          <code className="bg-[#eeece3] px-1 rounded">
            /sblocca?codice=FEEDER-2026-DEMO
          </code>{" "}
          per simulare la scansione del QR del Diario Feeder.
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
echo '✓ Sezione Maree e luna aggiunta.'
echo 'Installo la nuova dipendenza (astronomy-engine)...'
npm install