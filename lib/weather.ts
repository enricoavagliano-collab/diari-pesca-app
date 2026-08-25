export interface DayWeather {
  date: string; // YYYY-MM-DD
  tempMax: number;
  tempMin: number;
  windSpeed: number; // km/h
  windDirection: number; // gradi (0-360)
  pressure: number; // hPa
  weatherCode: number;
  description: string;
  icon: string;
}

export interface WeekWeatherForecast {
  days: DayWeather[];
  timezone: string;
}

// Codici meteo WMO usati da Open-Meteo, tradotti in italiano
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

function describeCode(code: number): { description: string; icon: string } {
  return WEATHER_CODES[code] || { description: "Condizioni variabili", icon: "🌡️" };
}

export async function getWeekWeather(lat: number, lon: number): Promise<WeekWeatherForecast | null> {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", lat.toString());
  url.searchParams.set("longitude", lon.toString());
  url.searchParams.set("daily", "weathercode,temperature_2m_max,temperature_2m_min,windspeed_10m_max,winddirection_10m_dominant");
  url.searchParams.set("hourly", "surface_pressure");
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", "7");

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  const dailyTimes: string[] = data?.daily?.time || [];
  if (dailyTimes.length === 0) return null;

  const timezone: string = data?.timezone || "UTC";
  const hourlyTimes: string[] = data?.hourly?.time || [];
  const hourlyPressure: number[] = data?.hourly?.surface_pressure || [];

  const days: DayWeather[] = dailyTimes.map((date: string, i: number) => {
    // Pressione: prendo il valore delle 12:00 di quel giorno come rappresentativo
    const middayIdx = hourlyTimes.findIndex((t) => t === `${date}T12:00`);
    const pressure = middayIdx >= 0 ? hourlyPressure[middayIdx] : hourlyPressure[i * 24 + 12] || 1013;

    const code = data.daily.weathercode[i];
    const { description, icon } = describeCode(code);

    return {
      date,
      tempMax: Math.round(data.daily.temperature_2m_max[i]),
      tempMin: Math.round(data.daily.temperature_2m_min[i]),
      windSpeed: Math.round(data.daily.windspeed_10m_max[i]),
      windDirection: Math.round(data.daily.winddirection_10m_dominant[i]),
      pressure: Math.round(pressure),
      weatherCode: code,
      description,
      icon,
    };
  });

  return { days, timezone };
}

export function windDirectionLabel(degrees: number): string {
  const dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"];
  const idx = Math.round(degrees / 45) % 8;
  return dirs[idx];
}

