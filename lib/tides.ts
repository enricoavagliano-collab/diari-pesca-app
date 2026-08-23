export interface TideExtreme {
  time: string; // HH:mm locale
  type: "alta" | "bassa";
  height: number; // metri, relativo al livello medio del mare (non è un datum di navigazione)
}

export interface TideForecast {
  today: TideExtreme[];
  hourlySeries: { time: string; height: number }[]; // per disegnare il grafico
  timezone: string;
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
  url.searchParams.set("past_days", "1"); // serve un'ora prima per rilevare un picco a mezzanotte

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  const times: string[] = data?.hourly?.time || [];
  const heights: (number | null)[] = data?.hourly?.sea_level_height_msl || [];
  const timezone: string = data?.timezone || "UTC";

  if (times.length === 0 || heights.every((h) => h === null)) return null;

  const series = times
    .map((t, i) => ({ time: t, height: heights[i] }))
    .filter((p): p is { time: string; height: number } => p.height !== null);

  // Trova i picchi locali (massimi e minimi) confrontando ogni punto con i vicini
  const extremes: TideExtreme[] = [];
  for (let i = 1; i < series.length - 1; i++) {
    const prev = series[i - 1].height;
    const curr = series[i].height;
    const next = series[i + 1].height;
    const isTargetDay = series[i].time.startsWith(targetDate);
    if (!isTargetDay) continue;

    if (curr > prev && curr > next) {
      extremes.push({
        time: formatLocalTime(series[i].time),
        type: "alta",
        height: Math.round(curr * 100) / 100,
      });
    } else if (curr < prev && curr < next) {
      extremes.push({
        time: formatLocalTime(series[i].time),
        type: "bassa",
        height: Math.round(curr * 100) / 100,
      });
    }
  }

  const hourlySeries = series
    .filter((p) => p.time.startsWith(targetDate))
    .map((p) => ({ time: formatLocalTime(p.time), height: p.height }));

  return { today: extremes, hourlySeries, timezone };
}

function formatLocalTime(isoLike: string): string {
  // Open-Meteo con timezone=auto restituisce già l'ora locale, es. "2026-08-23T14:00"
  const match = isoLike.match(/T(\d{2}:\d{2})/);
  return match ? match[1] : isoLike;
}

