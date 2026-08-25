import { NextRequest, NextResponse } from "next/server";
import { getMoonData } from "@/lib/moon";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");
  const timezone = req.nextUrl.searchParams.get("tz") || "Europe/Rome";
  const dateParam = req.nextUrl.searchParams.get("date");

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json({ ok: false, error: "Coordinate mancanti o non valide." }, { status: 400 });
  }

  const targetDate = dateParam || new Date().toLocaleDateString("sv-SE", { timeZone: timezone });
  const moonDate = new Date(`${targetDate}T12:00:00`);
  const moon = getMoonData(lat, lon, moonDate, timezone);

  return NextResponse.json({ ok: true, moon });
}

