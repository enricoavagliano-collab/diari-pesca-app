import { cookies } from "next/headers";
import Link from "next/link";
import { BOOKS } from "@/lib/books";
import IOSInstallBanner from "@/components/IOSInstallBanner";

export default async function Home() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5">
        <div className="bg-[#0F2D3D] text-[#F6F5F1] rounded-xl p-5 mb-5">
          <p className="text-[10px] uppercase tracking-widest text-[#D98E4A] mb-1">
            Diari di Pesca
          </p>
          <h1 className="text-xl font-medium">Il tuo hub di lettura</h1>
        </div>

        <p className="text-[11px] uppercase tracking-widest text-[#6B7E82] mb-2">
          I tuoi libri
        </p>

        <div className="space-y-3">
          {books.map((book) => (
            <Link
              key={book.id}
              href={`/diario/${book.id}`}
              className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3"
            >
              <div className="w-11 h-15 rounded bg-[#2C6E71] text-white flex items-center justify-center text-sm font-medium flex-shrink-0">
                {book.name.slice(0, 2).toUpperCase()}
              </div>
              <div className="flex-1">
                <h3 className="font-medium text-sm">{book.name}</h3>
                <p className="text-xs text-[#6B7E82]">
                  {book.unlocked ? "Contenuti disponibili" : "Da sbloccare col QR"}
                </p>
              </div>
              <span
                className={`text-[10px] px-2 py-1 rounded-full font-mono ${
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

        <p className="text-[11px] uppercase tracking-widest text-[#6B7E82] mb-2 mt-6">
          Strumenti — aperti a tutti
        </p>

        <Link
          href="/maree"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🌊
          </div>
          <div>
            <h3 className="font-semibold text-sm">Maree e luna</h3>
            <p className="text-xs text-[#6B7E82]">Qualunque località, oggi o nei prossimi giorni</p>
          </div>
        </Link>

        <Link
          href="/lenze"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🎣
          </div>
          <div>
            <h3 className="font-semibold text-sm">Le mie lenze</h3>
            <p className="text-xs text-[#6B7E82]">Con Mare e Foce o Diario Feeder</p>
          </div>
        </Link>

        <Link
          href="/meteo"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🌬️
          </div>
          <div>
            <h3 className="font-semibold text-sm">Meteo</h3>
            <p className="text-xs text-[#6B7E82]">Vento, pressione, condizioni</p>
          </div>
        </Link>

        <Link
          href="/specie"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            🐟
          </div>
          <div>
            <h3 className="font-semibold text-sm">Specie e periodi</h3>
            <p className="text-xs text-[#6B7E82]">Mare/Foce e Acqua dolce, mese per mese</p>
          </div>
        </Link>

        <Link
          href="/sblocca"
          className="mt-6 flex items-center justify-center gap-2 border border-dashed border-[#E1DFD6] rounded-xl py-3 text-sm text-[#2C6E71] font-medium"
        >
          🔑 Hai un codice? Sbloccalo qui
        </Link>
      </div>
      <IOSInstallBanner />
    </main>
  );
}

