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

export interface CatchTableSection {
  title: string;
  type: "table";
  columns: { key: string; label: string }[];
}

export interface CatchBoxesSection {
  title: string;
  type: "boxes";
  boxes: { key: string; label: string }[];
  extraField?: DiarioField; // es. "Altro"
}

export type DiarioTemplate = (DiarioSection | CatchTableSection | CatchBoxesSection)[];

// Struttura 1:1 con le pagine dei PDF caricati da Enrico
export const DIARIO_TEMPLATES: Record<Extract<BookId, "feeder" | "mare-e-foce">, DiarioTemplate> = {
  feeder: [
    {
      title: "Sessione",
      fields: [
        { key: "data", label: "Data", type: "date" },
        { key: "luogo", label: "Luogo", type: "text" },
        { key: "durata", label: "Durata", type: "text", placeholder: "es. 3h" },
      ],
    },
    {
      title: "Meteo e spot",
      fields: [
        { key: "meteo", label: "Meteo", type: "text", placeholder: "☀️ 🌤️ ☁️ 🌦️ ⛈️" },
        { key: "temperatura", label: "Temperatura", type: "text", placeholder: "°C" },
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
      title: "Catture",
      type: "table",
      columns: [
        { key: "specie", label: "Specie" },
        { key: "peso", label: "Peso" },
        { key: "lunghezza", label: "Lungh." },
        { key: "nr", label: "Nr" },
      ],
    },
    {
      title: "Analisi",
      fields: [
        { key: "cosa_ha_funzionato", label: "Cosa ha funzionato", type: "textarea" },
        { key: "cosa_migliorare", label: "Cosa migliorare", type: "textarea" },
      ],
    },
    {
      title: "Note",
      fields: [{ key: "note", label: "", type: "textarea" }],
    },
  ],

  "mare-e-foce": [
    {
      title: "Sessione di pesca",
      fields: [
        { key: "data", label: "Data", type: "date" },
        { key: "luogo", label: "Luogo", type: "text" },
        { key: "temperatura_aria", label: "Temperatura aria", type: "text", placeholder: "°C" },
        { key: "orario", label: "Orario", type: "time" },
        { key: "vento", label: "Vento", type: "text" },
        { key: "profondita", label: "Profondità", type: "text", placeholder: "mt" },
      ],
    },
    {
      title: "Note sessione",
      fields: [{ key: "note_sessione", label: "", type: "textarea" }],
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
    {
      title: "Catture",
      type: "boxes",
      boxes: [
        { key: "spigola", label: "🐟 Spigola" },
        { key: "orata", label: "🐟 Orata" },
        { key: "sarago", label: "🐟 Sarago" },
        { key: "cefalo", label: "🐟 Cefalo" },
      ],
      extraField: { key: "altro", label: "Altro", type: "textarea" },
    },
    {
      title: "Note",
      fields: [{ key: "note", label: "", type: "textarea" }],
    },
  ],
};

