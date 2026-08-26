"use client";

import { useState } from "react";
import Link from "next/link";
import { Fish, Waves, Droplets } from "lucide-react";
import { getSpecieByCategory, MONTH_LABELS, RATING_LABELS, SpecieCategory, Rating } from "@/lib/specie";

function ratingColor(r: Rating): string {
  if (r === 3) return "bg-[#2CA6A4]";
  if (r === 2) return "bg-[#FF9A3C]";
  return "bg-white/10";
}

export default function SpeciePage() {
  const [category, setCategory] = useState<SpecieCategory>("mare");
  const specieList = getSpecieByCategory(category);

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Specie e periodi
        </h1>

        <div className="flex gap-1.5 mb-5">
          <button
            onClick={() => setCategory("mare")}
            className={`flex items-center gap-1.5 text-[12.5px] font-medium px-3 py-1.5 rounded-full border ${
              category === "mare"
                ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            <Waves size={14} strokeWidth={2} /> Mare / Foce
          </button>
          <button
            onClick={() => setCategory("dolce")}
            className={`flex items-center gap-1.5 text-[12.5px] font-medium px-3 py-1.5 rounded-full border ${
              category === "dolce"
                ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            <Droplets size={14} strokeWidth={2} /> Acqua dolce
          </button>
        </div>

        <div className="flex items-center gap-2.5 mb-5 text-[10.5px] text-[#8FA8B2]">
          <span className="flex items-center gap-1.5 bg-[#124E5A] border border-white/10 rounded-full px-2.5 py-1">
            <span className="w-2.5 h-2.5 rounded-sm bg-white/10 inline-block"></span> Non buono
          </span>
          <span className="flex items-center gap-1.5 bg-[#124E5A] border border-white/10 rounded-full px-2.5 py-1">
            <span className="w-2.5 h-2.5 rounded-sm bg-[#FF9A3C] inline-block"></span> Buono
          </span>
          <span className="flex items-center gap-1.5 bg-[#124E5A] border border-white/10 rounded-full px-2.5 py-1">
            <span className="w-2.5 h-2.5 rounded-sm bg-[#2CA6A4] inline-block"></span> Ottimo
          </span>
        </div>

        <div className="space-y-3">
          {specieList.map((specie) => (
            <div key={specie.name} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
              <div className="flex items-start gap-3 mb-3">
                <div className="w-11 h-11 rounded-lg bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                  <Fish size={20} strokeWidth={1.5} className="text-[#2CA6A4]" />
                </div>
                <div>
                  <h3 className="text-[16px]" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
                    {specie.name}
                  </h3>
                  <p className="text-[11px] text-[#8FA8B2] italic">{specie.scientificName}</p>
                </div>
              </div>

              {[specie.months.slice(0, 6), specie.months.slice(6, 12)].map((half, rowIdx) => (
                <div key={rowIdx} className="grid grid-cols-6 gap-1.5 mb-1.5">
                  {half.map((rating, i) => {
                    const monthIdx = rowIdx * 6 + i;
                    return (
                      <div key={monthIdx} className="text-center">
                        <div
                          className={`rounded-md h-6 ${ratingColor(rating)}`}
                          title={RATING_LABELS[rating]}
                        />
                        <div className="text-[9px] text-[#8FA8B2] mt-1">{MONTH_LABELS[monthIdx]}</div>
                      </div>
                    );
                  })}
                </div>
              ))}

              <p className="text-[12px] text-[#8FA8B2] italic leading-relaxed pt-2.5 mt-1.5 border-t border-white/10">
                {specie.note}
              </p>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}

