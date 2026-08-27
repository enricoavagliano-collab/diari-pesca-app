#!/bin/bash
set -e

mkdir -p lib app/api/meteo

cat > lib/weather.ts << 'FILE_EOF'
export interface HourSlot {
  time: string; // HH:mm
  tempC: number;
  windSpeed: number; // km/h
  windDirection: number; // gradi
  pressure: number; // hPa
  weatherCode: number;
  description: string;
  icon: string;
}

export interface DayWeather {
  date: string; // YYYY-MM-DD
  slots: HourSlot[]; // ogni 2 ore, dalle 00:00 alle 22:00
}

export interface WeekWeatherForecast {
  days: DayWeather[];
  timezone: string;
}

const WEATHER_CODES: Record<number, { description: string; icon: string }> = {
  0: { description: "Sereno", icon: "☀️" },
  1: { description: "Prevalentemente sereno", icon: "🌤️" },
  2: { description: "Parzialmente nuvoloso", icon: "⛅" },
  3: { description: "Nuvoloso", icon: "☁️" },
  45: { description: "Nebbia", icon: "🌫️" },
  48: { description: "Nebbia con brina", icon: "🌫️" },
  51: { description: "Pioviggine leggera", icon: "🌦️" },
  53: { description: "Pioviggine moderata", icon: "🌦️" },
  55: { description: "Pioviggine intensa", icon: "🌧️" },
  61: { description: "Pioggia leggera", icon: "🌧️" },
  63: { description: "Pioggia moderata", icon: "🌧️" },
  65: { description: "Pioggia intensa", icon: "🌧️" },
  71: { description: "Neve leggera", icon: "🌨️" },
  73: { description: "Neve moderata", icon: "🌨️" },
  75: { description: "Neve intensa", icon: "❄️" },
  80: { description: "Rovesci leggeri", icon: "🌦️" },
  81: { description: "Rovesci moderati", icon: "🌧️" },
  82: { description: "Rovesci violenti", icon: "⛈️" },
  95: { description: "Temporale", icon: "⛈️" },
  96: { description: "Temporale con grandine", icon: "⛈️" },
  99: { description: "Temporale forte con grandine", icon: "⛈️" },
};

function describeCode(code: number, hour: number): { description: string; icon: string } {
  const base = WEATHER_CODES[code] || { description: "Condizioni variabili", icon: "🌡️" };
  const isNight = hour < 6 || hour >= 20;
  if (isNight) {
    if (code === 0) return { ...base, icon: "🌙" };
    if (code === 1) return { ...base, icon: "🌙" };
    if (code === 2) return { ...base, icon: "☁️" };
  }
  return base;
}

// Trasforma la risposta JSON "hourly" (uguale sia per l'API previsioni sia per
// quella storica) nella nostra struttura DayWeather[].
function parseHourlyResponse(data: {
  timezone?: string;
  hourly?: {
    time: string[];
    temperature_2m: number[];
    windspeed_10m: number[];
    winddirection_10m: number[];
    surface_pressure: number[];
    weathercode: number[];
  };
}): WeekWeatherForecast | null {
  const times: string[] = data?.hourly?.time || [];
  if (times.length === 0) return null;

  const timezone: string = data?.timezone || "UTC";
  const temps = data.hourly!.temperature_2m;
  const winds = data.hourly!.windspeed_10m;
  const dirs = data.hourly!.winddirection_10m;
  const pressures = data.hourly!.surface_pressure;
  const codes = data.hourly!.weathercode;

  const byDate: Record<string, HourSlot[]> = {};

  for (let i = 0; i < times.length; i++) {
    const [date, time] = times[i].split("T");
    const hour = parseInt(time.split(":")[0], 10);
    if (hour % 2 !== 0) continue; // teniamo solo ogni 2 ore: 00, 02, 04 ... 22

    // Se manca il dato (es. giorno all'estremo bordo dell'archivio storico),
    // saltiamo la fascia invece di riportare uno zero fuorviante.
    if (temps[i] == null || codes[i] == null) continue;

    const { description, icon } = describeCode(codes[i], hour);
    if (!byDate[date]) byDate[date] = [];
    byDate[date].push({
      time,
      tempC: Math.round(temps[i]),
      windSpeed: Math.round(winds[i] ?? 0),
      windDirection: Math.round(dirs[i] ?? 0),
      pressure: Math.round(pressures[i] ?? 0),
      weatherCode: codes[i],
      description,
      icon,
    });
  }

  const days: DayWeather[] = Object.entries(byDate).map(([date, slots]) => ({
    date,
    slots: slots.sort((a, b) => a.time.localeCompare(b.time)),
  }));

  return { days, timezone };
}

export async function getWeekWeather(
  lat: number,
  lon: number,
  options?: { pastDays?: number; forecastDays?: number }
): Promise<WeekWeatherForecast | null> {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set(
    "hourly",
    "temperature_2m,windspeed_10m,winddirection_10m,surface_pressure,weathercode"
  );
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", String(options?.forecastDays ?? 7));
  if (options?.pastDays) {
    url.searchParams.set("past_days", String(options.pastDays));
  }

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  return parseHourlyResponse(await res.json());
}

// Per date più vecchie di ~10 giorni l'API "previsioni" non ha più dati reali
// (torna solo l'ultima previsione disponibile, spesso vuota/azzerata).
// Per lo storico vero serve l'API archivio di Open-Meteo (dati rianalisi ERA5),
// disponibile da diversi giorni fa fino al 1940.
export async function getArchiveWeather(
  lat: number,
  lon: number,
  startDate: string,
  endDate: string
): Promise<WeekWeatherForecast | null> {
  const url = new URL("https://archive-api.open-meteo.com/v1/archive");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set("start_date", startDate);
  url.searchParams.set("end_date", endDate);
  url.searchParams.set(
    "hourly",
    "temperature_2m,windspeed_10m,winddirection_10m,surface_pressure,weathercode"
  );
  url.searchParams.set("timezone", "auto");

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  return parseHourlyResponse(await res.json());
}

export function windDirectionLabel(degrees: number): string {
  const dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"];
  return dirs[Math.round(degrees / 45) % 8];
}
FILE_EOF

cat > app/api/meteo/route.ts << 'FILE_EOF'
import { NextRequest, NextResponse } from "next/server";
import { getWeekWeather, getArchiveWeather } from "@/lib/weather";

// Oltre questa soglia di giorni nel passato, l'API "previsioni" di Open-Meteo
// non ha più dati reali (torna solo l'ultima previsione disponibile, spesso
// azzerata) — da qui in poi usiamo l'API archivio storico (ERA5).
const RECENT_PAST_THRESHOLD_DAYS = 7;
const MAX_ARCHIVE_YEARS_BACK = 3; // limite ragionevole per un diario di pesca
const MAX_FORECAST_DAYS = 16;

function diffInDays(dateStr: string): number {
  const target = new Date(dateStr + "T00:00:00");
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((target.getTime() - today.getTime()) / 86400000);
}

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");
  const date = req.nextUrl.searchParams.get("date"); // YYYY-MM-DD, opzionale

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json({ ok: false, error: "Coordinate mancanti o non valide." }, { status: 400 });
  }

  // Nessuna data richiesta: comportamento invariato, meteo di oggi + prossimi giorni
  // (usato dalla pagina Meteo generale dell'app).
  if (!date) {
    const forecast = await getWeekWeather(lat, lon);
    if (!forecast) {
      return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa località." });
    }
    return NextResponse.json({ ok: true, ...forecast });
  }

  const diff = diffInDays(date);
  const maxPastDays = MAX_ARCHIVE_YEARS_BACK * 365;

  if (diff < -maxPastDays || diff > MAX_FORECAST_DAYS) {
    return NextResponse.json({
      ok: false,
      error: `Meteo non disponibile per questa data (solo fino a ${MAX_ARCHIVE_YEARS_BACK} anni fa o prossimi 16 giorni).`,
    });
  }

  let forecast;

  if (diff >= -RECENT_PAST_THRESHOLD_DAYS) {
    // Oggi, futuro, o passato molto recente: API previsioni con past_days.
    const pastDays = diff < 0 ? -diff : 0;
    const forecastDays = diff >= 0 ? Math.min(MAX_FORECAST_DAYS, diff + 1) : 1;
    forecast = await getWeekWeather(lat, lon, { pastDays, forecastDays });
  } else {
    // Passato più lontano: API archivio storico (ERA5).
    forecast = await getArchiveWeather(lat, lon, date, date);
  }

  if (!forecast || forecast.days.length === 0) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa data/località." });
  }

  const matchedDay =
    forecast.days.find((d) => d.date === date) ||
    // Se per qualsiasi motivo la data esatta non è tra quelle restituite,
    // prendo il giorno disponibile più vicino invece di fallire in silenzio.
    forecast.days.reduce<{ date: string; slots: typeof forecast.days[number]["slots"] } | null>((closest, d) => {
      const dDiff = Math.abs(diffInDays(d.date) - diff);
      const closestDiff = closest ? Math.abs(diffInDays(closest.date) - diff) : Infinity;
      return dDiff < closestDiff ? d : closest;
    }, null);

  if (!matchedDay || matchedDay.slots.length === 0) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa data." });
  }

  return NextResponse.json({ ok: true, days: [matchedDay], timezone: forecast.timezone });
}
FILE_EOF

echo "Fatto: date lontane nel passato ora usano larchivio storico vero (fino a 3 anni fa)."
