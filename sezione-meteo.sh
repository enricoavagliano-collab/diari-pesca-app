#!/bin/bash
set -e
echo 'Aggiungo la sezione Meteo (vento, pressione, condizioni)...'
mkdir -p "app"
mkdir -p "app/api/meteo"
mkdir -p "app/meteo"
mkdir -p "lib"
cat > "lib/weather.ts" << 'SETUP_EOF_MARKER'
export interface DayWeather {
  date: string; // YYYY-MM-DD
  tempMax: number;
  tempMin: number;
  windSpeed: number; // km/h
  windDirection: number; // gradi (0-360)
  pressure: number; // hPa
  weatherCode: number;
  description: string;
  icon: string;
}

export interface WeekWeatherForecast {
  days: DayWeather[];
  timezone: string;
}

// Codici meteo WMO usati da Open-Meteo, tradotti in italiano
const WEATHER_CODES: Record<number, { description: string; icon: string }> = {
  0: { description: "Sereno", icon: "☀️" },
  1: { description: "Prevalentemente sereno", icon: "🌤️" },
  2: { description: "Parzialmente nuvoloso", icon: "⛅" },
  3: { description: "Nuvoloso", icon: "☁️" },
  45: { description: "Nebbia", icon: "🌫️" },
  48: { description: "Nebbia con brina", icon: "🌫️" },
  51: { description: "Pioviggine leggera", icon: "🌦️" },
  53: { description: "Pioviggine moderata", icon: "🌦️" },
  55: { description: "Pioviggine intensa", icon: "🌧️" },
  61: { description: "Pioggia leggera", icon: "🌧️" },
  63: { description: "Pioggia moderata", icon: "🌧️" },
  65: { description: "Pioggia intensa", icon: "🌧️" },
  71: { description: "Neve leggera", icon: "🌨️" },
  73: { description: "Neve moderata", icon: "🌨️" },
  75: { description: "Neve intensa", icon: "❄️" },
  80: { description: "Rovesci leggeri", icon: "🌦️" },
  81: { description: "Rovesci moderati", icon: "🌧️" },
  82: { description: "Rovesci violenti", icon: "⛈️" },
  95: { description: "Temporale", icon: "⛈️" },
  96: { description: "Temporale con grandine", icon: "⛈️" },
  99: { description: "Temporale forte con grandine", icon: "⛈️" },
};

function describeCode(code: number): { description: string; icon: string } {
  return WEATHER_CODES[code] || { description: "Condizioni variabili", icon: "🌡️" };
}

export async function getWeekWeather(lat: number, lon: number): Promise<WeekWeatherForecast | null> {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set("daily", "weathercode,temperature_2m_max,temperature_2m_min,windspeed_10m_max,winddirection_10m_dominant");
  url.searchParams.set("hourly", "surface_pressure");
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", "7");

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  const dailyTimes: string[] = data?.daily?.time || [];
  if (dailyTimes.length === 0) return null;

  const timezone: string = data?.timezone || "UTC";
  const hourlyTimes: string[] = data?.hourly?.time || [];
  const hourlyPressure: number[] = data?.hourly?.surface_pressure || [];

  const days: DayWeather[] = dailyTimes.map((date: string, i: number) => {
    // Pressione: prendo il valore delle 12:00 di quel giorno come rappresentativo
    const middayIdx = hourlyTimes.findIndex((t) => t === `${date}T12:00`);
    const pressure = middayIdx >= 0 ? hourlyPressure[middayIdx] : hourlyPressure[i * 24 + 12] || 1013;

    const code = data.daily.weathercode[i];
    const { description, icon } = describeCode(code);

    return {
      date,
      tempMax: Math.round(data.daily.temperature_2m_max[i]),
      tempMin: Math.round(data.daily.temperature_2m_min[i]),
      windSpeed: Math.round(data.daily.windspeed_10m_max[i]),
      windDirection: Math.round(data.daily.winddirection_10m_dominant[i]),
      pressure: Math.round(pressure),
      weatherCode: code,
      description,
      icon,
    };
  });

  return { days, timezone };
}

export function windDirectionLabel(degrees: number): string {
  const dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"];
  const idx = Math.round(degrees / 45) % 8;
  return dirs[idx];
}

SETUP_EOF_MARKER
cat > "app/api/meteo/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { getWeekWeather } from "@/lib/weather";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json({ ok: false, error: "Coordinate mancanti o non valide." }, { status: 400 });
  }

  const forecast = await getWeekWeather(lat, lon);
  if (!forecast) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa località." });
  }

  return NextResponse.json({ ok: true, ...forecast });
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

interface DayWeather {
  date: string;
  tempMax: number;
  tempMin: number;
  windSpeed: number;
  windDirection: number;
  pressure: number;
  description: string;
  icon: string;
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
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "Georgia, serif" }}>
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
          <div className="bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-5 mb-4">
            <div className="text-[11px] uppercase tracking-widest text-[#D98E4A] mb-1">
              {selected.name}
            </div>
            <h2 className="text-[19px] font-medium mb-1" style={{ fontFamily: "Georgia, serif" }}>
              {nextDays(6).find((d) => d.iso === selectedDate)?.label || "Oggi"}
            </h2>
            <div className="flex items-center gap-2 mb-4">
              <span className="text-2xl">{todayWeather.icon}</span>
              <span className="text-sm text-[#a9bcc2]">{todayWeather.description}</span>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <div className="font-mono text-[17px]">
                  {todayWeather.tempMin}° / {todayWeather.tempMax}°
                </div>
                <div className="text-[10px] text-[#a9bcc2] uppercase tracking-wide mt-0.5">Temperatura</div>
              </div>
              <div>
                <div className="font-mono text-[17px]">
                  {todayWeather.windSpeed} km/h {windDirectionLabel(todayWeather.windDirection)}
                </div>
                <div className="text-[10px] text-[#a9bcc2] uppercase tracking-wide mt-0.5">Vento</div>
              </div>
              <div>
                <div className="font-mono text-[17px]">{todayWeather.pressure} hPa</div>
                <div className="text-[10px] text-[#a9bcc2] uppercase tracking-wide mt-0.5">Pressione</div>
              </div>
            </div>
          </div>
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
echo "Fatto: sezione Meteo aggiunta, gratuita (Open-Meteo, nessuna chiave necessaria)."