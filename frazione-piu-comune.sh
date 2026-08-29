#!/bin/bash
set -e

echo "=== Mostro frazione + comune insieme (es. 'Campolimpido, Tivoli') ==="

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

    // Nome specifico (frazione/borgo/quartiere) e comune di appartenenza:
    // mostriamo entrambi quando diversi, cosi' il risultato e' preciso
    // (la frazione esatta) ma resta comunque riconoscibile (il comune).
    const specific: string | undefined = addr.village || addr.hamlet || addr.suburb;
    const city: string | undefined = addr.city || addr.town || addr.municipality;

    let place: string | undefined;
    if (specific && city && specific !== city) {
      place = `${specific}, ${city}`;
    } else {
      place = city || specific || addr.county;
    }

    return { name: place ? `${place} (posizione attuale)` : "Posizione attuale" };
  } catch {
    return { name: "Posizione attuale" };
  }
}
EOF

echo "=== File aggiornato: lib/reverse-geocode.ts ==="
echo ""
echo "Ricorda: bash frazione-piu-comune.sh, poi:"
echo "git add -A && git commit -m 'mostra frazione e comune insieme nel reverse geocoding' && git push"
