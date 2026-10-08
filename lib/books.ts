// Configurazione centrale: un libro = un codice di sblocco (dal QR stampato nella prima pagina)
// Il codice va cambiato ad ogni ristampa (rotazione) per limitare la condivisione.
//
// maxActivations: limite di dispositivi totali che possono attivare lo stesso codice.
// Valore alto di proposito: serve solo come rete di sicurezza contro un codice che
// finisse condiviso su larga scala, MAI per bloccare acquirenti veri. Configurabile
// da Vercel (variabile MAX_ACTIVATIONS) senza dover rifare un deploy per cambiarlo.

export type BookId = "feeder" | "mare-e-foce" | "senso-acqua";

export interface Book {
  id: BookId;
  name: string;
  unlockCode: string; // in produzione: da variabile d'ambiente, non hardcoded
  maxActivations: number; // limite dispositivi per codice
}

const DEFAULT_MAX_ACTIVATIONS = 500;
const MAX_ACTIVATIONS = process.env.MAX_ACTIVATIONS
  ? Number(process.env.MAX_ACTIVATIONS)
  : DEFAULT_MAX_ACTIVATIONS;

export const BOOKS: Record<BookId, Book> = {
  feeder: {
    id: "feeder",
    name: "Diario Feeder",
    unlockCode: process.env.UNLOCK_CODE_FEEDER || "FEEDER-2026-DEMO",
    maxActivations: MAX_ACTIVATIONS,
  },
  "mare-e-foce": {
    id: "mare-e-foce",
    name: "Mare e Foce",
    unlockCode: process.env.UNLOCK_CODE_MAREFOCE || "MAREFOCE-2026-DEMO",
    maxActivations: MAX_ACTIVATIONS,
  },
  "senso-acqua": {
    id: "senso-acqua",
    name: "Pesca a bolognese e all'inglese",
    unlockCode: process.env.UNLOCK_CODE_SENSOACQUA || "SENSOACQUA-2026-DEMO",
    maxActivations: MAX_ACTIVATIONS,
  },
};

export function findBookByCode(code: string): Book | undefined {
  return Object.values(BOOKS).find(
    (b) => b.unlockCode.toLowerCase() === code.trim().toLowerCase()
  );
}
