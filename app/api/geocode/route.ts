import { NextRequest, NextResponse } from "next/server";
import { searchLocations } from "@/lib/geocode";

export async function GET(req: NextRequest) {
  const query = req.nextUrl.searchParams.get("q");
  if (!query || query.trim().length < 2) {
    return NextResponse.json({ ok: true, results: [] });
  }

  const results = await searchLocations(query.trim());

  // Il database geografico a volte restituisce più voci con nome/regione/paese
  // identici (es. più "Roma" indistinguibili) — teniamo solo la prima di ognuna.
  const seen = new Set<string>();
  const deduped = results.filter((r) => {
    const key = `${r.name}|${r.admin1 || ""}|${r.country || ""}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  return NextResponse.json({ ok: true, results: deduped });
}
