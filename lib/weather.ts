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

  const data = await res.json();
  const times: string[] = data?.hourly?.time || [];
  if (times.length === 0) return null;

  const timezone: string = data?.timezone || "UTC";
  const temps: number[] = data.hourly.temperature_2m;
  const winds: number[] = data.hourly.windspeed_10m;
  const dirs: number[] = data.hourly.winddirection_10m;
  const pressures: number[] = data.hourly.surface_pressure;
  const codes: number[] = data.hourly.weathercode;

  const byDate: Record<string, HourSlot[]> = {};

  for (let i = 0; i < times.length; i++) {
    const [date, time] = times[i].split("T");
    const hour = parseInt(time.split(":")[0], 10);
    if (hour % 2 !== 0) continue; // teniamo solo ogni 2 ore: 00, 02, 04 ... 22

    const { description, icon } = describeCode(codes[i], hour);
    if (!byDate[date]) byDate[date] = [];
    byDate[date].push({
      time,
      tempC: Math.round(temps[i]),
      windSpeed: Math.round(winds[i]),
      windDirection: Math.round(dirs[i]),
      pressure: Math.round(pressures[i]),
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

export function windDirectionLabel(degrees: number): string {
  const dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"];
  return dirs[Math.round(degrees / 45) % 8];
}
