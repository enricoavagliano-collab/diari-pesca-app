#!/bin/bash
set -e

echo "=== Galleggianti Bolognese + tendine in Le mie lenze ==="

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
export const DIAMETRI_MM = ["0.08", "0.10", "0.12", "0.14", "0.16", "0.18", "0.20", "0.22", "0.25", "0.28", "0.30"];
export const AMI_NR = ["24", "22", "20", "18", "16", "14", "12", "10", "8", "6", "4"];

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
            Bolognese: [
              "0.5 gr", "0.75 gr", "1 gr", "1.5 gr", "2 gr", "2.5 gr",
              "3 gr", "4 gr", "5 gr", "6 gr", "8 gr", "10 gr",
            ],
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

cat > lib/lenze-official.ts << 'LENZEOFFICIALEOF'
import { DIAMETRI_MM, AMI_NR } from "./diario-templates";

export type LenzaCategory = "mare" | "feeder";

export type Tecnica = "trattenuta" | "passata" | "inglese" | "scogliera";

export const TECNICHE: { id: Tecnica; label: string }[] = [
  { id: "trattenuta", label: "Trattenuta" },
  { id: "passata", label: "Passata" },
  { id: "inglese", label: "Porto / Inglese" },
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
    { id: "bigattino", label: "Inglese · Bigattino" },
    { id: "alternative", label: "Inglese · Esche alternative" },
    { id: "bolognese-bigattino", label: "Bolognese · Bigattino" },
    { id: "bolognese-alternative", label: "Bolognese · Esche alternative" },
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
  "inglese:bolognese-bigattino": {
    madre: "0.14",
    finale: "0.12/0.12",
    galleggiante: "0.50/2gr",
    piombatura: "Lenza aperta — 5 pallini dell'11, 5 del 10, 5 del 9, fino a taratura",
    amo: "18/20",
    nota: "Esca bigattino, aumentare il peso in base alla corrente.",
  },
  "inglese:bolognese-alternative": {
    madre: "0.20",
    finale: "0.14/0.18",
    galleggiante: "3/5gr",
    piombatura: "10 pallini dell'8 sul metro di lunghezza, applicare torpilla in base alla profondità",
    amo: "10/4",
    nota: "Lenza ideale per pescare nei porti con esche come gambero, sarda e alici.",
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
// Galleggianti: unione delle misure Bolognese + Inglese usate nel diario,
// dato che qui non c'e' un campo "Tecnica" a monte che le distingua.
const GALLEGGIANTI_GR = [
  "0.5 gr", "0.75 gr", "1 gr", "1.5 gr", "2 gr", "2.5 gr", "3 gr", "4 gr",
  "5 gr", "6 gr", "7 gr", "8 gr", "10 gr", "12 gr",
  "2+1 gr", "3+1 gr", "4+1 gr",
];

const PASTURATORI = ["Cage", "Block End", "Method", "Pellet feeder", "In-line"];

export const LENZA_FIELDS_MARE = [
  { key: "madre", label: "Madre (mm)", type: "select" as const, options: DIAMETRI_MM },
  { key: "finale", label: "Finale (mm)", type: "select" as const, options: DIAMETRI_MM },
  { key: "galleggiante", label: "Galleggiante (gr)", type: "select" as const, options: GALLEGGIANTI_GR },
  { key: "piombatura", label: "Piombatura", type: "text" as const },
  { key: "amo", label: "Amo (nr)", type: "select" as const, options: AMI_NR },
  { key: "nota", label: "Note", type: "text" as const },
];

export const ASSETTO_FIELDS_FEEDER = [
  { key: "pasturatore", label: "Tipo di pasturatore", type: "select" as const, options: PASTURATORI },
  { key: "terminale", label: "Terminale (mm)", type: "select" as const, options: DIAMETRI_MM },
  { key: "lenzaMadre", label: "Lenza madre (mm)", type: "select" as const, options: DIAMETRI_MM },
  { key: "amo", label: "Amo (nr)", type: "select" as const, options: AMI_NR },
  { key: "esche", label: "Esche", type: "text" as const },
  { key: "pastura", label: "Pastura", type: "text" as const },
  { key: "nota", label: "Note", type: "text" as const },
];

LENZEOFFICIALEOF

cat > app/lenze/LenzeClient.tsx << 'LENZECLIENTEOF'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Waves, Link2, CircleDot, Weight, Fish as FishIcon, Plus, Package, Wheat } from "lucide-react";
import {
  LenzaCategory,
  Tecnica,
  TECNICHE,
  TECNICA_VARIANTI,
  getOfficialLenza,
  OFFICIAL_ASSETTI,
  LENZA_FIELDS_MARE,
  ASSETTO_FIELDS_FEEDER,
  LenzaSpec,
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

function fieldIcon(key: string) {
  const map: Record<string, typeof Waves> = {
    madre: Waves,
    lenzaMadre: Waves,
    finale: Link2,
    terminale: Link2,
    galleggiante: CircleDot,
    piombatura: Weight,
    amo: FishIcon,
    pasturatore: Package,
    esche: Wheat,
    pastura: Wheat,
  };
  return map[key] || CircleDot;
}

export default function LenzeClient({
  unlockedMare,
  unlockedFeeder,
  unlockedSensoAcqua,
}: {
  unlockedMare: boolean;
  unlockedFeeder: boolean;
  unlockedSensoAcqua: boolean;
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

  function copyToMine(spec: LenzaSpec) {
    setValues({
      madre: spec.madre,
      finale: spec.finale,
      galleggiante: spec.galleggiante,
      piombatura: spec.piombatura,
      amo: spec.amo,
    });
    setTitle(
      `${TECNICHE.find((t) => t.id === tecnica)?.label} — ${
        TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label
      } (copia)`
    );
    setSubtab("mie");
    setFormOpen(true);
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
  const categoryUnlocked = category === "mare" ? unlockedMare || unlockedSensoAcqua : unlockedFeeder;

  return (
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Le mie lenze
        </h1>

        {/* Categoria principale */}
        <div className="flex gap-1.5 mb-3">
          <button
            onClick={() => setCategory("mare")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "mare"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🌊 Mare / Foce {!(unlockedMare || unlockedSensoAcqua) && "🔒"}
          </button>
          <button
            onClick={() => setCategory("feeder")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "feeder"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🎣 Feeder {!unlockedFeeder && "🔒"}
          </button>
        </div>

        {!categoryUnlocked ? (
          <div className="bg-[#124E5A] border border-white/10 rounded-xl p-6 text-center mt-4">
            <div className="text-3xl mb-3">🔒</div>
            <h2 className="font-medium text-[15px] mb-1.5">
              {category === "mare" ? "Sblocca con Mare e Foce o Il senso dell'acqua (a breve online)" : "Sblocca con Diario Feeder"}
            </h2>
            <p className="text-sm text-[#8FA8B2] leading-relaxed">
              Questa sezione fa parte dei contenuti del diario{" "}
              {category === "mare" ? "Mare e Foce (o de Il senso dell'acqua, a breve online)" : "Feeder"} — inquadra il QR nella prima
              pagina della tua copia per sbloccarla.
            </p>
          </div>
        ) : (
          <>
            {/* Sotto-schede */}
        <div className="flex gap-1 mb-4 bg-[#0B1F2A] rounded-xl p-1">
          <button
            onClick={() => setSubtab("enrico")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "enrico" ? "bg-[#124E5A] text-[#F6F5F1]" : "text-[#8FA8B2]"
            }`}
          >
            Da Enrico
          </button>
          <button
            onClick={() => setSubtab("mie")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "mie" ? "bg-[#124E5A] text-[#F6F5F1]" : "text-[#8FA8B2]"
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
                      ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                      : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
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
                      ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                      : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
                  }`}
                >
                  {v.label}
                </button>
              ))}
            </div>

            {spec && (
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {TECNICHE.find((t) => t.id === tecnica)?.label} —{" "}
                  {TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label}
                </h3>
                <p className="text-[11px] text-[#8FA8B2] mb-3">di Enrico Avagliano</p>

                <div className="space-y-2.5 pt-2.5 border-t border-white/10">
                  {[
                    { Icon: Waves, label: "Madre", value: spec.madre },
                    { Icon: Link2, label: "Finale", value: spec.finale },
                    { Icon: CircleDot, label: "Galleggiante", value: spec.galleggiante },
                    { Icon: FishIcon, label: "Amo", value: spec.amo },
                  ].map(({ Icon, label, value }) => (
                    <div key={label} className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                        <Icon size={15} strokeWidth={1.75} className="text-[#2CA6A4]" />
                      </div>
                      <span className="text-[12.5px] flex-1">{label}</span>
                      <span className="font-mono text-[12.5px] text-[#F6F5F1]">{value}</span>
                    </div>
                  ))}
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                      <Weight size={15} strokeWidth={1.75} className="text-[#2CA6A4]" />
                    </div>
                    <div className="flex-1">
                      <span className="text-[12.5px]">Piombatura</span>
                      <p className="text-[11.5px] text-[#8FA8B2] leading-relaxed mt-0.5">{spec.piombatura}</p>
                    </div>
                  </div>
                </div>

                <p className="text-[12px] text-[#8FA8B2] italic mt-3 leading-relaxed">{spec.nota}</p>

                <button
                  onClick={() => copyToMine(spec)}
                  className="w-full flex items-center justify-center gap-1.5 border border-[#2CA6A4] text-[#2CA6A4] rounded-full py-2 text-[12.5px] font-medium mt-3"
                >
                  <Plus size={14} /> Aggiungi alle mie
                </button>

                {unlockedSensoAcqua ? (
                  <div className="mt-3 pt-3 border-t border-white/10">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-[10.5px] text-[#FF9A3C] font-medium">
                        ✎ Disegno esclusivo — Il senso dell&apos;acqua (a breve online)
                      </span>
                    </div>
                    <div className="bg-[#0B1F2A] border border-dashed border-white/10 rounded-lg h-32 flex items-center justify-center text-[11px] text-[#8FA8B2]">
                      📐 Disegno del montaggio — in arrivo
                    </div>
                  </div>
                ) : (
                  <div className="mt-3 pt-3 border-t border-white/10 flex items-center gap-2.5 bg-[#0B1F2A] rounded-lg p-2.5">
                    <span className="text-lg flex-shrink-0">🔒</span>
                    <p className="text-[11px] text-[#8FA8B2] leading-relaxed">
                      Disegno del montaggio disponibile solo per chi ha Il senso dell&apos;acqua (a breve online).
                    </p>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* ===== DA ENRICO — FEEDER ===== */}
        {subtab === "enrico" && category === "feeder" && (
          <div className="space-y-3">
            {OFFICIAL_ASSETTI.map((a, i) => (
              <div key={i} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {a.title}
                </h3>
                <p className="text-[11px] text-[#8FA8B2] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-white/10">
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Pasturatore</div>
                    <div className="font-mono text-[12.5px]">{a.pasturatore}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Terminale</div>
                    <div className="font-mono text-[12.5px]">{a.terminale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Lenza madre</div>
                    <div className="font-mono text-[12.5px]">{a.lenzaMadre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{a.amo}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Esche</div>
                    <div className="font-mono text-[12.5px]">{a.esche}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Pastura</div>
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
              <span className="text-xs text-[#8FA8B2]">{mine.length} salvate</span>
              <button
                onClick={() => setFormOpen((o) => !o)}
                className="w-8 h-8 rounded-full bg-[#2CA6A4] text-white text-lg flex items-center justify-center"
              >
                {formOpen ? "×" : "+"}
              </button>
            </div>

            {formOpen && (
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4 space-y-3">
                <div>
                  <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">Nome</label>
                  <input
                    className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                    placeholder={
                      category === "mare" ? "es. La mia bolognese da canale" : "es. Il mio assetto da corrente"
                    }
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                  />
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  {personalFields
                    .filter((f) => f.key !== "nota")
                    .map((f) => (
                      <div key={f.key}>
                        <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">{f.label}</label>
                        {"type" in f && f.type === "select" ? (
                          <select
                            className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                            value={values[f.key] || ""}
                            onChange={(e) => setField(f.key, e.target.value)}
                          >
                            <option value="">—</option>
                            {("options" in f ? f.options : []).map((opt) => (
                              <option key={opt} value={opt}>
                                {opt}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <input
                            className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                            value={values[f.key] || ""}
                            onChange={(e) => setField(f.key, e.target.value)}
                          />
                        )}
                      </div>
                    ))}
                </div>
                {personalFields.some((f) => f.key === "nota") && (
                  <div>
                    <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">Note</label>
                    <textarea
                      className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A] min-h-[70px] resize-none"
                      placeholder="Osservazioni, varianti, condizioni in cui usarla…"
                      value={values["nota"] || ""}
                      onChange={(e) => setField("nota", e.target.value)}
                    />
                  </div>
                )}
                <button
                  onClick={save}
                  disabled={saving || !title.trim()}
                  className="w-full bg-[#2CA6A4] text-[#0B1F2A] rounded-xl py-2.5 text-sm font-medium disabled:opacity-50"
                >
                  {saving ? "Salvataggio…" : "Salva"}
                </button>
              </div>
            )}

            {mine.length === 0 && !formOpen && (
              <p className="text-sm text-[#8FA8B2]">Nessuna lenza salvata ancora — inizia dal +</p>
            )}

            {mine.map((entry) => (
              <div key={entry.id} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <div className="flex justify-between items-start mb-2.5 pb-2.5 border-b border-white/10">
                  <h3 className="font-medium text-[15px]" style={{ fontFamily: "var(--font-fraunces)" }}>
                    {entry.title}
                  </h3>
                  <button
                    onClick={() => remove(entry.id)}
                    className="text-xs text-[#8FA8B2] hover:text-red-400 flex-shrink-0"
                  >
                    elimina
                  </button>
                </div>
                <div className="space-y-2">
                  {personalFields
                    .filter((f) => f.key !== "nota" && entry.data[f.key])
                    .map((f) => {
                      const FieldIcon = fieldIcon(f.key);
                      return (
                        <div key={f.key} className="flex items-center gap-2.5">
                          <div className="w-7 h-7 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                            <FieldIcon size={13} strokeWidth={1.75} className="text-[#2CA6A4]" />
                          </div>
                          <span className="text-[12px] flex-1 text-[#8FA8B2]">{f.label}</span>
                          <span className="font-mono text-[12px]">{entry.data[f.key]}</span>
                        </div>
                      );
                    })}
                  {entry.data["nota"] && (
                    <p className="text-[12px] text-[#8FA8B2] italic leading-relaxed pt-1 border-t border-white/10 mt-2">
                      {entry.data["nota"]}
                    </p>
                  )}
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

LENZECLIENTEOF

echo "=== File aggiornati: ==="
echo "  lib/diario-templates.ts"
echo "  lib/lenze-official.ts"
echo "  app/lenze/LenzeClient.tsx"
echo ""
echo "Modifiche:"
echo "  1. Diario Mare/Foce, galleggianti Bolognese: aggiunte le misure"
echo "     0.75 - 1.5 - 2.5 gr nella posizione corretta della lista"
echo "  2. Sezione 'Le mie lenze' (sia Mare/Foce che Feeder), campi ora a tendina:"
echo "     - Mare/Foce: Madre, Finale, Galleggiante, Amo"
echo "     - Feeder: Tipo pasturatore, Terminale, Lenza madre, Amo"
echo "     Restano testo libero: Piombatura, Esche, Pastura, Note"
echo "     (troppo descrittivi/variabili per una tendina)"
echo ""
echo "Ricorda: bash galleggianti-e-tendine-lemie.sh, poi:"
echo "git add -A && git commit -m 'aggiunge misure galleggianti bolognese e tendine in Le mie lenze' && git push"
