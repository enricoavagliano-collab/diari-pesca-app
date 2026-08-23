#!/bin/bash
set -e
echo 'Correggo app/globals.css...'
cat > "app/globals.css" << 'SETUP_EOF_MARKER'
@import "tailwindcss";

/* Colori fissi del brand: l'app ha sempre lo stesso aspetto,
   indipendentemente dalla modalità chiara/scura del dispositivo. */
:root {
  --background: #F6F5F1;
  --foreground: #16232B;
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
}

body {
  background: var(--background);
  color: var(--foreground);
  font-family: Arial, Helvetica, sans-serif;
}

input,
textarea {
  color: var(--foreground);
}

input::placeholder,
textarea::placeholder {
  color: #6B7E82;
}
SETUP_EOF_MARKER
echo '✓ Corretto: il testo ora è sempre leggibile, anche in modalità scura.'
