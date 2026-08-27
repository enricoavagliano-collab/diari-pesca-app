export interface ReverseGeocodeResult {
  name: string;
}

// Nominatim (OpenStreetMap) non richiede chiave API, ma richiede uno User-Agent
// identificativo per rispettare la loro policy d'uso.
export async function reverseGeocode(lat: number, lon: number): Promise<ReverseGeocodeResult> {
  try {
    const url = new URL("https://nominatim.openstreetmap.org/reverse");
    url.searchParams.set("lat", lat.toString());
    url.searchParams.set("lon", lon.toString());
    url.searchParams.set("format", "json");
    url.searchParams.set("accept-language", "it");
    url.searchParams.set("zoom", "14"); // livello città/paese, non via esatta

    const res = await fetch(url.toString(), {
      headers: { "User-Agent": "LibriDiPescaApp/1.0 (enricoavagliano.com)" },
    });
    if (!res.ok) return { name: "Posizione attuale" };

    const data = await res.json();
    const addr = data?.address || {};
    const place =
      addr.village || addr.town || addr.city || addr.hamlet || addr.suburb || addr.county;

    return { name: place ? `${place} (posizione attuale)` : "Posizione attuale" };
  } catch {
    return { name: "Posizione attuale" };
  }
}
