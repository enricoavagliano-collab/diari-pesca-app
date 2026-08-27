#!/bin/bash
set -e

echo "=== Rendo il banner Android più grande e in alto ==="

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
    <div className="fixed top-0 left-0 right-0 z-50 bg-[#0F2D3D] text-[#F6F5F1] shadow-lg border-b border-white/10">
      <div className="max-w-md mx-auto p-4 flex items-center gap-3">
        <span className="text-3xl flex-shrink-0">📲</span>
        <div className="flex-1">
          <p className="text-[15px] font-medium leading-snug">
            Installa l&apos;app
          </p>
          <p className="text-[12.5px] text-[#B7C7CC] leading-snug">
            Accesso più veloce, direttamente dalla tua Home.
          </p>
        </div>
        <button
          onClick={dismiss}
          aria-label="Chiudi"
          className="text-[#a9bcc2] text-xl leading-none flex-shrink-0 self-start"
        >
          ×
        </button>
      </div>
      <div className="max-w-md mx-auto px-4 pb-4">
        <button
          onClick={install}
          className="w-full bg-[#2CA6A4] rounded-lg py-3 text-[15px] font-semibold"
        >
          Installa ora
        </button>
      </div>
    </div>
  );
}
EOF

echo "=== File aggiornato: components/AndroidInstallBanner.tsx ==="
echo ""
echo "Ricorda: bash banner-android-grande.sh, poi:"
echo "git add -A && git commit -m 'banner Android piu grande e in alto' && git push"
