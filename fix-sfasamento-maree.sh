#!/bin/bash
set -e
echo 'Correggo lo sfasamento maree: array intero senza compattare i buchi...'
cat > "lib/tides.ts" << 'SETUP_EOF_MARKER'
export interface TideExtreme {
  time: string; // HH:mm locale
  type: "alta" | "bassa";
  height: number; // metri, relativo al livello medio del mare (non è un datum di navigazione)
  stimato: boolean; // true se calcolato dal ritmo di marea, non rilevato direttamente dal modello
}

export interface TideForecast {
  today: TideExtreme[];
  hourlySeries: { time: string; height: number }[]; // per disegnare il grafico
  timezone: string;
}

// Periodo semidiurno medio della marea M2: un ciclo alta→alta dura ~12h 25min,
// quindi alta→bassa (o viceversa) ~6h 12,5min = 372,5 minuti.
// Lavoriamo per "passi dell'array orario" (1 passo = 1 ora reale, garantito perché non
// compattiamo mai l'array togliendo i buchi) — così il ritmo resta accurato indipendentemente
// da dati mancanti o dal cambio ora legale/solare, entrambi già gestiti da Open-Meteo nelle
// etichette che riceviamo.
const HALF_PERIOD_HOURS = (6 * 60 + 12.5) / 60;

function extractHM(isoLike: string): string {
  const match = isoLike.match(/T(\d{2}:\d{2})/);
  return match ? match[1] : isoLike;
}

function extractDate(isoLike: string): string {
  return isoLike.split("T")[0];
}

export async function getTideForecast(
  lat: number,
  lon: number,
  targetDate: string // YYYY-MM-DD, nel timezone locale della località
): Promise<TideForecast | null> {
  const url = new URL("https://marine-api.open-meteo.com/v1/marine");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set("hourly", "sea_level_height_msl");
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", "7");
  url.searchParams.set("past_days", "2");

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  const times: string[] = data?.hourly?.time || [];
  const heights: (number | null)[] = data?.hourly?.sea_level_height_msl || [];
  const timezone: string = data?.timezone || "UTC";

  if (times.length === 0 || heights.every((h) => h === null)) return null;

  // IMPORTANTE: non filtriamo i null qui. Teniamo l'array intero, indice per indice,
  // così ogni passo di indice corrisponde sempre esattamente a un'ora reale — anche se
  // qualche ora nel mezzo non ha un valore valido.
  const n = times.length;

  // 1) Cerca i picchi VERI, saltando qualunque tripletta che tocchi un buco
  const detectedIndexes: number[] = [];
  const detectedType: Record<number, "alta" | "bassa"> = {};
  for (let i = 1; i < n - 1; i++) {
    const prev = heights[i - 1];
    const curr = heights[i];
    const next = heights[i + 1];
    if (prev === null || curr === null || next === null) continue;
    if (curr > prev && curr > next) {
      detectedIndexes.push(i);
      detectedType[i] = "alta";
    } else if (curr < prev && curr < next) {
      detectedIndexes.push(i);
      detectedType[i] = "bassa";
    }
  }

  const hourlySeries = times
    .map((t, i) => ({ time: t, height: heights[i] }))
    .filter((p): p is { time: string; height: number } => p.height !== null && extractDate(p.time) === targetDate)
    .map((p) => ({ time: extractHM(p.time), height: p.height }));

  if (detectedIndexes.length === 0) {
    return { today: [], hourlySeries, timezone };
  }

  // 2) Scegli come "ancora" il picco rilevato il cui giorno è più vicino al giorno target
  function dayDistance(idx: number): number {
    const d = new Date(extractDate(times[idx]));
    const t = new Date(targetDate);
    return Math.abs(d.getTime() - t.getTime());
  }
  const anchorIdx = detectedIndexes.reduce((best, i) =>
    dayDistance(i) < dayDistance(best) ? i : best
  );
  const anchorType = detectedType[anchorIdx];
  const anchorHeight = heights[anchorIdx] as number;

  const altHeights = detectedIndexes.filter((i) => detectedType[i] === "alta").map((i) => heights[i] as number);
  const bassHeights = detectedIndexes.filter((i) => detectedType[i] === "bassa").map((i) => heights[i] as number);
  const avgAlta = altHeights.length ? altHeights.reduce((a, b) => a + b, 0) / altHeights.length : Math.abs(anchorHeight);
  const avgBassa = bassHeights.length ? bassHeights.reduce((a, b) => a + b, 0) / bassHeights.length : -Math.abs(anchorHeight);

  // 3) Genera la sequenza periodica alternata a partire dall'ancora, muovendosi per "passi orari"
  //    dell'array intero (1 passo = 1 ora reale garantita)
  const detectedSet = new Set(detectedIndexes);
  const results: TideExtreme[] = [];
  const maxSteps = Math.ceil(n / HALF_PERIOD_HOURS) + 2;

  for (let k = -maxSteps; k <= maxSteps; k++) {
    const rawIdx = anchorIdx + k * HALF_PERIOD_HOURS;
    const roundedIdx = Math.round(rawIdx);
    if (roundedIdx < 0 || roundedIdx >= n) continue;

    const label = times[roundedIdx];
    if (extractDate(label) !== targetDate) continue;

    const isSameTypeAsAnchor = ((k % 2) + 2) % 2 === 0;
    const type: "alta" | "bassa" = isSameTypeAsAnchor
      ? anchorType
      : anchorType === "alta"
      ? "bassa"
      : "alta";

    const isRealDetected = detectedSet.has(roundedIdx) && detectedType[roundedIdx] === type;
    const realHeight = heights[roundedIdx];

    results.push({
      time: extractHM(label),
      type,
      height:
        Math.round(
          (isRealDetected && realHeight !== null ? realHeight : type === "alta" ? avgAlta : avgBassa) * 100
        ) / 100,
      stimato: !isRealDetected,
    });
  }

  const deduped: TideExtreme[] = [];
  for (const r of results.sort((a, b) => a.time.localeCompare(b.time))) {
    const last = deduped[deduped.length - 1];
    if (!last || last.time !== r.time) deduped.push(r);
  }

  return { today: deduped, hourlySeries, timezone };
}

SETUP_EOF_MARKER
echo "Fatto: gli orari di marea non si sfasano piu con la distanza dal dato reale rilevato."