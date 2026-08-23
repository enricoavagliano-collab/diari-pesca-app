import { NextRequest, NextResponse } from "next/server";
import { searchLocations } from "@/lib/geocode";

export async function GET(req: NextRequest) {
  const query = req.nextUrl.searchParams.get("q");
  if (!query || query.trim().length < 2) {
    return NextResponse.json({ ok: true, results: [] });
  }

  const results = await searchLocations(query.trim());
  return NextResponse.json({ ok: true, results });
}

