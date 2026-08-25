export type SpecieCategory = "mare" | "dolce";
export type Rating = 1 | 2 | 3; // 1 = non buono, 2 = buono, 3 = ottimo

export interface Specie {
  name: string;
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
    category: "mare",
    months: [2, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Sarago",
    category: "mare",
    months: [1, 1, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3],
    note: "Esche bigattino, gambero, sarda, alici.",
  },
  {
    name: "Orata",
    category: "mare",
    months: [1, 1, 2, 2, 3, 3, 3, 2, 3, 3, 1, 1],
    note: "Esche bigattino, gambero, sarda, alici, anellidi vari e molluschi.",
  },
  {
    name: "Cefalo",
    category: "mare",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, gambero, sarda, alici, pane.",
  },
  {
    name: "Cavedano",
    category: "dolce",
    months: [1, 1, 3, 3, 3, 2, 2, 2, 3, 3, 2, 2],
    note: "Esche bigattino, verme, mais, mora.",
  },
  {
    name: "Carpa",
    category: "dolce",
    months: [2, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Carassio",
    category: "dolce",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1],
    note: "Esche bigattino, mais, verme.",
  },
  {
    name: "Breme",
    category: "dolce",
    months: [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 2],
    note: "Esche bigattino, verme, mais.",
  },
];

export function getSpecieByCategory(category: SpecieCategory): Specie[] {
  return SPECIE.filter((s) => s.category === category);
}

