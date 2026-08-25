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

// Periodo semidiurno medio della marea M2 (la componente principale, quasi costante ovunque):
// un ciclo alta→alta dura ~12h 25min, quindi alta→bassa (o viceversa) ~6h 12,5min.
const HALF_PERIOD_MINUTES = 6 * 60 + 12.5; // 372.5 minuti

interface RawPoint {
  dateTime: Date; // interpretato come "orario locale ingenuo" (naive), coerente in tutto il calcolo
  height: number;
}

function parseLocalNaive(isoLike: string): Date {
  // "2026-08-24T14:00" → Date costruito nei componenti locali, senza conversioni di fuso.
  // Usiamo questo oggetto solo per fare differenze in minuti tra istanti, mai per formattarlo con fusi diversi.
  const [datePart, timePart] = isoLike.split("T");
  const [y, m, d] = datePart.split("-").map(Number);
  const [hh, mm] = timePart.split(":").map(Number);
  return new Date(y, m - 1, d, hh, mm);
}

function formatHM(date: Date): string {
  const hh = String(date.getHours()).padStart(2, "0");
  const mm = String(date.getMinutes()).padStart(2, "0");
  return `${hh}:${mm}`;
}

function dateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
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

  const series: RawPoint[] = times
    .map((t, i) => ({ dateTime: parseLocalNaive(t), height: heights[i] }))
    .filter((p): p is RawPoint => p.height !== null);

  if (series.length < 3) return null;

  // 1) Cerca i picchi VERI in tutta la finestra di dati disponibile (non solo nel giorno scelto),
  //    così anche se il giorno target è piatto possiamo comunque trovare un'ancora nei giorni vicini.
  const detected: { dateTime: Date; type: "alta" | "bassa"; height: number }[] = [];
  for (let i = 1; i < series.length - 1; i++) {
    const prev = series[i - 1].height;
    const curr = series[i].height;
    const next = series[i + 1].height;
    if (curr > prev && curr > next) {
      detected.push({ dateTime: series[i].dateTime, type: "alta", height: curr });
    } else if (curr < prev && curr < next) {
      detected.push({ dateTime: series[i].dateTime, type: "bassa", height: curr });
    }
  }

  const hourlySeries = series
    .filter((p) => dateKey(p.dateTime) === targetDate)
    .map((p) => ({ time: formatHM(p.dateTime), height: p.height }));

  if (detected.length === 0) {
    // Davvero nessun segnale di marea rilevabile in tutta la finestra: onesto dirlo, non inventiamo nulla.
    return { today: [], hourlySeries, timezone };
  }

  // 2) Scegli come "ancora" il picco rilevato più vicino al giorno target
  const targetMid = parseLocalNaive(`${targetDate}T12:00`);
  const anchor = detected.reduce((best, p) =>
    Math.abs(p.dateTime.getTime() - targetMid.getTime()) <
    Math.abs(best.dateTime.getTime() - targetMid.getTime())
      ? p
      : best
  );

  // Altezza media approssimativa per alta/bassa, usando tutti i picchi rilevati (se ce n'è più di uno)
  const altHeights = detected.filter((p) => p.type === "alta").map((p) => p.height);
  const bassHeights = detected.filter((p) => p.type === "bassa").map((p) => p.height);
  const avgAlta = altHeights.length
    ? altHeights.reduce((a, b) => a + b, 0) / altHeights.length
    : Math.abs(anchor.height);
  const avgBassa = bassHeights.length
    ? bassHeights.reduce((a, b) => a + b, 0) / bassHeights.length
    : -Math.abs(anchor.height);

  // 3) Genera la sequenza periodica alternata (alta/bassa) a partire dall'ancora,
  //    coprendo un paio di giorni prima e dopo per essere sicuri di coprire il giorno target
  const generated: TideExtreme[] = [];
  const stepMs = HALF_PERIOD_MINUTES * 60 * 1000;
  const windowStart = anchor.dateTime.getTime() - 4 * 24 * 60 * 60 * 1000;
  const windowEnd = anchor.dateTime.getTime() + 4 * 24 * 60 * 60 * 1000;

  let idx = Math.ceil((windowStart - anchor.dateTime.getTime()) / stepMs);
  const endIdx = Math.floor((windowEnd - anchor.dateTime.getTime()) / stepMs);

  for (; idx <= endIdx; idx++) {
    const t = new Date(anchor.dateTime.getTime() + idx * stepMs);
    if (dateKey(t) !== targetDate) continue;

    // L'ancora alterna tipo ad ogni passo dispari/pari rispetto al proprio tipo
    const isSameTypeAsAnchor = idx % 2 === 0;
    const type: "alta" | "bassa" = isSameTypeAsAnchor
      ? anchor.type
      : anchor.type === "alta"
      ? "bassa"
      : "alta";

    // Se questo istante coincide (entro 30 min) con un picco davvero rilevato, usa il dato vero
    const realMatch = detected.find(
      (d) => Math.abs(d.dateTime.getTime() - t.getTime()) < 30 * 60 * 1000
    );

    generated.push({
      time: formatHM(realMatch ? realMatch.dateTime : t),
      type,
      height: Math.round((realMatch ? realMatch.height : type === "alta" ? avgAlta : avgBassa) * 100) / 100,
      stimato: !realMatch,
    });
  }

  generated.sort((a, b) => a.time.localeCompare(b.time));

  return { today: generated, hourlySeries, timezone };
}

