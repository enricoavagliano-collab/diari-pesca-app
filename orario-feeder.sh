#!/bin/bash
set -e

echo "=== Aggiungo Orario inizio/fine anche al diario Feeder ==="

cat > lib/diario-templates.ts << 'TEMPLATESEOF'
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
        { key: "orario_inizio", label: "Orario inizio", type: "time" },
        { key: "orario_fine", label: "Orario fine", type: "time" },
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
        { key: "canna", label: "Canna (mt)", type: "text" },
        { key: "mulinello", label: "Mulinello", type: "text" },
        { key: "amo", label: "Amo (nr)", type: "text" },
        { key: "galleggiante", label: "Galleggiante (gr)", type: "text" },
        { key: "filo_madre", label: "Filo madre (mm)", type: "text" },
        { key: "terminale", label: "Terminale (mm)", type: "text" },
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

echo "=== File aggiornato: lib/diario-templates.ts ==="
echo ""
echo "Aggiunto 'Orario inizio' e 'Orario fine' nella sezione Sessione del"
echo "diario Feeder, subito dopo Luogo - stessa posizione gia' usata in"
echo "Mare/Foce. Il campo 'Durata' resta invariato, e' un dato diverso."
echo ""
echo "Ricorda: bash orario-feeder.sh, poi:"
echo "git add -A && git commit -m 'aggiunge orario inizio-fine al diario feeder' && git push"
