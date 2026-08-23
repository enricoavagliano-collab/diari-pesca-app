#!/bin/bash
set -e
echo 'Creo le cartelle...'
mkdir -p "app"
mkdir -p "app/api/lenze"
mkdir -p "app/api/lenze/[id]"
mkdir -p "app/lenze"
mkdir -p "lib"
echo 'Aggiungo/aggiorno i file...'
cat > "lib/schema.sql" << 'SETUP_EOF_MARKER'
-- Schema del database "Diari di Pesca".
-- Su Vercel: dalla dashboard del database (tab Storage → il tuo DB → Query),
-- incolla e esegui questo file una sola volta dopo aver collegato il database.

CREATE TABLE IF NOT EXISTS activations (
  id SERIAL PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (book_id, device_id)
);

CREATE TABLE IF NOT EXISTS diario_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lenze_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lenze_device_category
  ON lenze_entries (device_id, category);

CREATE INDEX IF NOT EXISTS idx_diario_book_device
  ON diario_entries (book_id, device_id);

CREATE INDEX IF NOT EXISTS idx_activations_book
  ON activations (book_id);

SETUP_EOF_MARKER
cat > "lib/lenze-official.ts" << 'SETUP_EOF_MARKER'
export type LenzaCategory = "mare" | "feeder";

export interface LenzaField {
  key: string;
  label: string;
}

export interface OfficialLenza {
  id: string;
  category: LenzaCategory;
  title: string;
  specs: { label: string; value: string }[];
  note: string;
}

export const LENZA_FIELDS: LenzaField[] = [
  { key: "madre", label: "Madre" },
  { key: "finale", label: "Finale" },
  { key: "galleggiante", label: "Galleggiante" },
  { key: "piombatura", label: "Piombatura" },
  { key: "tecnica", label: "Tecnica" },
  { key: "condizioni", label: "Condizioni" },
];

export const OFFICIAL_LENZE: OfficialLenza[] = [
  {
    id: "mare-1",
    category: "mare",
    title: "Bolognese in foce — trattenuta di fondo",
    specs: [
      { label: "Madre", value: "0.16" },
      { label: "Finale", value: "0.14" },
      { label: "Galleggiante", value: "3+2g scorrevole" },
      { label: "Piombatura", value: "Scalata, 4 pallini" },
      { label: "Tecnica", value: "Trattenuta" },
      { label: "Condizioni", value: "Corrente moderata" },
    ],
    note: "La mia base per orata e spigola nella zona di fine divieto — tiene bene anche con un filo di corrente contraria.",
  },
  {
    id: "mare-2",
    category: "mare",
    title: "Bolognese leggera — passata a cefalo",
    specs: [
      { label: "Madre", value: "0.14" },
      { label: "Finale", value: "0.12" },
      { label: "Galleggiante", value: "1+1g penna" },
      { label: "Piombatura", value: "Raggruppata" },
      { label: "Tecnica", value: "Passata" },
      { label: "Condizioni", value: "Acqua ferma/salmastro" },
    ],
    note: "Discesa lenta, essenziale col cefalo diffidente sotto costa.",
  },
  {
    id: "feeder-1",
    category: "feeder",
    title: "Feeder classico — canale a corrente lenta",
    specs: [
      { label: "Madre", value: "0.18" },
      { label: "Finale", value: "0.14" },
      { label: "Galleggiante", value: "—" },
      { label: "Piombatura", value: "Cage 30g" },
      { label: "Tecnica", value: "Feeder fermo" },
      { label: "Condizioni", value: "Corrente lenta" },
    ],
    note: "Il mio assetto di partenza quando non conosco ancora bene lo spot.",
  },
];

export function getOfficialByCategory(category: LenzaCategory): OfficialLenza[] {
  return OFFICIAL_LENZE.filter((l) => l.category === category);
}

SETUP_EOF_MARKER
cat > "lib/lenze-entries.ts" << 'SETUP_EOF_MARKER'
import { sql } from "./db";
import { LenzaCategory } from "./lenze-official";

export interface LenzaEntry {
  id: string;
  deviceId: string;
  category: LenzaCategory;
  title: string;
  data: Record<string, string>;
  createdAt: string;
}

export async function addLenza(
  entry: Omit<LenzaEntry, "id" | "createdAt">
): Promise<LenzaEntry> {
  const [row] = await sql`
    INSERT INTO lenze_entries (device_id, category, title, data)
    VALUES (${entry.deviceId}, ${entry.category}, ${entry.title}, ${sql.json(entry.data)})
    RETURNING id, device_id, category, title, data, created_at
  `;
  return {
    id: row.id,
    deviceId: row.device_id,
    category: row.category,
    title: row.title,
    data: row.data,
    createdAt: row.created_at.toISOString(),
  };
}

export async function getLenze(
  deviceId: string,
  category: LenzaCategory
): Promise<LenzaEntry[]> {
  const rows = await sql`
    SELECT id, device_id, category, title, data, created_at
    FROM lenze_entries
    WHERE device_id = ${deviceId} AND category = ${category}
    ORDER BY created_at DESC
  `;
  return rows.map((row) => ({
    id: row.id,
    deviceId: row.device_id,
    category: row.category,
    title: row.title,
    data: row.data,
    createdAt: row.created_at.toISOString(),
  }));
}

export async function deleteLenza(id: string, deviceId: string): Promise<boolean> {
  const rows = await sql`
    DELETE FROM lenze_entries WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id
  `;
  return rows.length > 0;
}

SETUP_EOF_MARKER
cat > "app/api/lenze/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { addLenza, getLenze } from "@/lib/lenze-entries";
import { LenzaCategory } from "@/lib/lenze-official";

export async function POST(req: NextRequest) {
  const { deviceId, category, title, data } = await req.json();

  if (!deviceId || !category || !title) {
    return NextResponse.json({ ok: false, error: "Dati mancanti." }, { status: 400 });
  }

  const entry = await addLenza({ deviceId, category, title, data: data || {} });
  return NextResponse.json({ ok: true, entry });
}

export async function GET(req: NextRequest) {
  const deviceId = req.nextUrl.searchParams.get("deviceId");
  const category = req.nextUrl.searchParams.get("category") as LenzaCategory | null;

  if (!deviceId || !category) {
    return NextResponse.json({ ok: false, error: "Parametri mancanti." }, { status: 400 });
  }

  const entries = await getLenze(deviceId, category);
  return NextResponse.json({ ok: true, entries });
}

SETUP_EOF_MARKER
cat > "app/api/lenze/[id]/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { deleteLenza } from "@/lib/lenze-entries";

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { deviceId } = await req.json();

  if (!deviceId) {
    return NextResponse.json({ ok: false, error: "Dispositivo mancante." }, { status: 400 });
  }

  const ok = await deleteLenza(id, deviceId);
  if (!ok) {
    return NextResponse.json({ ok: false, error: "Lenza non trovata." }, { status: 404 });
  }

  return NextResponse.json({ ok: true });
}

SETUP_EOF_MARKER
cat > "app/lenze/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { LENZA_FIELDS, getOfficialByCategory, LenzaCategory } from "@/lib/lenze-official";

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

export default function LenzePage() {
  const [category, setCategory] = useState<LenzaCategory>("mare");
  const [subtab, setSubtab] = useState<"enrico" | "mie">("enrico");
  const [mine, setMine] = useState<LenzaEntry[]>([]);
  const [formOpen, setFormOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [values, setValues] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const deviceId = typeof window !== "undefined" ? getDeviceId() : "";

  const loadMine = useCallback((cat: LenzaCategory) => {
    if (!deviceId) return;
    fetch(`/api/lenze?deviceId=${deviceId}&category=${cat}`)
      .then((r) => r.json())
      .then((d) => {
        if (d.ok) setMine(d.entries);
      });
  }, [deviceId]);

  useEffect(() => {
    loadMine(category);
  }, [category, loadMine]);

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

  const officialList = getOfficialByCategory(category);

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "Georgia, serif" }}>
          Le mie lenze
        </h1>

        {/* Filtro categoria */}
        <div className="flex gap-1.5 mb-3">
          <button
            onClick={() => setCategory("mare")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "mare"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🌊 Mare / Foce
          </button>
          <button
            onClick={() => setCategory("feeder")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "feeder"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🎣 Feeder
          </button>
        </div>

        {/* Sotto-schede */}
        <div className="flex gap-1 mb-4 bg-[#eeece3] rounded-xl p-1">
          <button
            onClick={() => setSubtab("enrico")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "enrico" ? "bg-white text-[#16232B]" : "text-[#6B7E82]"
            }`}
          >
            Da Enrico
          </button>
          <button
            onClick={() => setSubtab("mie")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "mie" ? "bg-white text-[#16232B]" : "text-[#6B7E82]"
            }`}
          >
            Le mie
          </button>
        </div>

        {subtab === "enrico" && (
          <div className="space-y-3">
            {officialList.length === 0 && (
              <p className="text-sm text-[#6B7E82]">
                Nessuna configurazione pubblicata ancora per questa categoria.
              </p>
            )}
            {officialList.map((l) => (
              <div key={l.id} className="bg-white border border-[#E1DFD6] rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "Georgia, serif" }}>
                  {l.title}
                </h3>
                <p className="text-[11px] text-[#6B7E82] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-[#E1DFD6]">
                  {l.specs.map((s) => (
                    <div key={s.label}>
                      <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">{s.label}</div>
                      <div className="font-mono text-[12.5px]">{s.value}</div>
                    </div>
                  ))}
                </div>
                <p className="text-[12px] text-[#6B7E82] italic mt-3 leading-relaxed">{l.note}</p>
              </div>
            ))}
          </div>
        )}

        {subtab === "mie" && (
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-xs text-[#6B7E82]">{mine.length} lenze salvate</span>
              <button
                onClick={() => setFormOpen((o) => !o)}
                className="w-8 h-8 rounded-full bg-[#2C6E71] text-white text-lg flex items-center justify-center"
              >
                {formOpen ? "×" : "+"}
              </button>
            </div>

            {formOpen && (
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-4 space-y-3">
                <div>
                  <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">Nome</label>
                  <input
                    className="w-full border border-[#E1DFD6] rounded-md px-2.5 py-2 text-sm bg-[#F6F5F1]"
                    placeholder="es. La mia bolognese da canale"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                  />
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  {LENZA_FIELDS.map((f) => (
                    <div key={f.key}>
                      <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">{f.label}</label>
                      <input
                        className="w-full border border-[#E1DFD6] rounded-md px-2.5 py-2 text-sm bg-[#F6F5F1]"
                        value={values[f.key] || ""}
                        onChange={(e) => setField(f.key, e.target.value)}
                      />
                    </div>
                  ))}
                </div>
                <button
                  onClick={save}
                  disabled={saving || !title.trim()}
                  className="w-full bg-[#0F2D3D] text-white rounded-xl py-2.5 text-sm font-medium disabled:opacity-50"
                >
                  {saving ? "Salvataggio…" : "Salva lenza"}
                </button>
              </div>
            )}

            {mine.length === 0 && !formOpen && (
              <p className="text-sm text-[#6B7E82]">Nessuna lenza salvata ancora — inizia dal +</p>
            )}

            {mine.map((entry) => (
              <div key={entry.id} className="bg-white border border-[#E1DFD6] rounded-xl p-4">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-medium text-[15px]" style={{ fontFamily: "Georgia, serif" }}>
                    {entry.title}
                  </h3>
                  <button
                    onClick={() => remove(entry.id)}
                    className="text-xs text-[#6B7E82] hover:text-red-600 flex-shrink-0"
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
                        className="text-[11px] bg-[#F6F5F1] border border-[#E1DFD6] rounded-full px-2 py-0.5"
                      >
                        {v}
                      </span>
                    ))}
                </div>
              </div>
            ))}
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
            <p className="text-xs text-[#6B7E82]">Configurazioni bolognese, le tue e quelle salvate</p>
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
echo '✓ Sezione Le mie lenze aggiunta.'
echo ''
echo '⚠️  IMPORTANTE: serve anche aggiornare il database — vai su Vercel, tab Storage → il tuo database → Query, e incolla questo:'
echo ''
cat << 'SQLEOF'
CREATE TABLE IF NOT EXISTS lenze_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_lenze_device_category ON lenze_entries (device_id, category);
SQLEOF