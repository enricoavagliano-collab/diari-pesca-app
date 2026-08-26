"use client";

import { useState } from "react";
import Link from "next/link";
import { Trash2 } from "lucide-react";

export default function ImpostazioniPage() {
  const [cleared, setCleared] = useState(false);

  function clearSavedLocations() {
    localStorage.removeItem("maree_locations");
    localStorage.removeItem("meteo_locations");
    setCleared(true);
    setTimeout(() => setCleared(false), 2000);
  }

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <Link href="/altro" className="text-xs text-[#8FA8B2]">
          ← Altro
        </Link>
        <h1 className="text-[22px] mt-2 mb-5" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Impostazioni
        </h1>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
          <h3 className="text-sm font-semibold mb-1">Località salvate</h3>
          <p className="text-[12.5px] text-[#8FA8B2] mb-3 leading-relaxed">
            Le località che hai cercato in Maree e Meteo restano salvate solo su questo
            dispositivo. Puoi cancellarle in ogni momento.
          </p>
          <button
            onClick={clearSavedLocations}
            className="flex items-center gap-2 text-sm text-[#FF9A3C] font-medium"
          >
            <Trash2 size={15} />
            {cleared ? "Cancellate ✓" : "Cancella località salvate"}
          </button>
        </div>

        <p className="text-[11px] text-[#8FA8B2] mt-6 leading-relaxed px-1">
          ⓘ L&apos;app non richiede un account: i tuoi dati (diario, lenze salvate,
          sblocchi) restano legati a questo dispositivo/browser specifico.
        </p>
      </div>
    </main>
  );
}

