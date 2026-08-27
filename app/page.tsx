import { cookies } from "next/headers";
import Link from "next/link";
import Image from "next/image";
import { Fish, Waves, CloudSun, Anchor, CalendarDays, BookOpen, Newspaper, KeyRound } from "lucide-react";
import { BOOKS } from "@/lib/books";
import IOSInstallBanner from "@/components/IOSInstallBanner";
import AndroidInstallBanner from "@/components/AndroidInstallBanner";

const COVERS: Record<string, string> = {
  feeder: "/covers/feeder.jpg",
  "mare-e-foce": "/covers/mare-e-foce.jpg",
  "senso-acqua": "/covers/senso-acqua.jpg",
};

const STRUMENTI = [
  { href: "/maree", Icon: Waves, label: "Maree e Luna" },
  { href: "/meteo", Icon: CloudSun, label: "Meteo" },
  { href: "/lenze", Icon: Anchor, label: "Le mie Lenze" },
  { href: "/specie", Icon: CalendarDays, label: "Specie e Periodi" },
  { href: "/diario", Icon: BookOpen, label: "Diario di Pesca" },
  { href: "/articoli", Icon: Newspaper, label: "Articoli e Blog" },
];

export default async function Home() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md">
        {/* Intestazione */}
        <div className="px-5 pt-6 pb-5 text-center">
          <Fish size={26} strokeWidth={1.5} className="mx-auto mb-2 text-[#F6F5F1]" />
          <h1
            className="text-[19px] tracking-wide"
            style={{ fontFamily: "var(--font-fraunces)", fontWeight: 600 }}
          >
            LIBRI DI PESCA
          </h1>
          <p className="text-[11px] text-[#8FA8B2] uppercase tracking-[0.12em] mt-0.5">
            La tua compagna di pesca
          </p>
        </div>

        <div className="px-5">
          {/* I miei libri */}
          <div className="flex items-center justify-between mb-2.5">
            <h2 className="text-[13px] uppercase tracking-[0.08em] text-[#8FA8B2] font-medium">
              I miei libri
            </h2>
            <Link href="/diario" className="text-[12px] text-[#2CA6A4]">
              Vedi tutti
            </Link>
          </div>

          <div className="flex gap-2.5 overflow-x-auto pb-1 mb-6 -mx-5 px-5">
            {books.map((book) => (
              <Link
                key={book.id}
                href={`/diario/${book.id}`}
                className="relative flex-shrink-0 w-28 rounded-lg overflow-hidden border border-white/10"
              >
                <div className="relative w-28 h-40">
                  <Image
                    src={COVERS[book.id]}
                    alt={book.name}
                    fill
                    sizes="112px"
                    className={`object-cover ${!book.unlocked ? "opacity-50" : ""}`}
                  />
                </div>
                <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent px-2 pt-4 pb-2">
                  <span
                    className={`text-[9.5px] px-1.5 py-0.5 rounded-full font-mono ${
                      book.unlocked ? "bg-[#7CB342]/30 text-[#B7E28C]" : "bg-white/15 text-[#F6F5F1]"
                    }`}
                  >
                    {book.unlocked ? "✓ Sbloccato" : "🔒 Bloccato"}
                  </span>
                </div>
              </Link>
            ))}
          </div>

          {/* Strumenti rapidi */}
          <h2 className="text-[13px] uppercase tracking-[0.08em] text-[#8FA8B2] font-medium mb-2.5">
            Strumenti rapidi
          </h2>
          <div className="grid grid-cols-2 gap-2.5 mb-6">
            {STRUMENTI.map(({ href, Icon, label }) => (
              <Link
                key={href}
                href={href}
                className="flex flex-col items-center justify-center gap-2 bg-[#124E5A] border border-white/10 rounded-xl py-4"
              >
                <Icon size={22} strokeWidth={1.6} className="text-[#2CA6A4]" />
                <span className="text-[11.5px] text-[#F6F5F1] text-center leading-tight px-1">{label}</span>
              </Link>
            ))}
          </div>

          <Link
            href="/sblocca"
            className="flex items-center justify-center gap-2 border border-dashed border-white/20 rounded-xl py-3 text-sm text-[#2CA6A4] font-medium mb-4"
          >
            <KeyRound size={15} strokeWidth={2} />
            Hai un codice? Sbloccalo qui
          </Link>
        </div>
      </div>
      <IOSInstallBanner />
      <AndroidInstallBanner />
    </main>
  );
}

