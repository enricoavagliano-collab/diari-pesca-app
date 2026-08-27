#!/bin/bash
set -e

mkdir -p lib

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

// Trasforma la risposta JSON "hourly" nella nostra struttura DayWeather[].
// L'API previsioni e quella storica usano nomi di parametro leggermente diversi
// per vento e codice meteo (es. "windspeed_10m" vs "wind_speed_10m"), quindi
// controlliamo entrambe le varianti possibili.
function parseHourlyResponse(data: {
  timezone?: string;
  hourly?: Record<string, (number | null)[]> & { time: string[] };
}): WeekWeatherForecast | null {
  const times: string[] = data?.hourly?.time || [];
  if (times.length === 0) return null;

  const timezone: string = data?.timezone || "UTC";
  const h = data.hourly!;
  const temps = h.temperature_2m;
  const winds = h.windspeed_10m ?? h.wind_speed_10m ?? [];
  const dirs = h.winddirection_10m ?? h.wind_direction_10m ?? [];
  const pressures = h.surface_pressure ?? h.pressure_msl ?? [];
  const codes = h.weathercode ?? h.weather_code;

  if (!temps || !codes) return null;

  const byDate: Record<string, HourSlot[]> = {};

  for (let i = 0; i < times.length; i++) {
    const [date, time] = times[i].split("T");
    const hour = parseInt(time.split(":")[0], 10);
    if (hour % 2 !== 0) continue; // teniamo solo ogni 2 ore: 00, 02, 04 ... 22

    // Se manca il dato (es. giorno all'estremo bordo dell'archivio storico),
    // saltiamo la fascia invece di riportare uno zero fuorviante.
    if (temps[i] == null || codes[i] == null) continue;

    const { description, icon } = describeCode(codes[i] as number, hour);
    if (!byDate[date]) byDate[date] = [];
    byDate[date].push({
      time,
      tempC: Math.round(temps[i] as number),
      windSpeed: Math.round((winds[i] as number) ?? 0),
      windDirection: Math.round((dirs[i] as number) ?? 0),
      pressure: Math.round((pressures[i] as number) ?? 0),
      weatherCode: codes[i] as number,
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
    "temperature_2m,wind_speed_10m,wind_direction_10m,surface_pressure,weather_code"
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

echo "Fatto: nomi parametri corretti per lAPI storico (wind_speed_10m, weather_code)."
