#!/bin/bash
set -e

echo "=== Aggiungo il banner di installazione per Android ==="

mkdir -p components

cat > components/AndroidInstallBanner.tsx << 'EOF'
"use client";

import { useEffect, useState } from "react";

const DISMISS_KEY = "android_install_banner_dismissed";

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

export default function AndroidInstallBanner() {
  const [deferredPrompt, setDeferredPrompt] =
    useState<BeforeInstallPromptEvent | null>(null);
  const [show, setShow] = useState(false);

  useEffect(() => {
    const dismissed = localStorage.getItem(DISMISS_KEY) === "1";
    if (dismissed) return;

    function handler(e: Event) {
      // Impedisce il mini-banner nativo del browser: mostriamo il nostro,
      // coerente con lo stile del resto dell'app.
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      setShow(true);
    }

    window.addEventListener("beforeinstallprompt", handler);
    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  async function install() {
    if (!deferredPrompt) return;
    await deferredPrompt.prompt();
    await deferredPrompt.userChoice;
    setShow(false);
    setDeferredPrompt(null);
  }

  function dismiss() {
    localStorage.setItem(DISMISS_KEY, "1");
    setShow(false);
  }

  if (!show) return null;

  return (
    <div className="fixed bottom-4 left-4 right-4 max-w-md mx-auto bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-4 shadow-lg z-50 flex items-center gap-3">
      <span className="text-xl flex-shrink-0">📲</span>
      <div className="flex-1 text-[12.5px] leading-relaxed">
        <strong>Installa l&apos;app</strong> per un accesso più veloce dalla
        tua Home.
      </div>
      <button
        onClick={install}
        className="bg-[#2CA6A4] rounded-lg px-3 py-1.5 text-[12px] font-medium flex-shrink-0"
      >
        Installa
      </button>
      <button
        onClick={dismiss}
        aria-label="Chiudi"
        className="text-[#a9bcc2] text-lg leading-none flex-shrink-0"
      >
        ×
      </button>
    </div>
  );
}
EOF

echo "=== File creato: components/AndroidInstallBanner.tsx ==="

python3 << 'PYEOF'
path = "app/page.tsx"
with open(path, "r") as f:
    content = f.read()

old_import = 'import IOSInstallBanner from "@/components/IOSInstallBanner";'
new_import = (
    'import IOSInstallBanner from "@/components/IOSInstallBanner";\n'
    'import AndroidInstallBanner from "@/components/AndroidInstallBanner";'
)
if old_import not in content:
    raise SystemExit("Import IOSInstallBanner non trovato in app/page.tsx")
content = content.replace(old_import, new_import)

old_render = "      <IOSInstallBanner />"
new_render = "      <IOSInstallBanner />\n      <AndroidInstallBanner />"
if old_render not in content:
    raise SystemExit("Render <IOSInstallBanner /> non trovato in app/page.tsx")
content = content.replace(old_render, new_render)

with open(path, "w") as f:
    f.write(content)

print("app/page.tsx aggiornato correttamente.")
PYEOF

echo ""
echo "=== File modificato: app/page.tsx ==="
echo ""
echo "NOTA IMPORTANTE: il banner Android compare solo se il browser (Chrome)"
echo "considera l'app 'installabile' (manifest.json valido, service worker"
echo "attivo, sito servito in HTTPS - tutte cose già presenti). Chrome può"
echo "comunque decidere di mostrarlo solo dopo un minimo di interazione con"
echo "il sito (non sempre al primissimo secondo di visita), per policy sua"
echo "interna anti-spam banner, non per un bug nostro."
echo ""
echo "Ricorda: bash aggiungi-banner-android.sh, poi:"
echo "git add -A && git commit -m 'aggiunge banner installazione Android' && git push"
