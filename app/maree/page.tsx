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

