#!/bin/bash
set -e

echo "=== Aggiungo la geolocalizzazione a Meteo e Maree ==="

cat > app/meteo/page.tsx << 'METEOEOF'
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
  const [locatingGps, setLocatingGps] = useState(false);
  const [gpsError, setGpsError] = useState<string | null>(null);

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

  const useCurrentPosition = useCallback(() => {
    if (!navigator.geolocation) {
      setGpsError("Il dispositivo non supporta la geolocalizzazione.");
      return;
    }
    setLocatingGps(true);
    setGpsError(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        fetch(`/api/reverse-geocode?lat=${latitude}&lon=${longitude}`)
          .then((r) => r.json())
          .then((d) => {
            const name = d.ok ? d.name : "Posizione attuale";
            loadLocationData({
              id: 0,
              name,
              latitude,
              longitude,
              country: "",
              timezone: "",
            });
          })
          .finally(() => setLocatingGps(false));
      },
      (err) => {
        setLocatingGps(false);
        if (err.code === err.PERMISSION_DENIED) {
          setGpsError("Permesso di posizione negato. Abilitalo nelle impostazioni del browser/telefono.");
        } else {
          setGpsError("Non sono riuscito a rilevare la posizione.");
        }
      }
    );
  }, [loadLocationData]);

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

        <button
          onClick={useCurrentPosition}
          disabled={locatingGps}
          className="w-full flex items-center justify-center gap-2 bg-[#2CA6A4] rounded-xl px-3.5 py-2.5 mb-3 text-sm font-medium disabled:opacity-50"
        >
          📍 {locatingGps ? "Rilevo la posizione…" : "Usa la mia posizione attuale"}
        </button>
        {gpsError && <p className="text-[12px] text-[#FF9A3C] mb-3">{gpsError}</p>}

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

METEOEOF

cat > app/maree/page.tsx << 'MAREEEOF'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import TideChart from "@/components/TideChart";
import { Sunrise, Sunset, ArrowUpCircle, ArrowDownCircle } from "lucide-react";

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
  const [locatingGps, setLocatingGps] = useState(false);
  const [gpsError, setGpsError] = useState<string | null>(null);

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

  const useCurrentPosition = useCallback(() => {
    if (!navigator.geolocation) {
      setGpsError("Il dispositivo non supporta la geolocalizzazione.");
      return;
    }
    setLocatingGps(true);
    setGpsError(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        fetch(`/api/reverse-geocode?lat=${latitude}&lon=${longitude}`)
          .then((r) => r.json())
          .then((d) => {
            const name = d.ok ? d.name : "Posizione attuale";
            loadLocationData({
              id: 0,
              name,
              latitude,
              longitude,
              country: "",
              timezone: "",
            });
          })
          .finally(() => setLocatingGps(false));
      },
      (err) => {
        setLocatingGps(false);
        if (err.code === err.PERMISSION_DENIED) {
          setGpsError("Permesso di posizione negato. Abilitalo nelle impostazioni del browser/telefono.");
        } else {
          setGpsError("Non sono riuscito a rilevare la posizione.");
        }
      }
    );
  }, [loadLocationData]);

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

        <button
          onClick={useCurrentPosition}
          disabled={locatingGps}
          className="w-full flex items-center justify-center gap-2 bg-[#2CA6A4] rounded-xl px-3.5 py-2.5 mb-3 text-sm font-medium disabled:opacity-50"
        >
          📍 {locatingGps ? "Rilevo la posizione…" : "Usa la mia posizione attuale"}
        </button>
        {gpsError && <p className="text-[12px] text-[#FF9A3C] mb-3">{gpsError}</p>}

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
                <>
                  <TideChart points={todayTides.map((t) => ({ time: t.time, type: t.type, height: t.height }))} />
                  <div className="flex flex-wrap gap-4 mt-2">
                    {todayTides.map((t, i) => (
                      <div key={i} className="text-center">
                        <div className="font-mono text-[17px]">{t.time}</div>
                        <div className="text-[10px] text-[#a9bcc2] uppercase tracking-wide mt-0.5">
                          {t.type === "alta" ? "Alta" : "Bassa"} · {t.height}m
                        </div>
                      </div>
                    ))}
                  </div>
                </>
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
            <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
              <div className="flex items-center gap-3 mb-3.5 pb-3.5 border-b border-white/10">
                <div className="w-11 h-11 rounded-full bg-[#0B1F2A] flex items-center justify-center text-xl flex-shrink-0">
                  🌔
                </div>
                <div>
                  <div className="text-sm font-medium">{moon.phaseName}</div>
                  <div className="text-[11px] text-[#8FA8B2]">{moon.illuminationPercent}% illuminata</div>
                </div>
              </div>

              <div className="space-y-2.5">
                {[
                  { Icon: Sunrise, label: "Alba lunare", value: moon.moonrise },
                  { Icon: Sunset, label: "Tramonto lunare", value: moon.moonset },
                  { Icon: ArrowUpCircle, label: "Transito superiore", value: moon.upperTransit },
                  { Icon: ArrowDownCircle, label: "Transito inferiore", value: moon.lowerTransit },
                ].map(({ Icon, label, value }) => (
                  <div key={label} className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                      <Icon size={15} strokeWidth={1.75} className="text-[#2CA6A4]" />
                    </div>
                    <span className="text-[12.5px] flex-1">{label}</span>
                    <span className="font-mono text-[12.5px]">{value || "—"}</span>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}
      </div>
    </main>
  );
}

MAREEEOF

echo "=== File aggiornati: ==="
echo "  app/meteo/page.tsx"
echo "  app/maree/page.tsx"
echo ""
echo "Aggiunto un pulsante \"Usa la mia posizione attuale\" in cima a"
echo "entrambe le pagine, sopra la ricerca manuale - stesso comportamento"
echo "gia' usato nel form del Diario (permesso GPS + reverse geocoding"
echo "gratuito via Nominatim, gia' configurato)."
echo ""
echo "Ricorda: bash geolocalizzazione-meteo-maree.sh, poi:"
echo "git add -A && git commit -m 'aggiunge geolocalizzazione a meteo e maree' && git push"
