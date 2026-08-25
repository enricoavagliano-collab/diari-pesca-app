import { NextRequest, NextResponse } from "next/server";
import { getWeekTides } from "@/lib/tides";

export async function GET(req: NextRequest) {
  const lat = parseFloat(req.nextUrl.searchParams.get("lat") || "");
  const lon = parseFloat(req.nextUrl.searchParams.get("lon") || "");

  if (isNaN(lat) || isNaN(lon)) {
    return NextResponse.json({ ok: false, error: "Coordinate mancanti o non valide." }, { status: 400 });
  }

  try {
    const forecast = await getWeekTides(lat, lon);
    if (!forecast) {
      return NextResponse.json({ ok: false, error: "Maree non disponibili per questa località." });
    }
    return NextResponse.json({ ok: true, ...forecast });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "Errore nel recupero maree." },
      { status: 500 }
    );
  }
}

