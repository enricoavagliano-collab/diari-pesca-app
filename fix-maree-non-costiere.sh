#!/bin/bash
set -e
echo 'Aggiungo il limite di distanza stazione: niente maree per localita non costiere...'
cat > "lib/tides.ts" << 'SETUP_EOF_MARKER'
export interface TideExtreme {
  time: string; // HH:mm locale
  type: "alta" | "bassa";
  height: number; // metri
  stimato: boolean;
}

export interface WeekTideEvent extends TideExtreme {
  date: string; // YYYY-MM-DD locale
}

export interface WeekTideForecast {
  events: WeekTideEvent[];
  timezone: string;
}

/**
 * Recupera le maree di una settimana intera in una sola chiamata.
 * IMPORTANTE: chiediamo esplicitamente "localtime" — così WorldTides ci restituisce
 * già l'orario locale pronto (con offset incluso nella stringa ISO), invece di doverlo
 * ricalcolare noi da un timestamp UTC. Meno margine di errore, niente conversioni a mano.
 */
export async function getWeekTides(lat: number, lon: number): Promise<WeekTideForecast | null> {
  const apiKey = process.env.WORLDTIDES_API_KEY;
  if (!apiKey) {
    throw new Error("Manca WORLDTIDES_API_KEY nelle variabili d'ambiente.");
  }

  // Costruzione manuale della query string (non URLSearchParams) per essere sicuri che i
  // parametri "flag" (extremes, localtime, timezone) restino senza "=" vuoto, esattamente
  // come negli esempi ufficiali della documentazione.
  const params = [
    "extremes",
    "localtime",
    "timezone",
    `date=today`,
    `days=7`,
    `lat=${encodeURIComponent(lat)}`,
    `lon=${encodeURIComponent(lon)}`,
    `stationDistance=50`, // entro 50km: oltre, niente stazione reale = niente dato inventato
    `key=${encodeURIComponent(apiKey)}`,
  ];
  const url = `https://www.worldtides.info/api/v3?${params.join("&")}`;

  const res = await fetch(url);
  if (!res.ok) return null;

  const data = await res.json();
  if (data.status !== 200 || !Array.isArray(data.extremes) || data.extremes.length === 0) return null;

  const timezone: string = data.timezone || "UTC";

  // Con "localtime" attivo, ogni evento ha un campo "date" in ISO8601 con l'offset locale
  // già incluso, es. "2026-08-25T08:44:00+02:00" — lo leggiamo direttamente come testo,
  // senza passare da nessuna conversione di fuso fatta da noi.
  const events: WeekTideEvent[] = data.extremes.map(
    (e: { date: string; height: number; type: string }) => {
      const match = e.date.match(/^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})/);
      const dateStr = match ? match[1] : e.date.slice(0, 10);
      const timeStr = match ? match[2] : "00:00";
      return {
        date: dateStr,
        time: timeStr,
        type: e.type === "High" ? "alta" : "bassa",
        height: Math.round(e.height * 100) / 100,
        stimato: false,
      };
    }
  );

  return { events, timezone };
}

SETUP_EOF_MARKER
cat > "app/api/maree/tides/route.ts" << 'SETUP_EOF_MARKER'
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
      return NextResponse.json({
        ok: false,
        error: "Nessuna stazione di marea nelle vicinanze — questa sezione funziona solo per località costiere.",
      });
    }
    return NextResponse.json({ ok: true, ...forecast });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "Errore nel recupero maree." },
      { status: 500 }
    );
  }
}

SETUP_EOF_MARKER
echo "Fatto: localita a piu di 50km dal mare mostrano un avviso invece di dati inventati."