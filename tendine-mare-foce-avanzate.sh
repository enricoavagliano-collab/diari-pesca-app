#!/bin/bash
set -e

echo "=== Tendine: diametri, ami, canna/galleggiante per tecnica, tipologia spot ==="

cat > lib/diario-templates.ts << 'TEMPLATESEOF'
import { BookId } from "./books";

export type FieldType = "text" | "date" | "time" | "textarea" | "number" | "select";

export interface DiarioField {
  key: string;
  label: string;
  type: FieldType;
  placeholder?: string;
  options?: string[]; // usato quando type === "select" e le opzioni sono fisse
  optionsDependsOn?: string; // key di un altro campo select da cui dipendono le opzioni
  optionsByValue?: Record<string, string[]>; // opzioni in base al valore del campo optionsDependsOn
}

export interface DiarioSection {
  title: string;
  fields: DiarioField[];
}

// "Dati sessione": i campi specifici del libro (Feeder vs Mare e Foce), raggruppati
// in sotto-sezioni solo per leggibilità del form — restano nella stessa scheda.
const DIAMETRI_MM = ["0.08", "0.10", "0.12", "0.14", "0.16", "0.18", "0.20", "0.22", "0.25", "0.28", "0.30"];
const AMI_NR = ["24", "22", "20", "18", "16", "14", "12", "10", "8", "6", "4"];

export const DIARIO_TEMPLATES: Record<Extract<BookId, "feeder" | "mare-e-foce">, DiarioSection[]> = {
  feeder: [
    {
      title: "Sessione",
      fields: [
        { key: "data", label: "Data", type: "date" },
        {
          key: "ambiente",
          label: "Ambiente",
          type: "select",
          options: ["Fiume", "Lago", "Canale", "Laghetto / Pesca sportiva", "Diga"],
        },
        { key: "orario_inizio", label: "Orario inizio", type: "time" },
        { key: "orario_fine", label: "Orario fine", type: "time" },
        { key: "spot", label: "Spot", type: "text" },
      ],
    },
    {
      title: "Pasturatori",
      fields: [
        { key: "cage", label: "Cage (gr)", type: "number" },
        { key: "block_end", label: "Block End (gr)", type: "number" },
        { key: "pellet", label: "Pellet (gr)", type: "number" },
        { key: "method", label: "Method (gr)", type: "number" },
      ],
    },
    {
      title: "Esche e pasture",
      fields: [
        { key: "esche_dure", label: "Esche dure", type: "text" },
        { key: "esche_naturali", label: "Esche naturali", type: "text" },
        { key: "pastura", label: "Pastura", type: "text" },
      ],
    },
    {
      title: "Assetto pescante",
      fields: [
        {
          key: "canna",
          label: "Canna (ft)",
          type: "select",
          options: ["10 ft", "11 ft", "12 ft", "13 ft", "14 ft"],
        },
        { key: "mulinello", label: "Mulinello", type: "text" },
        { key: "lenza_madre", label: "Lenza madre (mm)", type: "select", options: DIAMETRI_MM },
        { key: "terminale", label: "Terminale (mm)", type: "select", options: DIAMETRI_MM },
        { key: "amo", label: "Amo (nr)", type: "select", options: AMI_NR },
      ],
    },
    {
      title: "Analisi",
      fields: [
        { key: "cosa_ha_funzionato", label: "Cosa ha funzionato", type: "textarea" },
        { key: "cosa_migliorare", label: "Cosa migliorare", type: "textarea" },
      ],
    },
  ],

  "mare-e-foce": [
    {
      title: "Sessione di pesca",
      fields: [
        { key: "data", label: "Data", type: "date" },
        { key: "luogo", label: "Luogo", type: "text" },
        {
          key: "tipologia_spot",
          label: "Tipologia spot",
          type: "select",
          options: ["Scogliera", "Foce", "Porto", "Spiaggia"],
        },
        { key: "orario_inizio", label: "Orario inizio", type: "time" },
        { key: "orario_fine", label: "Orario fine", type: "time" },
        { key: "vento", label: "Vento (km/h)", type: "text" },
        { key: "profondita", label: "Profondità", type: "text", placeholder: "mt" },
        { key: "spot", label: "Spot", type: "text" },
      ],
    },
    {
      title: "Assetto tecnico",
      fields: [
        {
          key: "tecnica",
          label: "Tecnica",
          type: "select",
          options: ["Bolognese", "Inglese"],
        },
        {
          key: "canna",
          label: "Canna (mt)",
          type: "select",
          optionsDependsOn: "tecnica",
          optionsByValue: {
            Bolognese: ["5 mt", "6 mt", "7 mt", "8 mt", "9 mt", "10 mt", "11 mt", "12 mt"],
            Inglese: ["3.90 mt", "4.20 mt", "4.50 mt"],
          },
        },
        { key: "mulinello", label: "Mulinello", type: "text" },
        { key: "amo", label: "Amo (nr)", type: "select", options: AMI_NR },
        {
          key: "galleggiante",
          label: "Galleggiante (gr)",
          type: "select",
          optionsDependsOn: "tecnica",
          optionsByValue: {
            Bolognese: ["0.5 gr", "1 gr", "2 gr", "3 gr", "4 gr", "5 gr", "6 gr", "8 gr", "10 gr"],
            Inglese: [
              "3 gr", "4 gr", "5 gr", "6 gr", "7 gr", "8 gr", "10 gr", "12 gr",
              "2+1 gr", "3+1 gr", "4+1 gr",
            ],
          },
        },
        { key: "filo_madre", label: "Filo madre (mm)", type: "select", options: DIAMETRI_MM },
        { key: "terminale", label: "Terminale (mm)", type: "select", options: DIAMETRI_MM },
      ],
    },
  ],
};

// Condizioni rapide selezionabili nella scheda Meteo del diario (tag on/off) — specifiche per libro
export const CONDIZIONI_TAGS: Record<"feeder" | "mare-e-foce", string[]> = {
  feeder: ["Corrente forte", "Corrente media", "Corrente lenta", "Acqua limpida", "Acqua sporca", "Poco vento", "Vento forte"],
  "mare-e-foce": [
    "Mare calmo",
    "Mare mosso",
    "Corrente forte",
    "Corrente media",
    "Corrente lenta",
    "Acqua limpida",
    "Poco vento",
    "Vento forte",
  ],
};

TEMPLATESEOF

cat > components/DiarioForm.tsx << 'DIARIOFORMEOF'
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
  admin1?: string; // regione/provincia, per distinguere località omonime
  country?: string;
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
  const [meteoError, setMeteoError] = useState<string | null>(null);
  const [locatingGps, setLocatingGps] = useState(false);
  const [gpsError, setGpsError] = useState<string | null>(null);

  // Nuova cattura in compilazione
  const [newCatch, setNewCatch] = useState({ specie: "", lunghezza: "", peso: "", nota: "" });
  const [newCatchPhoto, setNewCatchPhoto] = useState<string | null>(null);
  const [newCatchLocation, setNewCatchLocation] = useState<{ lat: number; lon: number; name: string } | null>(null);
  const [locatingCatchGps, setLocatingCatchGps] = useState(false);
  const [catchGpsError, setCatchGpsError] = useState<string | null>(null);
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
    setValues((v) => {
      const nextFields = { ...v.fields, [key]: value };
      // Se cambia un campo da cui dipendono le opzioni di altri select (es. "Tecnica"),
      // azzero quei campi dipendenti: il valore scelto in precedenza potrebbe non
      // essere più tra le opzioni valide (es. una misura di canna Bolognese con Inglese selezionato).
      template.forEach((section) => {
        section.fields.forEach((f) => {
          if (f.optionsDependsOn === key) {
            delete nextFields[f.key];
          }
        });
      });
      return { ...v, fields: nextFields };
    });
  }

  const pickMeteoLocation = useCallback(
    (loc: GeoResult) => {
      setLoadingMeteo(true);
      setMeteoError(null);
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
          if (!d.ok || !d.days?.length) {
            setMeteoError(d.error || "Meteo non disponibile per questa data/località.");
            return;
          }
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
        .catch(() => setMeteoError("Errore di connessione, riprova."))
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

  function addCatchLocation() {
    if (!navigator.geolocation) {
      setCatchGpsError("Il dispositivo non supporta la geolocalizzazione.");
      return;
    }
    setLocatingCatchGps(true);
    setCatchGpsError(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        fetch(`/api/reverse-geocode?lat=${latitude}&lon=${longitude}`)
          .then((r) => r.json())
          .then((d) => {
            setNewCatchLocation({
              lat: latitude,
              lon: longitude,
              name: d.ok ? d.name : "Posizione attuale",
            });
          })
          .finally(() => setLocatingCatchGps(false));
      },
      (err) => {
        setLocatingCatchGps(false);
        if (err.code === err.PERMISSION_DENIED) {
          setCatchGpsError("Permesso di posizione negato. Abilitalo nelle impostazioni del browser/telefono.");
        } else {
          setCatchGpsError("Non sono riuscito a rilevare la posizione.");
        }
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
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
      lat: newCatchLocation?.lat,
      lon: newCatchLocation?.lon,
      locationName: newCatchLocation?.name,
      time: new Date().toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" }),
    };
    setValues((v) => ({ ...v, catture: [...v.catture, entry] }));
    setNewCatch({ specie: "", lunghezza: "", peso: "", nota: "" });
    setNewCatchPhoto(null);
    setNewCatchLocation(null);
    setCatchGpsError(null);
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
                          ) : f.type === "select" ? (
                            (() => {
                              const dependsValue = f.optionsDependsOn
                                ? values.fields[f.optionsDependsOn]
                                : undefined;
                              const dynamicOptions = f.optionsByValue
                                ? dependsValue
                                  ? f.optionsByValue[dependsValue] || []
                                  : []
                                : f.options || [];
                              const waitingForDependency =
                                !!f.optionsDependsOn && !dependsValue;
                              return (
                                <select
                                  className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A] disabled:opacity-50"
                                  value={values.fields[f.key] || ""}
                                  disabled={waitingForDependency}
                                  onChange={(e) => setField(f.key, e.target.value)}
                                >
                                  <option value="">
                                    {waitingForDependency ? "Scegli prima la tecnica" : "—"}
                                  </option>
                                  {dynamicOptions.map((opt) => (
                                    <option key={opt} value={opt}>
                                      {opt}
                                    </option>
                                  ))}
                                </select>
                              );
                            })()
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
                {meteoError && <p className="text-xs text-[#FF9A3C]">{meteoError}</p>}
                {meteoResults.length > 0 && (
                  <div className="bg-[#0B1F2A] border border-white/10 rounded-lg overflow-hidden">
                    {meteoResults.map((r) => (
                      <button
                        key={r.id}
                        onClick={() => pickMeteoLocation(r)}
                        className="w-full text-left px-3 py-2 text-sm border-b border-white/10 last:border-0"
                      >
                        {r.name}
                        {(r.admin1 || r.country) && (
                          <span className="text-[#8FA8B2]">
                            {" "}
                            — {[r.admin1, r.country].filter(Boolean).join(", ")}
                          </span>
                        )}
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
                    onClick={addCatchLocation}
                    disabled={locatingCatchGps}
                    className={`w-full flex items-center justify-center gap-1.5 rounded-md py-2 text-[12.5px] disabled:opacity-50 ${
                      newCatchLocation
                        ? "bg-[#2CA6A4]/20 text-[#2CA6A4] border border-[#2CA6A4]/40"
                        : "border border-dashed border-white/20 text-[#8FA8B2]"
                    }`}
                  >
                    📍{" "}
                    {locatingCatchGps
                      ? "Rilevo la posizione…"
                      : newCatchLocation
                      ? `Posizione salvata: ${newCatchLocation.name}`
                      : "Aggiungi la posizione della cattura"}
                  </button>
                  {catchGpsError && <p className="text-[11px] text-[#FF9A3C]">{catchGpsError}</p>}

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
                      {c.lat != null && c.lon != null && (
                        <a
                          href={`https://www.google.com/maps?q=${c.lat},${c.lon}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-[11px] text-[#2CA6A4] mt-0.5 inline-block"
                        >
                          📍 {c.locationName || "Vedi posizione"}
                        </a>
                      )}
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
DIARIOFORMEOF

echo "=== File aggiornati: ==="
echo "  lib/diario-templates.ts"
echo "  components/DiarioForm.tsx"
echo ""
echo "Modifiche:"
echo "  - Feeder: Lenza madre, Terminale, Amo -> tendine (diametri/numeri standard)"
echo "  - Mare/Foce: aggiunto campo 'Tecnica' (Bolognese/Inglese)"
echo "  - Mare/Foce: 'Canna' e 'Galleggiante' ora dipendono dalla Tecnica"
echo "    scelta, con le due liste di misure specifiche"
echo "  - Mare/Foce: Amo, Filo madre, Terminale -> tendine"
echo "  - Mare/Foce: aggiunta 'Tipologia spot' (Scogliera/Foce/Porto/Spiaggia)"
echo "  - Se si cambia Tecnica dopo aver gia' scelto canna/galleggiante,"
echo "    quei due campi si azzerano automaticamente (evita valori non validi)"
echo ""
echo "Ricorda: bash tendine-mare-foce-avanzate.sh, poi:"
echo "git add -A && git commit -m 'tendine avanzate: canna/galleggiante per tecnica, diametri, tipologia spot' && git push"
