#!/bin/bash
set -e

mkdir -p app/api/meteo app/api/reverse-geocode lib components

cat > lib/weather.ts << 'FILE_EOF'
export interface HourSlot {
  time: string; // HH:mm
  tempC: number;
  windSpeed: number; // km/h
  windDirection: number; // gradi
  pressure: number; // hPa
  weatherCode: number;
  description: string;
  icon: string;
}

export interface DayWeather {
  date: string; // YYYY-MM-DD
  slots: HourSlot[]; // ogni 2 ore, dalle 00:00 alle 22:00
}

export interface WeekWeatherForecast {
  days: DayWeather[];
  timezone: string;
}

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

function describeCode(code: number, hour: number): { description: string; icon: string } {
  const base = WEATHER_CODES[code] || { description: "Condizioni variabili", icon: "🌡️" };
  const isNight = hour < 6 || hour >= 20;
  if (isNight) {
    if (code === 0) return { ...base, icon: "🌙" };
    if (code === 1) return { ...base, icon: "🌙" };
    if (code === 2) return { ...base, icon: "☁️" };
  }
  return base;
}

export async function getWeekWeather(
  lat: number,
  lon: number,
  options?: { pastDays?: number; forecastDays?: number }
): Promise<WeekWeatherForecast | null> {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set(
    "hourly",
    "temperature_2m,windspeed_10m,winddirection_10m,surface_pressure,weathercode"
  );
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", String(options?.forecastDays ?? 7));
  if (options?.pastDays) {
    url.searchParams.set("past_days", String(options.pastDays));
  }

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  const times: string[] = data?.hourly?.time || [];
  if (times.length === 0) return null;

  const timezone: string = data?.timezone || "UTC";
  const temps: number[] = data.hourly.temperature_2m;
  const winds: number[] = data.hourly.windspeed_10m;
  const dirs: number[] = data.hourly.winddirection_10m;
  const pressures: number[] = data.hourly.surface_pressure;
  const codes: number[] = data.hourly.weathercode;

  const byDate: Record<string, HourSlot[]> = {};

  for (let i = 0; i < times.length; i++) {
    const [date, time] = times[i].split("T");
    const hour = parseInt(time.split(":")[0], 10);
    if (hour % 2 !== 0) continue; // teniamo solo ogni 2 ore: 00, 02, 04 ... 22

    const { description, icon } = describeCode(codes[i], hour);
    if (!byDate[date]) byDate[date] = [];
    byDate[date].push({
      time,
      tempC: Math.round(temps[i]),
      windSpeed: Math.round(winds[i]),
      windDirection: Math.round(dirs[i]),
      pressure: Math.round(pressures[i]),
      weatherCode: codes[i],
      description,
      icon,
    });
  }

  const days: DayWeather[] = Object.entries(byDate).map(([date, slots]) => ({
    date,
    slots: slots.sort((a, b) => a.time.localeCompare(b.time)),
  }));

  return { days, timezone };
}

export function windDirectionLabel(degrees: number): string {
  const dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"];
  return dirs[Math.round(degrees / 45) % 8];
}
FILE_EOF

cat > app/api/meteo/route.ts << 'FILE_EOF'
import { NextRequest, NextResponse } from "next/server";
import { getWeekWeather } from "@/lib/weather";

const MAX_PAST_DAYS = 92; // limite dei dati storici "recenti" di Open-Meteo
const MAX_FORECAST_DAYS = 16;

function diffInDays(dateStr: string): number {
  const target = new Date(dateStr + "T00:00:00");
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((target.getTime() - today.getTime()) / 86400000);
}

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");
  const date = req.nextUrl.searchParams.get("date"); // YYYY-MM-DD, opzionale

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json({ ok: false, error: "Coordinate mancanti o non valide." }, { status: 400 });
  }

  // Nessuna data richiesta: comportamento invariato, meteo di oggi + prossimi giorni
  // (usato dalla pagina Meteo generale dell'app).
  if (!date) {
    const forecast = await getWeekWeather(lat, lon);
    if (!forecast) {
      return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa località." });
    }
    return NextResponse.json({ ok: true, ...forecast });
  }

  const diff = diffInDays(date);

  if (diff < -MAX_PAST_DAYS || diff > MAX_FORECAST_DAYS) {
    return NextResponse.json({
      ok: false,
      error: "Meteo non disponibile per questa data (solo ultimi 3 mesi o prossimi 16 giorni).",
    });
  }

  const pastDays = diff < 0 ? Math.min(MAX_PAST_DAYS, -diff) : 0;
  const forecastDays = diff >= 0 ? Math.min(MAX_FORECAST_DAYS, diff + 1) : 1;

  const forecast = await getWeekWeather(lat, lon, { pastDays, forecastDays });
  if (!forecast) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa località." });
  }

  const matchedDay = forecast.days.find((d) => d.date === date);
  if (!matchedDay) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa data." });
  }

  return NextResponse.json({ ok: true, days: [matchedDay], timezone: forecast.timezone });
}
FILE_EOF

cat > lib/reverse-geocode.ts << 'FILE_EOF'
export interface ReverseGeocodeResult {
  name: string;
}

// Nominatim (OpenStreetMap) non richiede chiave API, ma richiede uno User-Agent
// identificativo per rispettare la loro policy d'uso.
export async function reverseGeocode(lat: number, lon: number): Promise<ReverseGeocodeResult> {
  try {
    const url = new URL("https://nominatim.openstreetmap.org/reverse");
    url.searchParams.set("lat", lat.toString());
    url.searchParams.set("lon", lon.toString());
    url.searchParams.set("format", "json");
    url.searchParams.set("accept-language", "it");
    url.searchParams.set("zoom", "14"); // livello città/paese, non via esatta

    const res = await fetch(url.toString(), {
      headers: { "User-Agent": "LibriDiPescaApp/1.0 (enricoavagliano.com)" },
    });
    if (!res.ok) return { name: "Posizione attuale" };

    const data = await res.json();
    const addr = data?.address || {};
    const place =
      addr.village || addr.town || addr.city || addr.hamlet || addr.suburb || addr.county;

    return { name: place ? `${place} (posizione attuale)` : "Posizione attuale" };
  } catch {
    return { name: "Posizione attuale" };
  }
}
FILE_EOF

cat > app/api/reverse-geocode/route.ts << 'FILE_EOF'
import { NextRequest, NextResponse } from "next/server";
import { reverseGeocode } from "@/lib/reverse-geocode";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json({ ok: false, error: "Coordinate mancanti o non valide." }, { status: 400 });
  }

  const result = await reverseGeocode(lat, lon);
  return NextResponse.json({ ok: true, ...result });
}
FILE_EOF

cat > components/DiarioForm.tsx << 'FILE_EOF'
"use client";

import { useEffect, useState, useCallback } from "react";
import { BookId } from "@/lib/books";
import { DiarioSection, CONDIZIONI_TAGS } from "@/lib/diario-templates";
import type { DiarioEntryData, CatchEntry, MeteoSnapshot } from "@/lib/diario-entries";
import { ClipboardList, CloudSun, Fish, StickyNote, Plus, Trash2, Search, Camera, Pencil, LocateFixed } from "lucide-react";

// Comprime e ridimensiona una foto scattata dal telefono prima di salvarla —
// altrimenti una foto originale (spesso 3-5 MB) appesantirebbe troppo il database.
function compressImage(file: File, maxWidth = 800, quality = 0.7): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const img = new Image();
      img.onload = () => {
        const scale = Math.min(1, maxWidth / img.width);
        const canvas = document.createElement("canvas");
        canvas.width = img.width * scale;
        canvas.height = img.height * scale;
        const ctx = canvas.getContext("2d");
        if (!ctx) return reject(new Error("Canvas non disponibile"));
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        resolve(canvas.toDataURL("image/jpeg", quality));
      };
      img.onerror = reject;
      img.src = reader.result as string;
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
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

interface Entry {
  id: string;
  createdAt: string;
  data: DiarioEntryData;
}

interface GeoResult {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  timezone: string;
}

type Tab = "dati" | "meteo" | "catture" | "note";

const TABS: { id: Tab; label: string; Icon: typeof ClipboardList }[] = [
  { id: "dati", label: "Dati sessione", Icon: ClipboardList },
  { id: "meteo", label: "Meteo", Icon: CloudSun },
  { id: "catture", label: "Catture", Icon: Fish },
  { id: "note", label: "Note", Icon: StickyNote },
];

function emptyData(): DiarioEntryData {
  return { fields: {}, catture: [], condizioni: [], note: "" };
}

export default function DiarioForm({
  bookId,
  template,
}: {
  bookId: BookId;
  template: DiarioSection[];
}) {
  const [formOpen, setFormOpen] = useState(false);
  const [tab, setTab] = useState<Tab>("dati");
  const [values, setValues] = useState<DiarioEntryData>(emptyData());
  const [entries, setEntries] = useState<Entry[]>([]);
  const [saving, setSaving] = useState(false);

  // Ricerca località per il meteo
  const [meteoQuery, setMeteoQuery] = useState("");
  const [meteoResults, setMeteoResults] = useState<GeoResult[]>([]);
  const [loadingMeteo, setLoadingMeteo] = useState(false);
  const [locatingGps, setLocatingGps] = useState(false);
  const [gpsError, setGpsError] = useState<string | null>(null);

  // Nuova cattura in compilazione
  const [newCatch, setNewCatch] = useState({ specie: "", lunghezza: "", peso: "", nota: "" });
  const [newCatchPhoto, setNewCatchPhoto] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [lightboxPhoto, setLightboxPhoto] = useState<string | null>(null);

  const deviceId = typeof window !== "undefined" ? getDeviceId() : "";

  useEffect(() => {
    if (!deviceId) return;
    fetch(`/api/diario?bookId=${bookId}&deviceId=${deviceId}`)
      .then((r) => r.json())
      .then((d) => {
        if (d.ok) setEntries(d.entries);
      });
  }, [bookId, deviceId]);

  useEffect(() => {
    if (meteoQuery.trim().length < 2) {
      setMeteoResults([]);
      return;
    }
    const t = setTimeout(() => {
      fetch(`/api/geocode?q=${encodeURIComponent(meteoQuery)}`)
        .then((r) => r.json())
        .then((d) => setMeteoResults(d.ok ? d.results : []));
    }, 350);
    return () => clearTimeout(t);
  }, [meteoQuery]);

  function setField(key: string, value: string) {
    setValues((v) => ({ ...v, fields: { ...v.fields, [key]: value } }));
  }

  const pickMeteoLocation = useCallback(
    (loc: GeoResult) => {
      setLoadingMeteo(true);
      setGpsError(null);
      setMeteoQuery("");
      setMeteoResults([]);
      // Il meteo deve riferirsi al giorno della battuta di pesca (campo "data" del
      // form), non a "adesso" — altrimenti compilando una voce per un giorno
      // passato o futuro vedremmo il meteo sbagliato.
      const entryDate = values.fields.data || new Date().toISOString().slice(0, 10);
      fetch(`/api/meteo?lat=${loc.latitude}&lon=${loc.longitude}&date=${entryDate}`)
        .then((r) => r.json())
        .then((d) => {
          if (!d.ok || !d.days?.length) return;
          const daySlot = d.days[0].slots.find((s: { time: string }) => s.time.startsWith("12")) || d.days[0].slots[0];
          const snapshot: MeteoSnapshot = {
            locationName: loc.name,
            tempC: daySlot.tempC,
            windSpeed: daySlot.windSpeed,
            windDirection: daySlot.windDirection,
            pressure: daySlot.pressure,
            description: daySlot.description,
            icon: daySlot.icon,
          };
          setValues((v) => ({ ...v, meteo: snapshot }));
        })
        .finally(() => setLoadingMeteo(false));
    },
    [values.fields.data]
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
            pickMeteoLocation({
              id: 0,
              name,
              latitude,
              longitude,
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
      },
      { enableHighAccuracy: false, timeout: 10000 }
    );
  }, [pickMeteoLocation]);

  function toggleCondizione(tag: string) {
    setValues((v) => ({
      ...v,
      condizioni: v.condizioni.includes(tag)
        ? v.condizioni.filter((c) => c !== tag)
        : [...v.condizioni, tag],
    }));
  }

  function addCatch() {
    if (!newCatch.specie.trim()) return;
    const entry: CatchEntry = {
      id: crypto.randomUUID(),
      specie: newCatch.specie,
      lunghezza: newCatch.lunghezza,
      peso: newCatch.peso,
      nota: newCatch.nota || undefined,
      foto: newCatchPhoto || undefined,
      time: new Date().toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" }),
    };
    setValues((v) => ({ ...v, catture: [...v.catture, entry] }));
    setNewCatch({ specie: "", lunghezza: "", peso: "", nota: "" });
    setNewCatchPhoto(null);
  }

  async function handlePhotoSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const compressed = await compressImage(file);
      setNewCatchPhoto(compressed);
    } catch {
      // se la compressione fallisce, semplicemente non allega la foto
    }
  }

  function removeCatch(id: string) {
    setValues((v) => ({ ...v, catture: v.catture.filter((c) => c.id !== id) }));
  }

  async function save() {
    setSaving(true);
    const url = editingId ? `/api/diario/${editingId}` : "/api/diario";
    const method = editingId ? "PUT" : "POST";
    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ bookId, deviceId, data: values }),
    });
    const d = await res.json();
    setSaving(false);
    if (d.ok) {
      if (editingId) {
        setEntries((e) => e.map((x) => (x.id === editingId ? d.entry : x)));
      } else {
        setEntries((e) => [d.entry, ...e]);
      }
      setValues(emptyData());
      setFormOpen(false);
      setTab("dati");
      setEditingId(null);
    }
  }

  function startEdit(entry: Entry) {
    setValues(entry.data);
    setEditingId(entry.id);
    setFormOpen(true);
    setTab("dati");
  }

  function cancelForm() {
    setFormOpen(false);
    setEditingId(null);
    setValues(emptyData());
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

  const totalPeso = values.catture.reduce((sum, c) => sum + (parseFloat(c.peso || "0") || 0), 0);

  const fieldLabels: Record<string, string> = Object.fromEntries(
    template.flatMap((section) => section.fields.map((f) => [f.key, f.label]))
  );

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <h2 className="font-medium text-lg" style={{ fontFamily: "var(--font-fraunces)" }}>
          Il tuo diario digitale
        </h2>
        <button
          onClick={() => (formOpen ? cancelForm() : setFormOpen(true))}
          className="w-8 h-8 rounded-full bg-[#2CA6A4] text-[#0B1F2A] text-lg flex items-center justify-center flex-shrink-0"
        >
          {formOpen ? "×" : "+"}
        </button>
      </div>

      {formOpen && (
        <div className="bg-[#124E5A] border border-white/10 rounded-xl overflow-hidden">
          {/* Sotto-schede */}
          <div className="flex border-b border-white/10">
            {TABS.map(({ id, label, Icon }) => (
              <button
                key={id}
                onClick={() => setTab(id)}
                className={`flex-1 flex flex-col items-center gap-1 py-2.5 text-[10.5px] ${
                  tab === id ? "text-[#FF9A3C] border-b-2 border-[#FF9A3C]" : "text-[#8FA8B2]"
                }`}
              >
                <Icon size={16} strokeWidth={1.75} />
                {label}
              </button>
            ))}
          </div>

          <div className="p-4">
            {/* DATI SESSIONE */}
            {tab === "dati" && (
              <div className="space-y-3">
                {template.map((section, i) => (
                  <div key={i}>
                    <h4 className="text-[10.5px] uppercase tracking-wide text-[#2CA6A4] mb-2">
                      {section.title}
                    </h4>
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
                              className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A] h-16"
                              placeholder={f.placeholder}
                              value={values.fields[f.key] || ""}
                              onChange={(e) => setField(f.key, e.target.value)}
                            />
                          ) : (
                            <input
                              type={f.type}
                              className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                              placeholder={f.placeholder}
                              value={values.fields[f.key] || ""}
                              onChange={(e) => setField(f.key, e.target.value)}
                            />
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* METEO */}
            {tab === "meteo" && (
              <div className="space-y-3">
                <div className="flex items-center gap-2 bg-[#0B1F2A] border border-white/10 rounded-lg px-3 py-2">
                  <Search size={14} className="text-[#8FA8B2] flex-shrink-0" />
                  <input
                    className="flex-1 outline-none text-sm bg-transparent"
                    placeholder="Cerca la località della sessione…"
                    value={meteoQuery}
                    onChange={(e) => setMeteoQuery(e.target.value)}
                  />
                </div>
                <button
                  onClick={useCurrentPosition}
                  disabled={locatingGps}
                  className="w-full flex items-center justify-center gap-2 bg-[#124E5A] border border-white/10 rounded-lg px-3 py-2 text-sm text-[#F6F5F1] disabled:opacity-60"
                >
                  <LocateFixed size={14} />
                  {locatingGps ? "Rilevo la posizione…" : "Usa la mia posizione attuale"}
                </button>
                {gpsError && <p className="text-xs text-[#FF9A3C]">{gpsError}</p>}
                {meteoResults.length > 0 && (
                  <div className="bg-[#0B1F2A] border border-white/10 rounded-lg overflow-hidden">
                    {meteoResults.map((r) => (
                      <button
                        key={r.id}
                        onClick={() => pickMeteoLocation(r)}
                        className="w-full text-left px-3 py-2 text-sm border-b border-white/10 last:border-0"
                      >
                        {r.name}
                      </button>
                    ))}
                  </div>
                )}
                {loadingMeteo && <p className="text-xs text-[#8FA8B2]">Carico il meteo…</p>}

                {values.meteo && (
                  <div className="bg-[#0B1F2A] border border-white/10 rounded-lg p-3.5">
                    <div className="flex items-center gap-2 mb-3">
                      <span className="text-xl">{values.meteo.icon}</span>
                      <div>
                        <div className="text-sm">
                          {values.meteo.tempC}° — {values.meteo.description}
                        </div>
                        <div className="text-[11px] text-[#8FA8B2]">{values.meteo.locationName}</div>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-[12px] text-[#8FA8B2]">
                      <div>Vento: {values.meteo.windSpeed} km/h</div>
                      <div>Pressione: {values.meteo.pressure} hPa</div>
                    </div>
                  </div>
                )}

                <div>
                  <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1.5">Condizioni</label>
                  <div className="flex flex-wrap gap-1.5">
                    {CONDIZIONI_TAGS[bookId as "feeder" | "mare-e-foce"].map((tag) => (
                      <button
                        key={tag}
                        onClick={() => toggleCondizione(tag)}
                        className={`text-[11px] px-2.5 py-1 rounded-full border ${
                          values.condizioni.includes(tag)
                            ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                            : "bg-[#0B1F2A] text-[#8FA8B2] border-white/10"
                        }`}
                      >
                        {tag}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* CATTURE */}
            {tab === "catture" && (
              <div className="space-y-3">
                <div className="bg-[#0B1F2A] border border-white/10 rounded-lg p-3 space-y-2">
                  <div className="grid grid-cols-3 gap-2">
                    <input
                      className="border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#124E5A]"
                      placeholder="Specie"
                      value={newCatch.specie}
                      onChange={(e) => setNewCatch((c) => ({ ...c, specie: e.target.value }))}
                    />
                    <input
                      className="border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#124E5A]"
                      placeholder="cm"
                      value={newCatch.lunghezza}
                      onChange={(e) => setNewCatch((c) => ({ ...c, lunghezza: e.target.value }))}
                    />
                    <input
                      className="border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#124E5A]"
                      placeholder="g"
                      value={newCatch.peso}
                      onChange={(e) => setNewCatch((c) => ({ ...c, peso: e.target.value }))}
                    />
                  </div>
                  <input
                    className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#124E5A]"
                    placeholder="Nota (facoltativa)"
                    value={newCatch.nota}
                    onChange={(e) => setNewCatch((c) => ({ ...c, nota: e.target.value }))}
                  />
                  <label className="flex items-center justify-center gap-1.5 border border-dashed border-white/20 rounded-md py-2 text-[12.5px] text-[#8FA8B2] cursor-pointer">
                    <Camera size={14} />
                    {newCatchPhoto ? "Foto selezionata ✓" : "Aggiungi una foto"}
                    <input type="file" accept="image/*" className="hidden" onChange={handlePhotoSelect} />
                  </label>
                  {newCatchPhoto && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={newCatchPhoto} alt="Anteprima cattura" className="w-full h-24 object-cover rounded-md" />
                  )}
                  <button
                    onClick={addCatch}
                    className="w-full flex items-center justify-center gap-1.5 text-[#2CA6A4] text-sm py-1.5"
                  >
                    <Plus size={14} /> Aggiungi cattura
                  </button>
                </div>

                {values.catture.map((c) => (
                  <div
                    key={c.id}
                    className="flex items-center gap-2.5 bg-[#0B1F2A] border border-white/10 rounded-lg px-3 py-2"
                  >
                    {c.foto ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={c.foto}
                        alt={c.specie}
                        onClick={() => setLightboxPhoto(c.foto!)}
                        className="w-10 h-10 rounded-md object-cover flex-shrink-0 cursor-pointer"
                      />
                    ) : (
                      <Fish size={16} className="text-[#2CA6A4] flex-shrink-0" />
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="text-sm">{c.specie}</div>
                      <div className="text-[11px] text-[#8FA8B2]">
                        {c.time} {c.lunghezza && `· ${c.lunghezza}cm`} {c.peso && `· ${c.peso}g`}
                      </div>
                      {c.nota && <div className="text-[11px] text-[#8FA8B2] italic mt-0.5">{c.nota}</div>}
                    </div>
                    <button onClick={() => removeCatch(c.id)}>
                      <Trash2 size={15} className="text-[#8FA8B2]" />
                    </button>
                  </div>
                ))}

                {values.catture.length > 0 && (
                  <div className="flex justify-between text-[12px] text-[#8FA8B2] pt-2 border-t border-white/10">
                    <span>Totale catture: {values.catture.length}</span>
                    <span>Totale peso: {(totalPeso / 1000).toFixed(2)} kg</span>
                  </div>
                )}
              </div>
            )}

            {/* NOTE */}
            {tab === "note" && (
              <textarea
                className="w-full border border-white/10 rounded-md px-3 py-2.5 text-sm bg-[#0B1F2A] h-32"
                placeholder="Note libere sulla sessione…"
                value={values.note}
                onChange={(e) => setValues((v) => ({ ...v, note: e.target.value }))}
              />
            )}

            <button
              onClick={save}
              disabled={saving}
              className="w-full bg-[#2CA6A4] text-[#0B1F2A] rounded-xl py-3 text-sm font-semibold disabled:opacity-50 mt-4"
            >
              {saving ? "Salvataggio…" : editingId ? "Salva modifiche" : "Salva voce nel diario"}
            </button>
          </div>
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
          <div className="flex justify-between items-center mb-2.5">
            <span className="text-xs text-[#8FA8B2] font-mono">
              {new Date(entry.createdAt).toLocaleDateString("it-IT", {
                day: "2-digit",
                month: "2-digit",
                year: "numeric",
              })}
            </span>
            <div className="flex items-center gap-3">
              <button onClick={() => startEdit(entry)} aria-label="Modifica voce">
                <Pencil size={14} className="text-[#8FA8B2] hover:text-[#2CA6A4]" />
              </button>
              <button onClick={() => remove(entry.id)} aria-label="Elimina voce">
                <Trash2 size={14} className="text-[#8FA8B2] hover:text-red-400" />
              </button>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            {entry.data.catture?.length > 0 && (
              <span className="flex items-center gap-1.5 text-[11.5px] bg-[#0B1F2A] border border-white/10 rounded-full pl-1.5 pr-2.5 py-1">
                <span className="w-5 h-5 rounded-full bg-[#2CA6A4]/20 flex items-center justify-center">
                  <Fish size={11} className="text-[#2CA6A4]" />
                </span>
                {entry.data.catture.length} catture
              </span>
            )}
            {entry.data.meteo && (
              <span className="flex items-center gap-1.5 text-[11.5px] bg-[#0B1F2A] border border-white/10 rounded-full pl-1.5 pr-2.5 py-1">
                <span className="text-sm">{entry.data.meteo.icon}</span>
                {entry.data.meteo.tempC}°
              </span>
            )}
            {Object.entries(entry.data.fields || {})
              .filter(([, v]) => v)
              .map(([k, v]) => (
                <span
                  key={k}
                  className="text-[11.5px] bg-[#0B1F2A] border border-white/10 rounded-full px-2.5 py-1"
                >
                  <span className="text-[#8FA8B2]">{fieldLabels[k] || k}:</span> {v}
                </span>
              ))}
          </div>

          {entry.data.catture?.some((c) => c.foto) && (
            <div className="flex gap-1.5 mt-2.5 overflow-x-auto">
              {entry.data.catture
                .filter((c) => c.foto)
                .map((c) => (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    key={c.id}
                    src={c.foto}
                    alt={c.specie}
                    title={`${c.specie}${c.peso ? ` · ${c.peso}g` : ""}`}
                    onClick={() => setLightboxPhoto(c.foto!)}
                    className="w-14 h-14 rounded-lg object-cover flex-shrink-0 border border-white/10 cursor-pointer"
                  />
                ))}
            </div>
          )}
        </div>
      ))}

      {lightboxPhoto && (
        <div
          className="fixed inset-0 bg-black/90 z-50 flex items-center justify-center p-4"
          onClick={() => setLightboxPhoto(null)}
        >
          <button
            onClick={() => setLightboxPhoto(null)}
            className="absolute top-4 right-4 text-white text-2xl w-9 h-9 flex items-center justify-center"
            aria-label="Chiudi"
          >
            ×
          </button>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={lightboxPhoto}
            alt="Cattura ingrandita"
            className="max-w-full max-h-full rounded-lg object-contain"
          />
        </div>
      )}
    </div>
  );
}
FILE_EOF

echo "Fatto: meteo ora legato alla data della battuta + pulsante posizione GPS aggiunto."
