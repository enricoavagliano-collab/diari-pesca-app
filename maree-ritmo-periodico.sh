#!/bin/bash
set -e
echo 'Aggiorno il calcolo maree: ancora reale + ritmo periodico...'
mkdir -p "app/maree"
mkdir -p "lib"
cat > "lib/tides.ts" << 'SETUP_EOF_MARKER'
export interface TideExtreme {
  time: string; // HH:mm locale
  type: "alta" | "bassa";
  height: number; // metri, relativo al livello medio del mare (non è un datum di navigazione)
  stimato: boolean; // true se calcolato dal ritmo di marea, non rilevato direttamente dal modello
}

export interface TideForecast {
  today: TideExtreme[];
  hourlySeries: { time: string; height: number }[]; // per disegnare il grafico
  timezone: string;
}

// Periodo semidiurno medio della marea M2 (la componente principale, quasi costante ovunque):
// un ciclo alta→alta dura ~12h 25min, quindi alta→bassa (o viceversa) ~6h 12,5min.
const HALF_PERIOD_MINUTES = 6 * 60 + 12.5; // 372.5 minuti

interface RawPoint {
  dateTime: Date; // interpretato come "orario locale ingenuo" (naive), coerente in tutto il calcolo
  height: number;
}

function parseLocalNaive(isoLike: string): Date {
  // "2026-08-24T14:00" → Date costruito nei componenti locali, senza conversioni di fuso.
  // Usiamo questo oggetto solo per fare differenze in minuti tra istanti, mai per formattarlo con fusi diversi.
  const [datePart, timePart] = isoLike.split("T");
  const [y, m, d] = datePart.split("-").map(Number);
  const [hh, mm] = timePart.split(":").map(Number);
  return new Date(y, m - 1, d, hh, mm);
}

function formatHM(date: Date): string {
  const hh = String(date.getHours()).padStart(2, "0");
  const mm = String(date.getMinutes()).padStart(2, "0");
  return `${hh}:${mm}`;
}

function dateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export async function getTideForecast(
  lat: number,
  lon: number,
  targetDate: string // YYYY-MM-DD, nel timezone locale della località
): Promise<TideForecast | null> {
  const url = new URL("https://marine-api.open-meteo.com/v1/marine");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set("hourly", "sea_level_height_msl");
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", "7");
  url.searchParams.set("past_days", "2");

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  const times: string[] = data?.hourly?.time || [];
  const heights: (number | null)[] = data?.hourly?.sea_level_height_msl || [];
  const timezone: string = data?.timezone || "UTC";

  if (times.length === 0 || heights.every((h) => h === null)) return null;

  const series: RawPoint[] = times
    .map((t, i) => ({ dateTime: parseLocalNaive(t), height: heights[i] }))
    .filter((p): p is RawPoint => p.height !== null);

  if (series.length < 3) return null;

  // 1) Cerca i picchi VERI in tutta la finestra di dati disponibile (non solo nel giorno scelto),
  //    così anche se il giorno target è piatto possiamo comunque trovare un'ancora nei giorni vicini.
  const detected: { dateTime: Date; type: "alta" | "bassa"; height: number }[] = [];
  for (let i = 1; i < series.length - 1; i++) {
    const prev = series[i - 1].height;
    const curr = series[i].height;
    const next = series[i + 1].height;
    if (curr > prev && curr > next) {
      detected.push({ dateTime: series[i].dateTime, type: "alta", height: curr });
    } else if (curr < prev && curr < next) {
      detected.push({ dateTime: series[i].dateTime, type: "bassa", height: curr });
    }
  }

  const hourlySeries = series
    .filter((p) => dateKey(p.dateTime) === targetDate)
    .map((p) => ({ time: formatHM(p.dateTime), height: p.height }));

  if (detected.length === 0) {
    // Davvero nessun segnale di marea rilevabile in tutta la finestra: onesto dirlo, non inventiamo nulla.
    return { today: [], hourlySeries, timezone };
  }

  // 2) Scegli come "ancora" il picco rilevato più vicino al giorno target
  const targetMid = parseLocalNaive(`${targetDate}T12:00`);
  const anchor = detected.reduce((best, p) =>
    Math.abs(p.dateTime.getTime() - targetMid.getTime()) <
    Math.abs(best.dateTime.getTime() - targetMid.getTime())
      ? p
      : best
  );

  // Altezza media approssimativa per alta/bassa, usando tutti i picchi rilevati (se ce n'è più di uno)
  const altHeights = detected.filter((p) => p.type === "alta").map((p) => p.height);
  const bassHeights = detected.filter((p) => p.type === "bassa").map((p) => p.height);
  const avgAlta = altHeights.length
    ? altHeights.reduce((a, b) => a + b, 0) / altHeights.length
    : Math.abs(anchor.height);
  const avgBassa = bassHeights.length
    ? bassHeights.reduce((a, b) => a + b, 0) / bassHeights.length
    : -Math.abs(anchor.height);

  // 3) Genera la sequenza periodica alternata (alta/bassa) a partire dall'ancora,
  //    coprendo un paio di giorni prima e dopo per essere sicuri di coprire il giorno target
  const generated: TideExtreme[] = [];
  const stepMs = HALF_PERIOD_MINUTES * 60 * 1000;
  const windowStart = anchor.dateTime.getTime() - 4 * 24 * 60 * 60 * 1000;
  const windowEnd = anchor.dateTime.getTime() + 4 * 24 * 60 * 60 * 1000;

  let idx = Math.ceil((windowStart - anchor.dateTime.getTime()) / stepMs);
  const endIdx = Math.floor((windowEnd - anchor.dateTime.getTime()) / stepMs);

  for (; idx <= endIdx; idx++) {
    const t = new Date(anchor.dateTime.getTime() + idx * stepMs);
    if (dateKey(t) !== targetDate) continue;

    // L'ancora alterna tipo ad ogni passo dispari/pari rispetto al proprio tipo
    const isSameTypeAsAnchor = idx % 2 === 0;
    const type: "alta" | "bassa" = isSameTypeAsAnchor
      ? anchor.type
      : anchor.type === "alta"
      ? "bassa"
      : "alta";

    // Se questo istante coincide (entro 30 min) con un picco davvero rilevato, usa il dato vero
    const realMatch = detected.find(
      (d) => Math.abs(d.dateTime.getTime() - t.getTime()) < 30 * 60 * 1000
    );

    generated.push({
      time: formatHM(realMatch ? realMatch.dateTime : t),
      type,
      height: Math.round((realMatch ? realMatch.height : type === "alta" ? avgAlta : avgBassa) * 100) / 100,
      stimato: !realMatch,
    });
  }

  generated.sort((a, b) => a.time.localeCompare(b.time));

  return { today: generated, hourlySeries, timezone };
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
    const iso = d.toLocaleDateString("sv-SE"); // YYYY-MM-DD
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

  const fetchData = useCallback((loc: GeoResult, dateIso: string) => {
    setLoadingData(true);
    setDataError(null);

    fetch(
      `/api/maree?lat=${loc.latitude}&lon=${loc.longitude}&tz=${encodeURIComponent(loc.timezone)}&date=${dateIso}`
    )
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

  const loadLocationData = useCallback(
    (loc: GeoResult) => {
      setSelected(loc);
      setQuery("");
      setResults([]);
      saveLocation(loc);
      setSaved(loadSaved());
      fetchData(loc, selectedDate);
    },
    [fetchData, selectedDate]
  );

  const changeDay = useCallback(
    (dateIso: string) => {
      setSelectedDate(dateIso);
      if (selected) fetchData(selected, dateIso);
    },
    [selected, fetchData]
  );

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

        {loadingData && <p className="text-sm text-[#6B7E82]">Carico i dati…</p>}

        {dataError && (
          <div className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 text-sm text-[#6B7E82] mb-4">
            {dataError}
          </div>
        )}

        {selected && !loadingData && tides && (
          <>
            <div className="bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-5 mb-2">
              <div className="text-[11px] uppercase tracking-widest text-[#D98E4A] mb-1">
                {selected.name}
              </div>
              <h2 className="text-[19px] font-medium mb-4" style={{ fontFamily: "Georgia, serif" }}>
                {nextDays(6).find((d) => d.iso === selectedDate)?.label || "Oggi"}
              </h2>
              {tides.length === 0 ? (
                <p className="text-sm text-[#a9bcc2]">
                  Nessun picco di marea rilevabile oggi in questa zona (escursione minima, tipico del Mediterraneo).
                </p>
              ) : (
                <div className="flex flex-wrap gap-4">
                  {tides.map((t, i) => (
                    <div key={i} className="text-center">
                      <div className="font-mono text-[17px]">
                        {t.stimato && <span className="text-[#D98E4A]">~</span>}
                        {t.time}
                      </div>
                      <div className="text-[10px] text-[#a9bcc2] uppercase tracking-wide mt-0.5">
                        {t.type === "alta" ? "Alta" : "Bassa"} · {t.height}m
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <p className="text-[11px] text-[#6B7E82] mb-4 px-1 leading-relaxed">
              ⓘ Orari calcolati sul ritmo naturale delle maree (~12h 25min tra due alte), ancorati a un dato
              rilevato dal modello. Il simbolo <span className="text-[#D98E4A]">~</span> indica un orario
              stimato dal ritmo, non rilevato direttamente — utile per farsi un&apos;idea, non per la navigazione.
            </p>
          </>
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
echo "Fatto: ora vengono sempre mostrati 3-4 picchi, ancorati a un dato vero, calcolati sul ritmo periodico della marea."