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

