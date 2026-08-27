#!/bin/bash
set -e

echo "=== Aggiungo debug temporaneo per capire il problema Brevo ==="

python3 << 'PYEOF'
path = "app/api/unlock/route.ts"
with open(path, "r") as f:
    content = f.read()

old_marker = 'let brevoDebug = "non tentato";'
if old_marker in content:
    print("Debug già presente in app/api/unlock/route.ts, salto.")
else:
    old = '''  const res = NextResponse.json({ ok: true, bookId: book.id, bookName: book.name });

  // Cookie di sblocco: 1 anno, leggibile lato client per mostrare lo stato "Sbloccato"
  res.cookies.set(`unlock_${book.id}`, "1", {
    maxAge: 60 * 60 * 24 * 365,
    path: "/",
    sameSite: "lax",
  });

  // Collega l'email già data al gate d'ingresso alla lista Brevo di
  // questo libro specifico (best-effort: se fallisce non blocca lo sblocco).
  const visitorEmail = req.cookies.get("visitor_email")?.value;
  const brevoBook = toBrevoBook(book.id);
  if (visitorEmail && brevoBook) {
    try {
      await subscribeToBrevo(visitorEmail, brevoBook);
    } catch (err) {
      console.error("Errore invio a Brevo dopo sblocco:", err);
    }
  }

  return res;
}'''

    new = '''  // Collega l'email già data al gate d'ingresso alla lista Brevo di
  // questo libro specifico (best-effort: se fallisce non blocca lo sblocco).
  // DEBUG TEMPORANEO: brevoDebug nella risposta serve solo per diagnosticare
  // perche i contatti non arrivano su Brevo - va rimosso una volta risolto.
  const visitorEmail = req.cookies.get("visitor_email")?.value;
  const brevoBook = toBrevoBook(book.id);
  let brevoDebug = "non tentato";

  if (!visitorEmail) {
    brevoDebug = "cookie visitor_email assente nella richiesta";
  } else if (!brevoBook) {
    brevoDebug = `nessuna lista Brevo mappata per bookId '${book.id}'`;
  } else {
    try {
      const brevoResult = await subscribeToBrevo(visitorEmail, brevoBook);
      brevoDebug = brevoResult.ok
        ? `OK (email: ${visitorEmail}, lista: ${brevoBook})`
        : `ERRORE status ${brevoResult.status}: ${brevoResult.error}`;
    } catch (err) {
      brevoDebug = `ECCEZIONE: ${err instanceof Error ? err.message : String(err)}`;
    }
  }

  const res = NextResponse.json({
    ok: true,
    bookId: book.id,
    bookName: book.name,
    brevoDebug,
  });

  // Cookie di sblocco: 1 anno, leggibile lato client per mostrare lo stato "Sbloccato"
  res.cookies.set(`unlock_${book.id}`, "1", {
    maxAge: 60 * 60 * 24 * 365,
    path: "/",
    sameSite: "lax",
  });

  return res;
}'''

    if old not in content:
        raise SystemExit("Blocco atteso non trovato in app/api/unlock/route.ts")

    content = content.replace(old, new)
    with open(path, "w") as f:
        f.write(content)
    print("app/api/unlock/route.ts aggiornato.")
PYEOF

python3 << 'PYEOF'
path = "app/sblocca/page.tsx"
with open(path, "r") as f:
    content = f.read()

old = '''            setBookName(data.bookName);
            setMessage(`${data.bookName} sbloccato su questo dispositivo.`);
            setTimeout(() => router.push("/"), 1800);'''

new = '''            setBookName(data.bookName);
            setMessage(
              `${data.bookName} sbloccato su questo dispositivo.` +
                (data.brevoDebug ? ` [DEBUG Brevo: ${data.brevoDebug}]` : "")
            );
            setTimeout(() => router.push("/"), 8000); // rallentato temporaneamente per leggere il debug Brevo'''

if old not in content:
    print("Blocco atteso non trovato in app/sblocca/page.tsx (forse già modificato), salto.")
else:
    content = content.replace(old, new)
    with open(path, "w") as f:
        f.write(content)
    print("app/sblocca/page.tsx aggiornato.")
PYEOF

echo ""
echo "=== IMPORTANTE ==="
echo "Questo è un debug TEMPORANEO. Dopo aver capito il problema, va"
echo "rimosso (basta chiedermelo e ti preparo lo script di pulizia)."
echo ""
echo "Ricorda: bash debug-brevo-unlock.sh, poi:"
echo "git add -A && git commit -m 'debug temporaneo brevo su sblocco' && git push"
echo ""
echo "Dopo il push, rifai il test da zero (incognito nuovo, email inventata,"
echo "sblocco libro) e questa volta il messaggio a schermo dopo lo sblocco"
echo "mostrerà tra parentesi quadre il motivo esatto se qualcosa fallisce."
echo "Mandami uno screenshot di quel messaggio."
