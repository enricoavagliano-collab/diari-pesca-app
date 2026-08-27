import { NextRequest, NextResponse } from "next/server";
import { isValidEmail } from "@/lib/brevo";

export async function POST(req: NextRequest) {
  let body: { email?: string; consent?: boolean };

  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Body non valido" }, { status: 400 });
  }

  const { email, consent } = body;

  if (!email || !isValidEmail(email)) {
    return NextResponse.json({ error: "Email non valida" }, { status: 400 });
  }
  if (!consent) {
    return NextResponse.json(
      { error: "Devi accettare per continuare." },
      { status: 400 }
    );
  }

  const res = NextResponse.json({ ok: true });

  // Sblocca la navigazione nell'app (letto dal middleware)
  res.cookies.set("email_ok", "1", {
    maxAge: 60 * 60 * 24 * 365 * 5,
    path: "/",
    sameSite: "lax",
  });

  // Ricordiamo l'email per collegarla alla lista Brevo giusta quando,
  // più avanti, l'utente inserisce il codice del suo libro specifico.
  res.cookies.set("visitor_email", email, {
    maxAge: 60 * 60 * 24 * 365 * 5,
    path: "/",
    sameSite: "lax",
  });

  return res;
}
