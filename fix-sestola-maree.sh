#!/bin/bash
set -e
echo 'Correggo il controllo localita costiere: verifica vera con endpoint stations...'
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

  // 1) Prima controlliamo che esista DAVVERO una stazione di marea entro 50km.
  //    (il parametro stationDistance sulla richiesta "extremes" viene ignorato da
  //    WorldTides — va usato con "stations" per avere un controllo vero)
  const stationsUrl = `https://www.worldtides.info/api/v3?stations&lat=${encodeURIComponent(
    lat
  )}&lon=${encodeURIComponent(lon)}&stationDistance=50&key=${encodeURIComponent(apiKey)}`;

  const stationsRes = await fetch(stationsUrl);
  if (!stationsRes.ok) return null;
  const stationsData = await stationsRes.json();
  if (!Array.isArray(stationsData.stations) || stationsData.stations.length === 0) {
    return null; // nessuna stazione vicina: località non costiera
  }

  // 2) Solo se c'è una stazione vera vicina, chiediamo le maree
  const params = [
    "extremes",
    "localtime",
    "timezone",
    `date=today`,
    `days=7`,
    `lat=${encodeURIComponent(lat)}`,
    `lon=${encodeURIComponent(lon)}`,
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
echo "Fatto: Sestola e altre localita di montagna ora mostrano l avviso invece della marea."