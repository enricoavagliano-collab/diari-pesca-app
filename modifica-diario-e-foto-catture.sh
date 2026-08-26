#!/bin/bash
set -e
echo 'Aggiungo modifica voci diario, foto e nota per le catture...'
mkdir -p "app/api/diario/[id]"
mkdir -p "components"
mkdir -p "lib"
cat > "lib/diario-entries.ts" << 'SETUP_EOF_MARKER'
import { sql } from "./db";
import { BookId } from "./books";

export interface CatchEntry {
  id: string;
  specie: string;
  lunghezza?: string;
  peso?: string;
  time: string; // HH:mm
  foto?: string; // immagine compressa, salvata come data URL
  nota?: string;
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

export async function updateEntry(
  id: string,
  deviceId: string,
  data: DiarioEntryData
): Promise<DiarioEntry | null> {
  const [row] = await sql`
    UPDATE diario_entries
    SET data = ${sql.json(data as unknown as never)}
    WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id, book_id, device_id, data, created_at
  `;
  if (!row) return null;
  return {
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: parseData(row.data),
    createdAt: row.created_at.toISOString(),
  };
}

export async function deleteEntry(id: string, deviceId: string): Promise<boolean> {
  const rows = await sql`
    DELETE FROM diario_entries WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id
  `;
  return rows.length > 0;
}

SETUP_EOF_MARKER
cat > "app/api/diario/[id]/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { deleteEntry, updateEntry } from "@/lib/diario-entries";

export async function PUT(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { deviceId, data } = await req.json();

  if (!deviceId || !data) {
    return NextResponse.json({ ok: false, error: "Dati mancanti." }, { status: 400 });
  }

  const entry = await updateEntry(id, deviceId, data);
  if (!entry) {
    return NextResponse.json({ ok: false, error: "Voce non trovata." }, { status: 404 });
  }

  return NextResponse.json({ ok: true, entry });
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { deviceId } = await req.json();

  if (!deviceId) {
    return NextResponse.json({ ok: false, error: "Dispositivo mancante." }, { status: 400 });
  }

  const ok = await deleteEntry(id, deviceId);
  if (!ok) {
    return NextResponse.json({ ok: false, error: "Voce non trovata." }, { status: 404 });
  }

  return NextResponse.json({ ok: true });
}

SETUP_EOF_MARKER
cat > "components/DiarioForm.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import { BookId } from "@/lib/books";
import { DiarioSection, CONDIZIONI_TAGS } from "@/lib/diario-templates";
import type { DiarioEntryData, CatchEntry, MeteoSnapshot } from "@/lib/diario-entries";
import { ClipboardList, CloudSun, Fish, StickyNote, Plus, Trash2, Search, Camera, Pencil } from "lucide-react";

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

  // Nuova cattura in compilazione
  const [newCatch, setNewCatch] = useState({ specie: "", lunghezza: "", peso: "", nota: "" });
  const [newCatchPhoto, setNewCatchPhoto] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);

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
                    <input type="file" accept="image/*" capture="environment" className="hidden" onChange={handlePhotoSelect} />
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
                      <img src={c.foto} alt={c.specie} className="w-10 h-10 rounded-md object-cover flex-shrink-0" />
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
              .slice(0, 4)
              .map(([k, v]) => (
                <span
                  key={k}
                  className="text-[11.5px] bg-[#0B1F2A] border border-white/10 rounded-full px-2.5 py-1"
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
echo "Fatto: ora puoi modificare una sessione salvata, e aggiungere foto+nota ad ogni cattura."