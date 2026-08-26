"use client";

import { useState } from "react";
import Link from "next/link";
import { getSpecieByCategory, MONTH_LABELS, RATING_LABELS, SpecieCategory, Rating } from "@/lib/specie";

function ratingColor(r: Rating): string {
  if (r === 3) return "bg-[#2CA6A4] text-white";
  if (r === 2) return "bg-[#FF9A3C]/25 text-[#FFC98A]";
  return "bg-[#0B1F2A] text-[#8FA8B2]";
}

export default function SpeciePage() {
  const [category, setCategory] = useState<SpecieCategory>("mare");
  const specieList = getSpecieByCategory(category);

  return (
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Specie e periodi migliori
        </h1>

        <div className="flex gap-1.5 mb-5">
          <button
            onClick={() => setCategory("mare")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "mare"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🌊 Mare / Foce
          </button>
          <button
            onClick={() => setCategory("dolce")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "dolce"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            💧 Acqua dolce
          </button>
        </div>

        <div className="flex items-center gap-3 mb-4 text-[10.5px] text-[#8FA8B2]">
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#0B1F2A] inline-block"></span> Non buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#FF9A3C]/25 inline-block"></span> Buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#2CA6A4] inline-block"></span> Ottimo
          </span>
        </div>

        <div className="space-y-4">
          {specieList.map((specie) => (
            <div key={specie.name} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
              <h3 className="font-medium text-[16px] mb-3" style={{ fontFamily: "var(--font-fraunces)" }}>
                {specie.name}
              </h3>
              <div className="grid grid-cols-6 gap-1.5 mb-3">
                {specie.months.map((rating, i) => (
                  <div key={i} className="text-center">
                    <div
                      className={`rounded-md py-2 text-[13px] font-semibold ${ratingColor(rating)}`}
                      title={RATING_LABELS[rating]}
                    >
                      {"🐟".repeat(rating)}
                    </div>
                    <div className="text-[9.5px] text-[#8FA8B2] mt-1">{MONTH_LABELS[i]}</div>
                  </div>
                ))}
              </div>
              <p className="text-[12px] text-[#8FA8B2] italic leading-relaxed pt-2.5 border-t border-white/10">
                {specie.note}
              </p>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}

