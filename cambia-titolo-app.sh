#!/bin/bash
# Cambia SOLO il titolo mostrato del libro nell'app (non tocca codici, cookie o dati).
set -e
python3 - <<'PY'
NEW_H = "Pesca a bolognese e all'inglese"
NEW_E = "Pesca a bolognese e all&apos;inglese"
changes = {
 "lib/books.ts": [("name: \"Il senso dell'acqua\"", "name: \"" + NEW_H + "\"")],
 "app/lenze/LenzeClient.tsx": [
   ("Il senso dell'acqua (a breve online)", NEW_H + " (a breve online)"),
   ("de Il senso dell'acqua", NEW_H),
   ("Il senso dell&apos;acqua (a breve online)", NEW_E + " (a breve online)"),
   ("Il senso dell&apos;acqua", NEW_E),
 ],
}
for path, pairs in changes.items():
    s = open(path, encoding="utf-8").read()
    n = 0
    for a, b in pairs:
        n += s.count(a)
        s = s.replace(a, b)
    open(path, "w", encoding="utf-8").write(s)
    print(f"{path}: {n} sostituzioni")
PY
echo "Fatto. Controllo che non resti il vecchio titolo:"
grep -rn "senso dell" app lib components || echo "nessun vecchio titolo rimasto"
