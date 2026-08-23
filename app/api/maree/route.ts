import { NextRequest, NextResponse } from "next/server";
import { getTideForecast } from "@/lib/tides";
import { getMoonData } from "@/lib/moon";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");
  const timezone = req.nextUrl.searchParams.get("tz") || "Europe/Rome";
  const dateParam = req.nextUrl.searchParams.get("date"); // YYYY-MM-DD, opzionale

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json(
      { ok: false, error: "Coordinate mancanti o non valide." },
      { status: 400 }
    );
  }

  const targetDate =
    dateParam || new Date().toLocaleDateString("sv-SE", { timeZone: timezone });

  // Per la luna serve un oggetto Date reale: costruisco mezzogiorno locale del giorno scelto
  const moonDate = new Date(`${targetDate}T12:00:00`);

  const [tides, moon] = await Promise.all([
    getTideForecast(lat, lon, targetDate),
    Promise.resolve(getMoonData(lat, lon, moonDate, timezone)),
  ]);

  return NextResponse.json({ ok: true, tides, moon, date: targetDate });
}

