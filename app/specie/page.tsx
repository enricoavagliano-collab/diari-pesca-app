"use client";

import { useState } from "react";
import Link from "next/link";
import { getSpecieByCategory, MONTH_LABELS, RATING_LABELS, SpecieCategory, Rating } from "@/lib/specie";

function ratingColor(r: Rating): string {
  if (r === 3) return "bg-[#2C6E71] text-white";
  if (r === 2) return "bg-[#D98E4A]/25 text-[#8a5a26]";
  return "bg-[#eeece3] text-[#6B7E82]";
}

export default function SpeciePage() {
  const [category, setCategory] = useState<SpecieCategory>("mare");
  const specieList = getSpecieByCategory(category);

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
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
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            🌊 Mare / Foce
          </button>
          <button
            onClick={() => setCategory("dolce")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border ${
              category === "dolce"
                ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            💧 Acqua dolce
          </button>
        </div>

        <div className="flex items-center gap-3 mb-4 text-[10.5px] text-[#6B7E82]">
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#eeece3] inline-block"></span> Non buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#D98E4A]/25 inline-block"></span> Buono
          </span>
          <span className="flex items-center gap-1">
            <span className="w-3 h-3 rounded-sm bg-[#2C6E71] inline-block"></span> Ottimo
          </span>
        </div>

        <div className="space-y-4">
          {specieList.map((specie) => (
            <div key={specie.name} className="bg-white border border-[#E1DFD6] rounded-xl p-4">
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
                    <div className="text-[9.5px] text-[#6B7E82] mt-1">{MONTH_LABELS[i]}</div>
                  </div>
                ))}
              </div>
              <p className="text-[12px] text-[#6B7E82] italic leading-relaxed pt-2.5 border-t border-[#E1DFD6]">
                {specie.note}
              </p>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}

