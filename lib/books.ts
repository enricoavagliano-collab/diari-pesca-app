// Configurazione centrale: un libro = un codice di sblocco (dal QR stampato nella prima pagina)
// Il codice va cambiato ad ogni ristampa (rotazione) per limitare la condivisione.

export type BookId = "feeder" | "mare-e-foce" | "senso-acqua";

export interface Book {
  id: BookId;
  name: string;
  unlockCode: string; // in produzione: da variabile d'ambiente, non hardcoded
  maxActivations: number; // limite dispositivi per codice
}

export const BOOKS: Record<BookId, Book> = {
  feeder: {
    id: "feeder",
    name: "Diario Feeder",
    unlockCode: process.env.UNLOCK_CODE_FEEDER || "FEEDER-2026-DEMO",
    maxActivations: 3,
  },
  "mare-e-foce": {
    id: "mare-e-foce",
    name: "Mare e Foce",
    unlockCode: process.env.UNLOCK_CODE_MAREFOCE || "MAREFOCE-2026-DEMO",
    maxActivations: 3,
  },
  "senso-acqua": {
    id: "senso-acqua",
    name: "Il senso dell'acqua",
    unlockCode: process.env.UNLOCK_CODE_SENSOACQUA || "SENSOACQUA-2026-DEMO",
    maxActivations: 3,
  },
};

export function findBookByCode(code: string): Book | undefined {
  return Object.values(BOOKS).find(
    (b) => b.unlockCode.toLowerCase() === code.trim().toLowerCase()
  );
}

