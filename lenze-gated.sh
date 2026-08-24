#!/bin/bash
set -e
echo 'Aggiungo la regola di accesso alle lenze legata all acquisto...'
mkdir -p "app"
mkdir -p "app/lenze"
cat > "app/lenze/LenzeClient.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import {
  LenzaCategory,
  Tecnica,
  TECNICHE,
  TECNICA_VARIANTI,
  getOfficialLenza,
  OFFICIAL_ASSETTI,
  LENZA_FIELDS_MARE,
  ASSETTO_FIELDS_FEEDER,
} from "@/lib/lenze-official";

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

export default function LenzeClient({
  unlockedMare,
  unlockedFeeder,
}: {
  unlockedMare: boolean;
  unlockedFeeder: boolean;
}) {
  const [category, setCategory] = useState<LenzaCategory>("mare");
  const [subtab, setSubtab] = useState<"enrico" | "mie">("enrico");
  const [tecnica, setTecnica] = useState<Tecnica>("trattenuta");
  const [variante, setVariante] = useState<string>(TECNICA_VARIANTI["trattenuta"][0].id);

  const [mine, setMine] = useState<LenzaEntry[]>([]);
  const [formOpen, setFormOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [values, setValues] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const deviceId = typeof window !== "undefined" ? getDeviceId() : "";

  const loadMine = useCallback(
    (cat: LenzaCategory) => {
      if (!deviceId) return;
      fetch(`/api/lenze?deviceId=${deviceId}&category=${cat}`)
        .then((r) => r.json())
        .then((d) => {
          if (d.ok) setMine(d.entries);
        });
    },
    [deviceId]
  );

  useEffect(() => {
    loadMine(category);
  }, [category, loadMine]);

  useEffect(() => {
    // Quando cambia la tecnica, seleziona la prima variante disponibile
    setVariante(TECNICA_VARIANTI[tecnica][0].id);
  }, [tecnica]);

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

  const spec = category === "mare" ? getOfficialLenza(tecnica, variante) : null;
  const personalFields = category === "mare" ? LENZA_FIELDS_MARE : ASSETTO_FIELDS_FEEDER;
  const categoryUnlocked = category === "mare" ? unlockedMare : unlockedFeeder;

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "Georgia, serif" }}>
          Le mie lenze
        </h1>

        {/* Categoria principale */}
        <div className="flex gap-1.5 mb-3">
          <button
            onClick={() => setCategory("mare")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "mare"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🌊 Mare / Foce {!unlockedMare && "🔒"}
          </button>
          <button
            onClick={() => setCategory("feeder")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "feeder"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🎣 Feeder {!unlockedFeeder && "🔒"}
          </button>
        </div>

        {!categoryUnlocked ? (
          <div className="bg-white border border-[#E1DFD6] rounded-xl p-6 text-center mt-4">
            <div className="text-3xl mb-3">🔒</div>
            <h2 className="font-medium text-[15px] mb-1.5">
              {category === "mare" ? "Sblocca con Mare e Foce" : "Sblocca con Diario Feeder"}
            </h2>
            <p className="text-sm text-[#6B7E82] leading-relaxed">
              Questa sezione fa parte dei contenuti del diario{" "}
              {category === "mare" ? "Mare e Foce" : "Feeder"} — inquadra il QR nella prima
              pagina della tua copia per sbloccarla.
            </p>
          </div>
        ) : (
          <>
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

        {/* ===== DA ENRICO — MARE/FOCE ===== */}
        {subtab === "enrico" && category === "mare" && (
          <div>
            <div className="flex gap-1.5 overflow-x-auto pb-1 mb-3 -mx-1 px-1">
              {TECNICHE.map((t) => (
                <button
                  key={t.id}
                  onClick={() => setTecnica(t.id)}
                  className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
                    tecnica === t.id
                      ? "bg-[#0F2D3D] text-white border-[#0F2D3D]"
                      : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            <div className="flex flex-wrap gap-1.5 mb-4">
              {TECNICA_VARIANTI[tecnica].map((v) => (
                <button
                  key={v.id}
                  onClick={() => setVariante(v.id)}
                  className={`text-[11.5px] px-2.5 py-1.5 rounded-lg border ${
                    variante === v.id
                      ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                      : "bg-white border-[#E1DFD6] text-[#6B7E82]"
                  }`}
                >
                  {v.label}
                </button>
              ))}
            </div>

            {spec && (
              <div className="bg-white border border-[#E1DFD6] rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "Georgia, serif" }}>
                  {TECNICHE.find((t) => t.id === tecnica)?.label} —{" "}
                  {TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label}
                </h3>
                <p className="text-[11px] text-[#6B7E82] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-[#E1DFD6]">
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Madre</div>
                    <div className="font-mono text-[12.5px]">{spec.madre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Finale</div>
                    <div className="font-mono text-[12.5px]">{spec.finale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Galleggiante</div>
                    <div className="font-mono text-[12.5px]">{spec.galleggiante}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{spec.amo}</div>
                  </div>
                  <div className="col-span-2">
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Piombatura</div>
                    <div className="text-[12.5px] leading-relaxed">{spec.piombatura}</div>
                  </div>
                </div>
                <p className="text-[12px] text-[#6B7E82] italic mt-3 leading-relaxed">{spec.nota}</p>
                <p className="text-[10.5px] text-[#D98E4A] mt-3 pt-2.5 border-t border-[#E1DFD6]">
                  ✎ Disegno in esclusiva per i possessori de Il senso dell&apos;acqua
                </p>
              </div>
            )}
          </div>
        )}

        {/* ===== DA ENRICO — FEEDER ===== */}
        {subtab === "enrico" && category === "feeder" && (
          <div className="space-y-3">
            {OFFICIAL_ASSETTI.map((a, i) => (
              <div key={i} className="bg-white border border-[#E1DFD6] rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "Georgia, serif" }}>
                  {a.title}
                </h3>
                <p className="text-[11px] text-[#6B7E82] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-[#E1DFD6]">
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Pasturatore</div>
                    <div className="font-mono text-[12.5px]">{a.pasturatore}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Terminale</div>
                    <div className="font-mono text-[12.5px]">{a.terminale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Lenza madre</div>
                    <div className="font-mono text-[12.5px]">{a.lenzaMadre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{a.amo}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Esche</div>
                    <div className="font-mono text-[12.5px]">{a.esche}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#6B7E82] tracking-wide">Pastura</div>
                    <div className="font-mono text-[12.5px]">{a.pastura}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ===== LE MIE (personali, sia mare che feeder) ===== */}
        {subtab === "mie" && (
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-xs text-[#6B7E82]">{mine.length} salvate</span>
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
                    placeholder={
                      category === "mare" ? "es. La mia bolognese da canale" : "es. Il mio assetto da corrente"
                    }
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                  />
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  {personalFields.map((f) => (
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
                  {saving ? "Salvataggio…" : "Salva"}
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
          </>
        )}
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/lenze/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import LenzeClient from "./LenzeClient";

export default async function LenzePage() {
  const cookieStore = await cookies();
  const unlockedMare = cookieStore.get("unlock_mare-e-foce")?.value === "1";
  const unlockedFeeder = cookieStore.get("unlock_feeder")?.value === "1";

  return <LenzeClient unlockedMare={unlockedMare} unlockedFeeder={unlockedFeeder} />;
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
            <p className="text-xs text-[#6B7E82]">Con Mare e Foce o Diario Feeder</p>
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
echo "Fatto: Le mie lenze ora richiede lo sblocco del diario giusto (Mare e Foce o Feeder)."