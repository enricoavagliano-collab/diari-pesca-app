import { cookies } from "next/headers";
import Link from "next/link";
import { Waves, Anchor, Wind, CalendarDays, Newspaper, KeyRound } from "lucide-react";
import { BOOKS } from "@/lib/books";
import IOSInstallBanner from "@/components/IOSInstallBanner";

const TOOLS = [
  {
    href: "/maree",
    Icon: Waves,
    title: "Maree e luna",
    subtitle: "Qualunque località, oggi o nei prossimi giorni",
  },
  {
    href: "/lenze",
    Icon: Anchor,
    title: "Le mie lenze",
    subtitle: "Con Mare e Foce o Diario Feeder",
  },
  {
    href: "/meteo",
    Icon: Wind,
    title: "Meteo",
    subtitle: "Vento, pressione, condizioni",
  },
  {
    href: "/specie",
    Icon: CalendarDays,
    title: "Specie e periodi",
    subtitle: "Mare/Foce e Acqua dolce, mese per mese",
  },
  {
    href: "/articoli",
    Icon: Newspaper,
    title: "Articoli",
    subtitle: "Tutti i contenuti tecnici dal blog",
  },
];

export default async function Home() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md pb-16">
        {/* Intestazione + linea di marea (elemento firma) */}
        <div className="bg-[#0F2D3D] text-[#F6F5F1] px-5 pt-6 pb-7">
          <p className="text-[10px] uppercase tracking-[0.15em] text-[#D98E4A] mb-1.5 font-medium">
            Libri di Pesca
          </p>
          <h1
            className="text-[22px] leading-snug"
            style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}
          >
            Tutta la pesca a portata di click
          </h1>
        </div>
        <svg
          className="w-full block -mt-px"
          viewBox="0 0 400 20"
          preserveAspectRatio="none"
          style={{ height: 18 }}
        >
          <path
            d="M0,10 C33,3 67,17 100,10 C133,3 167,17 200,10 C233,3 267,17 300,10 C333,3 367,17 400,10 L400,20 L0,20 Z"
            fill="#0F2D3D"
          />
        </svg>

        <div className="p-5 pt-4">
          <p className="text-[11px] uppercase tracking-[0.1em] text-[#6B7E82] mb-2.5 font-medium">
            I tuoi libri
          </p>

          <div className="space-y-2.5">
            {books.map((book) => (
              <Link
                key={book.id}
                href={`/diario/${book.id}`}
                className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 shadow-[0_1px_2px_rgba(15,45,61,0.04)] transition-transform active:scale-[0.98]"
              >
                <div
                  className="w-11 h-14 rounded-md bg-[#2C6E71] text-white flex items-center justify-center text-sm flex-shrink-0"
                  style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}
                >
                  {book.name.slice(0, 2).toUpperCase()}
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-sm">{book.name}</h3>
                  <p className="text-xs text-[#6B7E82]">
                    {book.unlocked ? "Contenuti disponibili" : "Da sbloccare col QR"}
                  </p>
                </div>
                <span
                  className={`text-[10px] px-2 py-1 rounded-full font-mono flex-shrink-0 ${
                    book.unlocked
                      ? "bg-[#e6f0ef] text-[#2C6E71]"
                      : "bg-[#f0eee6] text-[#6B7E82]"
                  }`}
                >
                  {book.unlocked ? "Sbloccato" : "🔒 QR"}
                </span>
              </Link>
            ))}
          </div>

          <p className="text-[11px] uppercase tracking-[0.1em] text-[#6B7E82] mb-2.5 mt-6 font-medium">
            Strumenti — aperti a tutti
          </p>

          <div className="space-y-2.5">
            {TOOLS.map(({ href, Icon, title, subtitle }) => (
              <Link
                key={href}
                href={href}
                className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 shadow-[0_1px_2px_rgba(15,45,61,0.04)] transition-transform active:scale-[0.98]"
              >
                <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center flex-shrink-0">
                  <Icon size={18} strokeWidth={1.75} className="text-[#2C6E71]" />
                </div>
                <div>
                  <h3 className="font-semibold text-sm">{title}</h3>
                  <p className="text-xs text-[#6B7E82]">{subtitle}</p>
                </div>
              </Link>
            ))}
          </div>

          <Link
            href="/sblocca"
            className="mt-6 flex items-center justify-center gap-2 border border-dashed border-[#E1DFD6] rounded-xl py-3 text-sm text-[#2C6E71] font-medium"
          >
            <KeyRound size={15} strokeWidth={2} />
            Hai un codice? Sbloccalo qui
          </Link>
        </div>
      </div>
      <IOSInstallBanner />
    </main>
  );
}

