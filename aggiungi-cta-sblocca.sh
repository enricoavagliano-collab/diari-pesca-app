#!/bin/bash
set -e

echo "=== Aggiungo pulsante 'Inserisci il codice' nella schermata bloccata ==="

python3 << 'PYEOF'
import re

path = "app/diario/[bookId]/page.tsx"
with open(path, "r") as f:
    content = f.read()

old = '''          <p className="text-sm text-[#8FA8B2] mb-6">
            Inquadra il QR nella prima pagina della tua copia per sbloccare i contenuti.
          </p>
          <Link href="/" className="text-sm text-[#2CA6A4] underline">'''

new = '''          <p className="text-sm text-[#8FA8B2] mb-6">
            Inquadra il QR nella prima pagina della tua copia, oppure inserisci
            manualmente il codice di sblocco per accedere ai contenuti.
          </p>
          <Link
            href="/sblocca"
            className="inline-block bg-[#2CA6A4] rounded-lg px-5 py-2.5 text-sm font-medium mb-4"
          >
            Inserisci il codice del libro
          </Link>
          <br />
          <Link href="/" className="text-sm text-[#2CA6A4] underline">'''

if old not in content:
    raise SystemExit("Blocco atteso non trovato: controlla se il file è già stato modificato in precedenza.")

content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Modifica applicata con successo.")
PYEOF

echo "=== File modificato: app/diario/[bookId]/page.tsx ==="
echo ""
echo "Ricorda: bash aggiungi-cta-sblocca.sh, poi:"
echo "git add -A && git commit -m 'aggiunge link diretto a sblocco manuale codice' && git push"
