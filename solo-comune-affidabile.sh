#!/bin/bash
set -e

echo "=== Torno a mostrare solo il comune (affidabile) ==="

cat > lib/reverse-geocode.ts << 'EOF'
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
    // Solo il comune: in Italia molte frazioni sono mappate su OpenStreetMap
    // come singolo punto anziche' come area/confine, quindi Nominatim le
    // assegna per "punto piu' vicino" e puo' sbagliare anche di diversi km.
    // Il confine del comune invece e' affidabile, quindi ci fermiamo li'.
    const place = addr.city || addr.town || addr.municipality || addr.village || addr.county;

    return { name: place ? `${place} (posizione attuale)` : "Posizione attuale" };
  } catch {
    return { name: "Posizione attuale" };
  }
}
EOF

echo "=== File aggiornato: lib/reverse-geocode.ts ==="
echo ""
echo "Ricorda: bash solo-comune-affidabile.sh, poi:"
echo "git add -A && git commit -m 'reverse geocode: solo comune, frazioni inaffidabili su OSM' && git push"
