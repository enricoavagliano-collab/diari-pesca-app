#!/bin/bash
set -e
echo 'Diario a 4 schede, grafico marea, pagine Impostazioni/Guida/Info...'
mkdir -p "app/altro"
mkdir -p "app/altro/guida"
mkdir -p "app/altro/impostazioni"
mkdir -p "app/altro/info"
mkdir -p "app/diario/[bookId]"
mkdir -p "app/maree"
mkdir -p "components"
mkdir -p "lib"
cat > "lib/diario-templates.ts" << 'SETUP_EOF_MARKER'
import { BookId } from "./books";

export type FieldType = "text" | "date" | "time" | "textarea" | "number";

export interface DiarioField {
  key: string;
  label: string;
  type: FieldType;
  placeholder?: string;
}

export interface DiarioSection {
  title: string;
  fields: DiarioField[];
}

// "Dati sessione": i campi specifici del libro (Feeder vs Mare e Foce), raggruppati
// in sotto-sezioni solo per leggibilità del form — restano nella stessa scheda.
export const DIARIO_TEMPLATES: Record<Extract<BookId, "feeder" | "mare-e-foce">, DiarioSection[]> = {
  feeder: [
    {
      title: "Sessione",
      fields: [
        { key: "data", label: "Data", type: "date" },
        { key: "luogo", label: "Luogo", type: "text" },
        { key: "durata", label: "Durata", type: "text", placeholder: "es. 3h" },
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
        { key: "canna", label: "Canna (mt)", type: "text" },
        { key: "mulinello", label: "Mulinello", type: "text" },
        { key: "lenza_madre", label: "Lenza madre (mm)", type: "text" },
        { key: "terminale", label: "Terminale (mm)", type: "text" },
        { key: "amo", label: "Amo (nr)", type: "text" },
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
        { key: "orario", label: "Orario", type: "time" },
        { key: "vento", label: "Vento", type: "text" },
        { key: "profondita", label: "Profondità", type: "text", placeholder: "mt" },
        { key: "spot", label: "Spot", type: "text" },
      ],
    },
    {
      title: "Assetto tecnico",
      fields: [
        { key: "canna", label: "Canna (mt)", type: "text" },
        { key: "mulinello", label: "Mulinello", type: "text" },
        { key: "amo", label: "Amo", type: "text" },
        { key: "galleggiante", label: "Galleggiante (gr)", type: "text" },
        { key: "filo_madre", label: "Filo madre (mm)", type: "text" },
        { key: "terminale", label: "Terminale (mm)", type: "text" },
      ],
    },
  ],
};

// Condizioni rapide selezionabili nella scheda Meteo del diario (tag on/off)
export const CONDIZIONI_TAGS = ["Mare calmo", "Mare mosso", "Acqua limpida", "Poco vento", "Vento forte", "Corrente"];

SETUP_EOF_MARKER
cat > "lib/diario-entries.ts" << 'SETUP_EOF_MARKER'
import { sql } from "./db";
import { BookId } from "./books";

export interface CatchEntry {
  id: string;
  specie: string;
  lunghezza?: string;
  peso?: string;
  time: string; // HH:mm
}

export interface MeteoSnapshot {
  locationName: string;
  tempC?: number;
  windSpeed?: number;
  windDirection?: number;
  pressure?: number;
  description?: string;
  icon?: string;
}

export interface DiarioEntryData {
  fields: Record<string, string>;
  catture: CatchEntry[];
  meteo?: MeteoSnapshot;
  condizioni: string[];
  note: string;
}

export interface DiarioEntry {
  id: string;
  bookId: BookId;
  deviceId: string;
  createdAt: string;
  data: DiarioEntryData;
}

function parseData(raw: unknown): DiarioEntryData {
  if (typeof raw === "string") return JSON.parse(raw);
  return raw as DiarioEntryData;
}

export async function addEntry(
  entry: Omit<DiarioEntry, "id" | "createdAt">
): Promise<DiarioEntry> {
  const [row] = await sql`
    INSERT INTO diario_entries (book_id, device_id, data)
    VALUES (${entry.bookId}, ${entry.deviceId}, ${sql.json(entry.data as unknown as never)})
    RETURNING id, book_id, device_id, data, created_at
  `;
  return {
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: parseData(row.data),
    createdAt: row.created_at.toISOString(),
  };
}

export async function getEntries(
  bookId: BookId,
  deviceId: string
): Promise<DiarioEntry[]> {
  const rows = await sql`
    SELECT id, book_id, device_id, data, created_at
    FROM diario_entries
    WHERE book_id = ${bookId} AND device_id = ${deviceId}
    ORDER BY created_at DESC
  `;
  return rows.map((row) => ({
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: parseData(row.data),
    createdAt: row.created_at.toISOString(),
  }));
}

export async function deleteEntry(id: string, deviceId: string): Promise<boolean> {
  const rows = await sql`
    DELETE FROM diario_entries WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id
  `;
  return rows.length > 0;
}

SETUP_EOF_MARKER
cat > "components/DiarioForm.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import { BookId } from "@/lib/books";
import { DiarioSection, CONDIZIONI_TAGS } from "@/lib/diario-templates";
import type { DiarioEntryData, CatchEntry, MeteoSnapshot } from "@/lib/diario-entries";
import { ClipboardList, CloudSun, Fish, StickyNote, Plus, Trash2, Search } from "lucide-react";

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

  // Nuova cattura in compilazione
  const [newCatch, setNewCatch] = useState({ specie: "", lunghezza: "", peso: "" });

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

  const pickMeteoLocation = useCallback((loc: GeoResult) => {
    setLoadingMeteo(true);
    setMeteoQuery("");
    setMeteoResults([]);
    fetch(`/api/meteo?lat=${loc.latitude}&lon=${loc.longitude}`)
      .then((r) => r.json())
      .then((d) => {
        if (!d.ok || !d.days?.length) return;
        const todaySlot = d.days[0].slots.find((s: { time: string }) => s.time.startsWith("12")) || d.days[0].slots[0];
        const snapshot: MeteoSnapshot = {
          locationName: loc.name,
          tempC: todaySlot.tempC,
          windSpeed: todaySlot.windSpeed,
          windDirection: todaySlot.windDirection,
          pressure: todaySlot.pressure,
          description: todaySlot.description,
          icon: todaySlot.icon,
        };
        setValues((v) => ({ ...v, meteo: snapshot }));
      })
      .finally(() => setLoadingMeteo(false));
  }, []);

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
      time: new Date().toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" }),
    };
    setValues((v) => ({ ...v, catture: [...v.catture, entry] }));
    setNewCatch({ specie: "", lunghezza: "", peso: "" });
  }

  function removeCatch(id: string) {
    setValues((v) => ({ ...v, catture: v.catture.filter((c) => c.id !== id) }));
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
      setValues(emptyData());
      setFormOpen(false);
      setTab("dati");
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

  const totalPeso = values.catture.reduce((sum, c) => sum + (parseFloat(c.peso || "0") || 0), 0);

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <h2 className="font-medium text-lg" style={{ fontFamily: "var(--font-fraunces)" }}>
          Il tuo diario digitale
        </h2>
        <button
          onClick={() => setFormOpen((o) => !o)}
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
                    {CONDIZIONI_TAGS.map((tag) => (
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
                    <Fish size={16} className="text-[#2CA6A4] flex-shrink-0" />
                    <div className="flex-1">
                      <div className="text-sm">{c.specie}</div>
                      <div className="text-[11px] text-[#8FA8B2]">
                        {c.time} {c.lunghezza && `· ${c.lunghezza}cm`} {c.peso && `· ${c.peso}g`}
                      </div>
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
              {saving ? "Salvataggio…" : "Salva voce nel diario"}
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
              className="text-xs text-[#8FA8B2] hover:text-red-400"
            >
              elimina
            </button>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {entry.data.catture?.length > 0 && (
              <span className="text-[11px] bg-[#0B1F2A] border border-white/10 rounded-full px-2 py-0.5">
                🐟 {entry.data.catture.length} catture
              </span>
            )}
            {entry.data.meteo && (
              <span className="text-[11px] bg-[#0B1F2A] border border-white/10 rounded-full px-2 py-0.5">
                {entry.data.meteo.icon} {entry.data.meteo.tempC}°
              </span>
            )}
            {Object.entries(entry.data.fields || {})
              .filter(([, v]) => v)
              .slice(0, 4)
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
cat > "components/TideChart.tsx" << 'SETUP_EOF_MARKER'
"use client";

interface TidePoint {
  time: string; // HH:mm
  type: "alta" | "bassa";
  height: number;
}

function timeToMinutes(t: string): number {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}

/**
 * Disegna una curva di marea approssimata (interpolazione cosinusoidale tra i
 * punti alta/bassa reali) — non è il dato grezzo orario, ma visivamente
 * rappresenta bene l'andamento reale tra i picchi che abbiamo.
 */
export default function TideChart({ points }: { points: TidePoint[] }) {
  if (points.length < 2) return null;

  const width = 340;
  const height = 140;
  const padTop = 15;
  const padBottom = 30;
  const plotH = height - padTop - padBottom;

  const heights = points.map((p) => p.height);
  const minH = Math.min(...heights, -0.1);
  const maxH = Math.max(...heights, 0.1);
  const range = maxH - minH || 1;

  function yFor(h: number): number {
    return padTop + plotH - ((h - minH) / range) * plotH;
  }
  function xFor(minutes: number): number {
    return (minutes / 1440) * width;
  }

  // Genera la curva passando dolcemente da un punto al successivo (Catmull-Rom semplificato)
  const sorted = [...points].sort((a, b) => timeToMinutes(a.time) - timeToMinutes(b.time));
  let path = "";
  const steps = 60;
  for (let i = 0; i < sorted.length - 1; i++) {
    const p0 = sorted[i];
    const p1 = sorted[i + 1];
    const t0 = timeToMinutes(p0.time);
    const t1 = timeToMinutes(p1.time);
    for (let s = 0; s <= steps; s++) {
      const frac = s / steps;
      // Interpolazione coseno: transizione morbida tra un picco e il successivo
      const smooth = (1 - Math.cos(frac * Math.PI)) / 2;
      const h = p0.height + (p1.height - p0.height) * smooth;
      const t = t0 + (t1 - t0) * frac;
      const x = xFor(t);
      const y = yFor(h);
      path += i === 0 && s === 0 ? `M${x},${y} ` : `L${x},${y} `;
    }
  }

  return (
    <svg viewBox={`0 0 ${width} ${height}`} className="w-full" style={{ height: 150 }}>
      <path d={path} fill="none" stroke="#2CA6A4" strokeWidth={2} strokeLinecap="round" />
      {sorted.map((p, i) => {
        const x = xFor(timeToMinutes(p.time));
        const y = yFor(p.height);
        return (
          <g key={i}>
            <circle cx={x} cy={y} r={3.5} fill="#FF9A3C" />
            <text
              x={x}
              y={p.type === "alta" ? y - 9 : y + 16}
              fontSize="9"
              fill="#8FA8B2"
              textAnchor="middle"
              fontFamily="var(--font-mono)"
            >
              {p.time}
            </text>
          </g>
        );
      })}
      {[0, 6, 12, 18, 24].map((h) => (
        <text
          key={h}
          x={xFor(h * 60)}
          y={height - 6}
          fontSize="8.5"
          fill="#8FA8B2"
          textAnchor="middle"
          fontFamily="var(--font-mono)"
        >
          {String(h).padStart(2, "0")}:00
        </text>
      ))}
    </svg>
  );
}

SETUP_EOF_MARKER
cat > "app/diario/[bookId]/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import Image from "next/image";
import { FileText } from "lucide-react";
import { BOOKS, BookId } from "@/lib/books";
import { DIARIO_TEMPLATES } from "@/lib/diario-templates";
import DiarioForm from "@/components/DiarioForm";

// Link Drive reali forniti da Enrico + argomenti dei 4 PDF per libro
const PDF_FOLDERS: Record<string, { link: string; topics: string[] }> = {
  feeder: {
    link: "https://drive.google.com/drive/folders/1x3cVL9F61G6g7b6Q3gmwp7dLVxY9AZfV",
    topics: ["Feeder generale", "Pasturazione", "Attrezzatura", "Lenze Feeder"],
  },
  "mare-e-foce": {
    link: "https://drive.google.com/drive/folders/1Q2wTAyLYlg0hmYlo9l-H-1ZRWANmzS5a",
    topics: ["Mare e Foce", "Maree", "Luna", "Lenze"],
  },
};

const COVERS: Record<string, string> = {
  feeder: "/covers/feeder.jpg",
  "mare-e-foce": "/covers/mare-e-foce.jpg",
  "senso-acqua": "/covers/senso-acqua.jpg",
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
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/diario" className="text-xs text-[#8FA8B2]">
          ← Diario
        </Link>

        <div className="flex items-center gap-3 mt-2 mb-5">
          <div className="relative w-14 h-20 rounded-md overflow-hidden flex-shrink-0 border border-white/10">
            <Image src={COVERS[bookId]} alt={book.name} fill sizes="56px" className="object-cover" />
          </div>
          <div>
            <h1 className="text-[19px]" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
              {book.name}
            </h1>
            <span className="inline-block mt-1 text-[10px] px-2 py-0.5 rounded-full font-mono bg-[#7CB342]/20 text-[#9FD16A]">
              ✓ Sbloccato
            </span>
          </div>
        </div>

        <h2 className="text-[11px] uppercase tracking-[0.08em] text-[#8FA8B2] font-medium mb-2.5">
          PDF inclusi
        </h2>
        <div className="grid grid-cols-2 gap-2.5 mb-6">
          {pdf.topics.map((topic) => (
            <a
              key={topic}
              href={pdf.link}
              target="_blank"
              rel="noopener noreferrer"
              className="bg-[#124E5A] border border-white/10 rounded-xl p-3 flex flex-col gap-2"
            >
              <div className="w-8 h-8 rounded-md bg-[#0B1F2A] flex items-center justify-center">
                <FileText size={15} strokeWidth={1.75} className="text-[#FF9A3C]" />
              </div>
              <span className="text-[12.5px] leading-snug">{topic}</span>
              <span className="text-[10px] text-[#2CA6A4]">Apri →</span>
            </a>
          ))}
        </div>

        <DiarioForm bookId={bookId as BookId} template={template} />
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/maree/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import TideChart from "@/components/TideChart";

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
cat > "app/altro/page.tsx" << 'SETUP_EOF_MARKER'
import Link from "next/link";
import { Anchor, CalendarDays, Newspaper, KeyRound, Settings, HelpCircle, Info, ChevronRight } from "lucide-react";

const VOCI = [
  { href: "/lenze", Icon: Anchor, title: "Le mie lenze", subtitle: "Le configurazioni di Enrico e le tue" },
  { href: "/specie", Icon: CalendarDays, title: "Specie e periodi", subtitle: "Calendario delle specie" },
  { href: "/articoli", Icon: Newspaper, title: "Articoli", subtitle: "Tutti gli articoli del blog" },
  { href: "/sblocca", Icon: KeyRound, title: "Hai un codice?", subtitle: "Accedi ai contenuti esclusivi" },
];

const VOCI_APP = [
  { href: "/altro/impostazioni", Icon: Settings, title: "Impostazioni" },
  { href: "/altro/guida", Icon: HelpCircle, title: "Guida e supporto" },
  { href: "/altro/info", Icon: Info, title: "Informazioni sull'app" },
];

export default function AltroPage() {
  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <h1 className="text-[22px] mb-5" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Altro
        </h1>

        <div className="space-y-2.5 mb-6">
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

        <div className="border-t border-white/10 pt-4 space-y-1">
          {VOCI_APP.map(({ href, Icon, title }) => (
            <Link key={href} href={href} className="flex items-center gap-3 py-2.5">
              <Icon size={17} strokeWidth={1.75} className="text-[#8FA8B2]" />
              <span className="text-sm flex-1">{title}</span>
              <ChevronRight size={15} className="text-[#8FA8B2]" />
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/altro/impostazioni/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useState } from "react";
import Link from "next/link";
import { Trash2 } from "lucide-react";

export default function ImpostazioniPage() {
  const [cleared, setCleared] = useState(false);

  function clearSavedLocations() {
    localStorage.removeItem("maree_locations");
    localStorage.removeItem("meteo_locations");
    setCleared(true);
    setTimeout(() => setCleared(false), 2000);
  }

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <Link href="/altro" className="text-xs text-[#8FA8B2]">
          ← Altro
        </Link>
        <h1 className="text-[22px] mt-2 mb-5" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Impostazioni
        </h1>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
          <h3 className="text-sm font-semibold mb-1">Località salvate</h3>
          <p className="text-[12.5px] text-[#8FA8B2] mb-3 leading-relaxed">
            Le località che hai cercato in Maree e Meteo restano salvate solo su questo
            dispositivo. Puoi cancellarle in ogni momento.
          </p>
          <button
            onClick={clearSavedLocations}
            className="flex items-center gap-2 text-sm text-[#FF9A3C] font-medium"
          >
            <Trash2 size={15} />
            {cleared ? "Cancellate ✓" : "Cancella località salvate"}
          </button>
        </div>

        <p className="text-[11px] text-[#8FA8B2] mt-6 leading-relaxed px-1">
          ⓘ L&apos;app non richiede un account: i tuoi dati (diario, lenze salvate,
          sblocchi) restano legati a questo dispositivo/browser specifico.
        </p>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/altro/guida/page.tsx" << 'SETUP_EOF_MARKER'
import Link from "next/link";

const FAQ = [
  {
    q: "Come sblocco i contenuti di un libro?",
    a: "Inquadra il QR stampato nella prima pagina della tua copia con la fotocamera del telefono. In alternativa, vai su \"Hai un codice? Sbloccalo qui\" nella home e inseriscilo a mano.",
  },
  {
    q: "Ho sbloccato un libro su un dispositivo, funziona anche su un altro?",
    a: "Ogni codice funziona su un numero limitato di dispositivi (di solito 2-3), pensato per l'uso personale. Se hai finito i tentativi disponibili, contattaci per assistenza.",
  },
  {
    q: "Gli orari di marea sono precisi al minuto?",
    a: "Sono previsioni (non un dato ufficiale di navigazione) e possono scostarsi di qualche decina di minuti dal dato reale locale — utili per farsi un'idea, non per la sicurezza in mare.",
  },
  {
    q: "Il mio diario resta salvato se cambio telefono?",
    a: "No: il diario digitale, le lenze salvate e gli sblocchi restano legati al dispositivo/browser su cui li hai creati, non c'è un account centrale.",
  },
];

export default function GuidaPage() {
  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <Link href="/altro" className="text-xs text-[#8FA8B2]">
          ← Altro
        </Link>
        <h1 className="text-[22px] mt-2 mb-5" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Guida e supporto
        </h1>

        <div className="space-y-3 mb-6">
          {FAQ.map((item, i) => (
            <div key={i} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
              <h3 className="text-sm font-semibold mb-1.5">{item.q}</h3>
              <p className="text-[12.5px] text-[#8FA8B2] leading-relaxed">{item.a}</p>
            </div>
          ))}
        </div>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
          <h3 className="text-sm font-semibold mb-1.5">Serve altro aiuto?</h3>
          <p className="text-[12.5px] text-[#8FA8B2] leading-relaxed mb-2">
            Scrivi a Enrico direttamente dal blog:
          </p>
          <a
            href="https://enricoavagliano.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-[#2CA6A4] underline"
          >
            enricoavagliano.com →
          </a>
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/altro/info/page.tsx" << 'SETUP_EOF_MARKER'
import Link from "next/link";
import { Fish } from "lucide-react";

export default function InfoPage() {
  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <Link href="/altro" className="text-xs text-[#8FA8B2]">
          ← Altro
        </Link>

        <div className="text-center mt-6 mb-8">
          <Fish size={32} strokeWidth={1.5} className="mx-auto mb-3 text-[#2CA6A4]" />
          <h1 className="text-[20px]" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 600 }}>
            Libri di Pesca
          </h1>
          <p className="text-[12px] text-[#8FA8B2] mt-1">Tutta la pesca a portata di click</p>
        </div>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4 mb-3">
          <p className="text-[13px] text-[#F6F5F1] leading-relaxed">
            L&apos;app companion dei libri di pesca di Enrico Avagliano — diario digitale,
            maree, meteo, lenze e specie, tutto in un unico posto.
          </p>
        </div>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
          <h3 className="text-sm font-semibold mb-1.5">Un progetto di</h3>
          <a
            href="https://enricoavagliano.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-[#2CA6A4] underline"
          >
            Enrico Avagliano
          </a>
          <p className="text-[12px] text-[#8FA8B2] mt-1">La pesca a portata di click</p>
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
echo "Fatto: diario con meteo automatico e catture, grafico marea reale, nuove pagine Altro."