import { NextRequest, NextResponse } from "next/server";

// Percorsi sempre raggiungibili senza email: la pagina del gate stessa,
// tutte le API (servono anche prima che l'email sia data, es. per darla),
// e gli asset statici/PWA.
const PUBLIC_PREFIXES = [
  "/entra",
  "/api",
  "/_next",
  "/icons",
  "/covers",
  "/favicon.ico",
  "/manifest.json",
  "/sw.js",
];

function isPublic(pathname: string): boolean {
  return PUBLIC_PREFIXES.some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );
}

export function middleware(req: NextRequest) {
  const { pathname, search } = req.nextUrl;

  if (isPublic(pathname)) {
    return NextResponse.next();
  }

  const emailOk = req.cookies.get("email_ok")?.value === "1";
  if (emailOk) {
    return NextResponse.next();
  }

  const url = req.nextUrl.clone();
  url.pathname = "/entra";
  url.search = "";
  url.searchParams.set("next", pathname + search);
  return NextResponse.redirect(url);
}

export const config = {
  matcher: ["/((?!_next/static|_next/image).*)"],
};
