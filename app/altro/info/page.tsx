import Link from "next/link";
import { Fish } from "lucide-react";

export default function InfoPage() {
  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <Link href="/altro" className="text-xs text-[#8FA8B2]">
          ← Altro
        </Link>

        <div className="text-center mt-6 mb-8">
          <Fish size={32} strokeWidth={1.5} className="mx-auto mb-3 text-[#2CA6A4]" />
          <h1 className="text-[20px]" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 600 }}>
            Libri di Pesca
          </h1>
          <p className="text-[12px] text-[#8FA8B2] mt-1">Tutta la pesca a portata di click</p>
        </div>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4 mb-3">
          <p className="text-[13px] text-[#F6F5F1] leading-relaxed">
            L&apos;app companion dei libri di pesca di Enrico Avagliano — diario digitale,
            maree, meteo, lenze e specie, tutto in un unico posto.
          </p>
        </div>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
          <h3 className="text-sm font-semibold mb-1.5">Un progetto di</h3>
          <a
            href="https://enricoavagliano.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-[#2CA6A4] underline"
          >
            Enrico Avagliano
          </a>
          <p className="text-[12px] text-[#8FA8B2] mt-1">La pesca a portata di click</p>
        </div>
      </div>
    </main>
  );
}

