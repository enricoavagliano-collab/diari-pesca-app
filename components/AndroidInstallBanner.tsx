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
