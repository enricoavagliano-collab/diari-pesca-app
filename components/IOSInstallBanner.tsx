"use client";

import { useEffect, useState } from "react";

const DISMISS_KEY = "ios_install_banner_dismissed";

export default function IOSInstallBanner() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const isIOS = /iPad|iPhone|iPod/.test(window.navigator.userAgent);
    // @ts-expect-error: 'standalone' esiste solo su Safari iOS, non nel tipo standard di Navigator
    const isStandalone = window.navigator.standalone === true;
    const dismissed = localStorage.getItem(DISMISS_KEY) === "1";

    if (isIOS && !isStandalone && !dismissed) {
      setShow(true);
    }
  }, []);

  function dismiss() {
    localStorage.setItem(DISMISS_KEY, "1");
    setShow(false);
  }

  if (!show) return null;

  return (
    <div className="fixed bottom-4 left-4 right-4 max-w-md mx-auto bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-4 shadow-lg z-50 flex items-start gap-3">
      <span className="text-xl flex-shrink-0">📲</span>
      <div className="flex-1 text-[12.5px] leading-relaxed">
        <strong>Aggiungi questa app alla tua Home:</strong> tocca l&apos;icona Condividi{" "}
        <span aria-hidden>⬆️</span> qui sotto, poi &quot;Aggiungi a Home&quot;.
      </div>
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

