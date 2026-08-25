export interface TideExtreme {
  time: string; // HH:mm locale
  type: "alta" | "bassa";
  height: number; // metri
  stimato: boolean; // sempre false con WorldTides: sono previsioni vere, non stimate da noi
}

export interface WeekTideEvent extends TideExtreme {
  date: string; // YYYY-MM-DD locale
}

export interface WeekTideForecast {
  events: WeekTideEvent[];
  timezone: string;
}

/**
 * Recupera le maree di UNA SETTIMANA intera in una sola chiamata (1 credito WorldTides
 * copre 7 giorni per località) — così cambiare giorno nell'app non consuma altri crediti,
 * si naviga tra i dati già scaricati.
 */
export async function getWeekTides(lat: number, lon: number): Promise<WeekTideForecast | null> {
  const apiKey = process.env.WORLDTIDES_API_KEY;
  if (!apiKey) {
    throw new Error("Manca WORLDTIDES_API_KEY nelle variabili d'ambiente.");
  }

  const url = new URL("https://www.worldtides.info/api/v3");
  url.searchParams.set("extremes", "");
  url.searchParams.set("date", "today");
  url.searchParams.set("days", "7");
  url.searchParams.set("lat", lat.toString());
  url.searchParams.set("lon", lon.toString());
  url.searchParams.set("timezone", "");
  url.searchParams.set("key", apiKey);

  const res = await fetch(url.toString());
  if (!res.ok) return null;

  const data = await res.json();
  if (data.status !== 200 || !Array.isArray(data.extremes)) return null;

  const timezone: string = data.timezone || "UTC";

  const events: WeekTideEvent[] = data.extremes.map(
    (e: { dt: number; height: number; type: string }) => {
      const d = new Date(e.dt * 1000);
      const dateStr = new Intl.DateTimeFormat("sv-SE", { timeZone: timezone }).format(d); // YYYY-MM-DD
      const timeStr = new Intl.DateTimeFormat("it-IT", {
        timeZone: timezone,
        hour: "2-digit",
        minute: "2-digit",
        hour12: false,
      }).format(d);
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

