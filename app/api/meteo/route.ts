import { NextRequest, NextResponse } from "next/server";
import { getWeekWeather } from "@/lib/weather";

const MAX_PAST_DAYS = 92; // limite dei dati storici "recenti" di Open-Meteo
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

  if (diff < -MAX_PAST_DAYS || diff > MAX_FORECAST_DAYS) {
    return NextResponse.json({
      ok: false,
      error: "Meteo non disponibile per questa data (solo ultimi 3 mesi o prossimi 16 giorni).",
    });
  }

  const pastDays = diff < 0 ? Math.min(MAX_PAST_DAYS, -diff) : 0;
  const forecastDays = diff >= 0 ? Math.min(MAX_FORECAST_DAYS, diff + 1) : 1;

  const forecast = await getWeekWeather(lat, lon, { pastDays, forecastDays });
  if (!forecast) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa località." });
  }

  const matchedDay =
    forecast.days.find((d) => d.date === date) ||
    // Se per qualsiasi motivo la data esatta non è tra quelle restituite
    // (es. limite dei dati storici), prendo il giorno disponibile più vicino
    // invece di fallire in silenzio.
    forecast.days.reduce<{ date: string; slots: typeof forecast.days[number]["slots"] } | null>((closest, d) => {
      const dDiff = Math.abs(diffInDays(d.date) - diff);
      const closestDiff = closest ? Math.abs(diffInDays(closest.date) - diff) : Infinity;
      return dDiff < closestDiff ? d : closest;
    }, null);

  if (!matchedDay) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa data." });
  }

  return NextResponse.json({ ok: true, days: [matchedDay], timezone: forecast.timezone });
}
