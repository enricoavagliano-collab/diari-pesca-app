export type SpecieCategory = "mare" | "dolce";
export type Rating = 1 | 2 | 3; // 1 = non buono, 2 = buono, 3 = ottimo

export interface Specie {
  name: string;
  scientificName: string;
  category: SpecieCategory;
  months: Rating[]; // 12 valori, Gennaio → Dicembre
  note: string;
}

export const MONTH_LABELS = [
  "Gen", "Feb", "Mar", "Apr", "Mag", "Giu",
  "Lug", "Ago", "Set", "Ott", "Nov", "Dic",
];

export const RATING_LABELS: Record<Rating, string> = {
  1: "Non buono",
  2: "Buono",
  3: "Ottimo",
};

export const SPECIE: Specie[] = [
  {
    name: "Spigola",
    scientificName: "Dicentrarchus labrax",
    category: "mare",
    months: [2, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Sarago",
    scientificName: "Diplodus sargus",
    category: "mare",
    months: [1, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Orata",
    scientificName: "Sparus aurata",
    category: "mare",
    months: [1, 1, 2, 2, 3, 3, 3, 2, 3, 3, 1, 1],
    note: "Esche bigattino, gambero, sarda, alici, anellidi vari e molluschi.",
  },
  {
    name: "Cefalo",
    scientificName: "Mugil cephalus",
    category: "mare",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, gambero, sarda, alici, pane.",
  },
  {
    name: "Cavedano",
    scientificName: "Squalius cephalus",
    category: "dolce",
    months: [1, 1, 3, 3, 3, 2, 2, 2, 3, 3, 2, 2],
    note: "Esche bigattino, verme, mais, mora.",
  },
  {
    name: "Carpa",
    scientificName: "Cyprinus carpio",
    category: "dolce",
    months: [2, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Carassio",
    scientificName: "Carassius carassius",
    category: "dolce",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Breme",
    scientificName: "Abramis brama",
    category: "dolce",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 2],
    note: "Esche bigattino, verme, mais.",
  },
];

export function getSpecieByCategory(category: SpecieCategory): Specie[] {
  return SPECIE.filter((s) => s.category === category);
}

