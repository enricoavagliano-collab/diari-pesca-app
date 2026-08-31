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

