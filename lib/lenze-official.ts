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

