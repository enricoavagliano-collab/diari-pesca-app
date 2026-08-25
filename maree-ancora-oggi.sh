#!/bin/bash
set -e
echo 'Riscrivo il calcolo maree: ancora su oggi + spostamento 50min/giorno...'
cat > "lib/tides.ts" << 'SETUP_EOF_MARKER'
export interface TideExtreme {
  time: string; // HH:mm locale
  type: "alta" | "bassa";
  height: number; // metri, relativo al livello medio del mare (non è un datum di navigazione)
  stimato: boolean; // true se non rilevato direttamente dal modello per questo giorno specifico
}

export interface TideForecast {
  today: TideExtreme[];
  hourlySeries: { time: string; height: number }[]; // per disegnare il grafico
  timezone: string;
}

// Periodo semidiurno medio della marea M2: un ciclo alta→alta dura ~12h 25min,
// quindi alta→bassa (o viceversa) ~6h 12,5min = 372,5 minuti.
const HALF_PERIOD_HOURS = (6 * 60 + 12.5) / 60;

// Ogni giorno solare (24h) è più corto del giorno lunare (24h 50,5min): per questo la marea
// "ritarda" di circa 50 minuti rispetto all'orologio, ogni giorno che passa.
const DAILY_DRIFT_MINUTES = 50.5;

function extractHM(isoLike: string): string {
  const match = isoLike.match(/T(\d{2}:\d{2})/);
  return match ? match[1] : isoLike;
}

function extractDate(isoLike: string): string {
  return isoLike.split("T")[0];
}

function shiftTime(hm: string, minutesToAdd: number): string {
  const [h, m] = hm.split(":").map(Number);
  let total = h * 60 + m + minutesToAdd;
  total = ((total % 1440) + 1440) % 1440; // avvolge tra 0 e 24h
  const hh = String(Math.floor(total / 60)).padStart(2, "0");
  const mm = String(Math.round(total % 60)).padStart(2, "0");
  return `${hh}:${mm}`;
}

/**
 * Calcola gli eventi di marea per "oggi" (il giorno reale nel fuso della località),
 * ancorando a un dato vero rilevato dal modello dove possibile. Per gli altri giorni
 * (targetDate diverso da oggi), NON richiediamo di nuovo il rilevamento al modello:
 * spostiamo semplicemente gli orari di oggi del ritardo naturale della marea
 * (~50 min per ogni giorno di differenza). Così il risultato è sempre coerente e
 * si muove in modo fluido, invece di "saltare" in modo imprevedibile giorno per giorno.
 */
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

  const n = times.length;
  const todayDate = times.find((t) => true) ? extractDate(times[Math.floor(n / 3)]) : targetDate;
  // "Oggi" reale nel fuso della località: lo calcoliamo dal server, non dal modello,
  // per essere sicuri che sia il giorno vero indipendentemente da dove parte l'array.
  const now = new Date();
  const localToday = new Intl.DateTimeFormat("sv-SE", { timeZone: timezone }).format(now); // YYYY-MM-DD

  // 1) Rileva i picchi VERI in tutta la finestra
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

  // 2) Ancora scelta il più vicino possibile a "oggi" (non al giorno che l'utente sta guardando)
  function dayDistance(idx: number): number {
    const d = new Date(extractDate(times[idx]));
    const t = new Date(localToday);
    return Math.abs(d.getTime() - t.getTime());
  }
  const anchorIdx = detectedIndexes.reduce((best, i) => (dayDistance(i) < dayDistance(best) ? i : best));
  const anchorType = detectedType[anchorIdx];

  const altHeights = detectedIndexes.filter((i) => detectedType[i] === "alta").map((i) => heights[i] as number);
  const bassHeights = detectedIndexes.filter((i) => detectedType[i] === "bassa").map((i) => heights[i] as number);
  const avgAlta = altHeights.length ? altHeights.reduce((a, b) => a + b, 0) / altHeights.length : Math.abs(heights[anchorIdx] as number);
  const avgBassa = bassHeights.length ? bassHeights.reduce((a, b) => a + b, 0) / bassHeights.length : -Math.abs(heights[anchorIdx] as number);

  // 3) Genera gli eventi di OGGI (solo oggi), ancorati al dato vero più vicino
  const detectedSet = new Set(detectedIndexes);
  const todayEvents: TideExtreme[] = [];
  const maxSteps = Math.ceil(n / HALF_PERIOD_HOURS) + 2;

  for (let k = -maxSteps; k <= maxSteps; k++) {
    const rawIdx = anchorIdx + k * HALF_PERIOD_HOURS;
    const roundedIdx = Math.round(rawIdx);
    if (roundedIdx < 0 || roundedIdx >= n) continue;

    const label = times[roundedIdx];
    if (extractDate(label) !== localToday) continue;

    const isSameTypeAsAnchor = ((k % 2) + 2) % 2 === 0;
    const type: "alta" | "bassa" = isSameTypeAsAnchor ? anchorType : anchorType === "alta" ? "bassa" : "alta";
    const isRealDetected = detectedSet.has(roundedIdx) && detectedType[roundedIdx] === type;
    const realHeight = heights[roundedIdx];

    todayEvents.push({
      time: extractHM(label),
      type,
      height: Math.round((isRealDetected && realHeight !== null ? realHeight : type === "alta" ? avgAlta : avgBassa) * 100) / 100,
      stimato: !isRealDetected,
    });
  }
  todayEvents.sort((a, b) => a.time.localeCompare(b.time));

  // 4) Se il giorno richiesto è "oggi", restituisci direttamente questi eventi.
  //    Altrimenti, sposta ogni orario di oggi del ritardo naturale della marea.
  const dayOffset = Math.round(
    (new Date(targetDate).getTime() - new Date(localToday).getTime()) / (1000 * 60 * 60 * 24)
  );

  let finalEvents: TideExtreme[];
  if (dayOffset === 0) {
    finalEvents = todayEvents;
  } else {
    finalEvents = todayEvents
      .map((e) => ({
        ...e,
        time: shiftTime(e.time, dayOffset * DAILY_DRIFT_MINUTES),
        stimato: true, // qualunque giorno diverso da oggi è per definizione uno spostamento stimato
      }))
      .sort((a, b) => a.time.localeCompare(b.time));
  }

  return { today: finalEvents, hourlySeries, timezone };
}

SETUP_EOF_MARKER
echo "Fatto: le maree ora si spostano di ~50 minuti al giorno, in modo fluido e coerente, ancorate al dato reale di oggi."