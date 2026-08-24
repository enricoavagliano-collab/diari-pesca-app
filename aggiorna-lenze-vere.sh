#!/bin/bash
set -e
echo 'Aggiorno la sezione Le mie lenze con le 17 configurazioni vere...'
mkdir -p "app/lenze"
mkdir -p "lib"
cat > "lib/lenze-official.ts" << 'SETUP_EOF_MARKER'
export type LenzaCategory = "mare" | "feeder";

export type Tecnica = "trattenuta" | "passata" | "inglese" | "scogliera";

export const TECNICHE: { id: Tecnica; label: string }[] = [
  { id: "trattenuta", label: "Trattenuta" },
  { id: "passata", label: "Passata" },
  { id: "inglese", label: "Inglese" },
  { id: "scogliera", label: "Pesca scogliera" },
];

// Ogni tecnica ha un proprio set di "varianti" (la seconda dimensione di scelta)
export const TECNICA_VARIANTI: Record<Tecnica, { id: string; label: string }[]> = {
  trattenuta: [
    { id: "bigattino-lenta", label: "Bigattino · Corrente lenta" },
    { id: "bigattino-media", label: "Bigattino · Corrente media" },
    { id: "bigattino-forte", label: "Bigattino · Corrente forte" },
    { id: "alternative-lenta", label: "Esche alternative · Corrente lenta" },
    { id: "alternative-media", label: "Esche alternative · Corrente media" },
    { id: "alternative-forte", label: "Esche alternative · Corrente forte" },
  ],
  passata: [
    { id: "bigattino-lenta", label: "Bigattino · Corrente lenta" },
    { id: "bigattino-media", label: "Bigattino · Corrente media" },
    { id: "bigattino-forte", label: "Bigattino · Corrente forte" },
    { id: "alternative-lenta", label: "Esche alternative · Corrente lenta" },
    { id: "alternative-media", label: "Esche alternative · Corrente media" },
    { id: "alternative-forte", label: "Esche alternative · Corrente forte" },
  ],
  inglese: [
    { id: "bigattino", label: "Bigattino" },
    { id: "alternative", label: "Esche alternative" },
  ],
  scogliera: [
    { id: "calmo", label: "Mare calmo" },
    { id: "mosso", label: "Mare mosso" },
  ],
};

export interface LenzaSpec {
  madre: string;
  finale: string;
  galleggiante: string;
  piombatura: string;
  amo: string;
  nota: string;
}

// Chiave: `${tecnica}:${variante}`
export const OFFICIAL_LENZE: Record<string, LenzaSpec> = {
  "trattenuta:bigattino-lenta": {
    madre: "0.14",
    finale: "0.10/0.12",
    galleggiante: "0.50/1gr intercambiabile",
    piombatura: "In base alla profondità dello spot, dal metro ai 2mt — 6 pallini dell'11, 6 del 10, 6 del 9, fino a taratura",
    amo: "20/22",
    nota: "Lenza idonea per corrente lenta con poco appoggio. In caso di corrente sul fondo che torna indietro, accorciare il terminale.",
  },
  "trattenuta:bigattino-media": {
    madre: "0.14",
    finale: "0.10/0.12",
    galleggiante: "1/3gr",
    piombatura: "In base alla profondità dello spot, dal metro a 1,5mt — 6 pallini del 10, 6 del 9, 6 dell'8, fino a taratura",
    amo: "18/20",
    nota: "Appoggio di tutto il terminale ed oltre. In caso di corrente sul fondo, allungare il terminale.",
  },
  "trattenuta:bigattino-forte": {
    madre: "0.14",
    finale: "0.10/0.12",
    galleggiante: "1/5gr",
    piombatura: "In base alla profondità dello spot, a 1mt — 7 pallini del 9, 7 dell'8, 7 del 7, fino a taratura",
    amo: "16/18",
    nota: "Appoggio di tutto il terminale ed oltre. In caso di corrente sul fondo, allungare il terminale.",
  },
  "trattenuta:alternative-lenta": {
    madre: "0.18",
    finale: "0.14/0.16",
    galleggiante: "1/3gr",
    piombatura: "In base alla profondità dello spot, a 1mt — 10 pallini dell'8, fino a taratura",
    amo: "4/10",
    nota: "Gambero, sarda o alici.",
  },
  "trattenuta:alternative-media": {
    madre: "0.18",
    finale: "0.14/0.16",
    galleggiante: "1/3gr",
    piombatura: "In base alla profondità dello spot, a 1mt — 10 pallini del 7, fino a taratura",
    amo: "4/10",
    nota: "Gambero, sarda o alici, sondata all'ultimo pallino.",
  },
  "trattenuta:alternative-forte": {
    madre: "0.18",
    finale: "0.16",
    galleggiante: "3/6gr",
    piombatura: "In base alla profondità dello spot, a 0.70cm — 10 pallini del 6, fino a taratura",
    amo: "4/10",
    nota: "Gambero, sarda o alici, sondata all'ultimo pallino e oltre.",
  },
  "passata:bigattino-lenta": {
    madre: "0.14",
    finale: "0.10/0.12",
    galleggiante: "0.50/1gr",
    piombatura: "In base alla profondità dello spot, a 0.70cm — 2 pallini del 12, 2 dell'11, 6 del 10, tarare con pallini del 9",
    amo: "20/22",
    nota: "Pesca in passata per correnti lente, esca bigattino, pasturazione poca ma continua.",
  },
  "passata:bigattino-media": {
    madre: "0.14",
    finale: "0.10/0.12",
    galleggiante: "1/3gr",
    piombatura: "In base alla profondità dello spot, a 0.70cm — 2 pallini dell'11, 2 del 10, 6 del 9, tarare con pallini dell'8",
    amo: "18/20",
    nota: "Pesca in passata per correnti medie, esca bigattino, pasturazione con più larve per creare una buona scia.",
  },
  "passata:bigattino-forte": {
    madre: "0.14",
    finale: "0.12/0.14",
    galleggiante: "2/5gr",
    piombatura: "In base alla profondità dello spot, a 0.70cm — torpilla, 10 pallini del 9 equidistanti",
    amo: "16/18",
    nota: "Pesca in passata per correnti forti, esca bigattino, pasturazione copiosa, da non sottovalutare l'incollato.",
  },
  "passata:alternative-lenta": {
    madre: "0.18",
    finale: "0.14/0.16",
    galleggiante: "1/3gr",
    piombatura: "In base alla profondità dello spot, a 0.70cm — 10 pallini del 9 equidistanti",
    amo: "4/10",
    nota: "Esche coreano e gambero.",
  },
  "passata:alternative-media": {
    madre: "0.20",
    finale: "0.16",
    galleggiante: "3/5gr",
    piombatura: "In base alla profondità dello spot, a 0.70cm — torpilla, 10 pallini dell'8 equidistanti",
    amo: "4/10",
    nota: "Esche coreano e gambero.",
  },
  "passata:alternative-forte": {
    madre: "0.25",
    finale: "diretto",
    galleggiante: "4/8gr",
    piombatura: "In base alla profondità dello spot, a 0.70cm — torpilla, 10 pallini del 7 equidistanti",
    amo: "4/10",
    nota: "Esche coreano e gambero.",
  },
  "inglese:bigattino": {
    madre: "0.14/0.16",
    finale: "0.10/0.12",
    galleggiante: "3/8gr",
    piombatura: "Bulk di pallini in battuta, lenza in base allo spot — 10 pallini del 10, aperti dal metro ai 2 metri",
    amo: "18/20",
    nota: "Condizioni di mare calmo, sia dalla spiaggia che scogliera e porto.",
  },
  "inglese:alternative": {
    madre: "0.18",
    finale: "0.14/0.16",
    galleggiante: "3/8gr",
    piombatura: "Bulk a sbattere, lenza molto aperta con un pallino del 9 sulla girella e un altro a un metro di distanza",
    amo: "12/10",
    nota: "Esca gambero, ideale per scogliera e porto.",
  },
  "scogliera:calmo": {
    madre: "0.14",
    finale: "0.12",
    galleggiante: "1/3gr",
    piombatura: "Lunghezza in base allo spot, dai 0.60cm al metro — 5 pallini del 10, 5 del 9, 5 dell'8",
    amo: "16/18",
    nota: "Esche bigattino e gambero, stringere la lenza in base alla profondità.",
  },
  "scogliera:mosso": {
    madre: "0.18",
    finale: "0.14/0.16",
    galleggiante: "3/6gr",
    piombatura: "Lunghezza in base allo spot, dai 0.60cm al metro — 5 pallini del 9, 5 dell'8, 5 del 7",
    amo: "14/16",
    nota: "Esche bigattino e gambero, stringere la lenza in base alla profondità.",
  },
};

export function getOfficialLenza(tecnica: Tecnica, varianteId: string): LenzaSpec | undefined {
  return OFFICIAL_LENZE[`${tecnica}:${varianteId}`];
}

// --- FEEDER (chiamato "Assetto", campi diversi dalla bolognese) ---
export interface AssettoSpec {
  title: string;
  pasturatore: string;
  terminale: string;
  lenzaMadre: string;
  amo: string;
  esche: string;
  pastura: string;
}

export const OFFICIAL_ASSETTI: AssettoSpec[] = [
  {
    title: "Assetto base",
    pasturatore: "Cage feeder",
    terminale: "0.14/0.16",
    lenzaMadre: "0.20",
    amo: "12/18",
    esche: "Bigattino",
    pastura: "Formaggio",
  },
];

// Campi del form per le lenze personali dell'utente (semplificato rispetto alla libreria ufficiale)
export const LENZA_FIELDS_MARE = [
  { key: "madre", label: "Madre" },
  { key: "finale", label: "Finale" },
  { key: "galleggiante", label: "Galleggiante" },
  { key: "piombatura", label: "Piombatura" },
  { key: "amo", label: "Amo" },
];

export const ASSETTO_FIELDS_FEEDER = [
  { key: "pasturatore", label: "Tipo di pasturatore" },
  { key: "terminale", label: "Tipo di terminale" },
  { key: "lenzaMadre", label: "Lenza madre" },
  { key: "amo", label: "Amo" },
  { key: "esche", label: "Esche" },
  { key: "pastura", label: "Pastura" },
];

SETUP_EOF_MARKER
cat > "app/lenze/page.tsx" << 'SETUP_EOF_MARKER'
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

export default function LenzePage() {
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
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
echo "Fatto: 16 lenze Mare/Foce + 1 Assetto Feeder ora presenti nell app, con la navigazione a tecnica/variante."