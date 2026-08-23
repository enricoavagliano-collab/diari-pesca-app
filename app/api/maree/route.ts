import { NextRequest, NextResponse } from "next/server";
import { getTideForecast } from "@/lib/tides";
import { getMoonData } from "@/lib/moon";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");
  const timezone = req.nextUrl.searchParams.get("tz") || "Europe/Rome";

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json(
      { ok: false, error: "Coordinate mancanti o non valide." },
      { status: 400 }
    );
  }

  const [tides, moon] = await Promise.all([
    getTideForecast(lat, lon),
    Promise.resolve(getMoonData(lat, lon, new Date(), timezone)),
  ]);

  return NextResponse.json({ ok: true, tides, moon });
}

