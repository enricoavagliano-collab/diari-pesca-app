import { NextRequest, NextResponse } from "next/server";
import { getWeekWeather } from "@/lib/weather";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json({ ok: false, error: "Coordinate mancanti o non valide." }, { status: 400 });
  }

  const forecast = await getWeekWeather(lat, lon);
  if (!forecast) {
    return NextResponse.json({ ok: false, error: "Meteo non disponibile per questa località." });
  }

  return NextResponse.json({ ok: true, ...forecast });
}

