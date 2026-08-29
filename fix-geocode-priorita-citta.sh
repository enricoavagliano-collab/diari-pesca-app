#!/bin/bash
set -e

echo "=== Correggo la priorita' nel reverse geocoding (citta' invece di frazioni) ==="

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
    // Priorita' a citta'/comune principale: una frazione o borgo minore
    // (village/hamlet) spesso ha un nome diverso dal comune di riferimento
    // e risulta meno riconoscibile per chi cerca la propria posizione.
    const place =
      addr.city || addr.town || addr.municipality || addr.village || addr.hamlet || addr.suburb || addr.county;

    return { name: place ? `${place} (posizione attuale)` : "Posizione attuale" };
  } catch {
    return { name: "Posizione attuale" };
  }
}
EOF

echo "=== File corretto: lib/reverse-geocode.ts ==="
echo ""
echo "Ricorda: bash fix-geocode-priorita-citta.sh, poi:"
echo "git add -A && git commit -m 'fix priorita reverse geocode: citta invece di frazioni' && git push"
