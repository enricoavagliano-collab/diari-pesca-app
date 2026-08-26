import { cookies } from "next/headers";
import Link from "next/link";
import Image from "next/image";
import { BOOKS } from "@/lib/books";

const COVERS: Record<string, string> = {
  feeder: "/covers/feeder.jpg",
  "mare-e-foce": "/covers/mare-e-foce.jpg",
  "senso-acqua": "/covers/senso-acqua.jpg",
};

export default async function DiarioIndexPage() {
  const cookieStore = await cookies();

  const books = Object.values(BOOKS).map((book) => ({
    ...book,
    unlocked: cookieStore.get(`unlock_${book.id}`)?.value === "1",
  }));

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <h1 className="text-[22px] mb-1" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          I tuoi libri
        </h1>
        <p className="text-[13px] text-[#8FA8B2] mb-5">
          Contenuti sbloccati con il QR nella prima pagina della tua copia
        </p>

        <div className="space-y-3">
          {books.map((book) => (
            <Link
              key={book.id}
              href={`/diario/${book.id}`}
              className="relative flex items-center gap-3 rounded-xl overflow-hidden border border-white/10 bg-[#124E5A]"
            >
              <div className="relative w-20 h-28 flex-shrink-0">
                <Image
                  src={COVERS[book.id]}
                  alt={book.name}
                  fill
                  sizes="80px"
                  className={`object-cover ${!book.unlocked ? "opacity-60" : ""}`}
                />
              </div>
              <div className="flex-1 py-3 pr-3">
                <h3 className="text-[15px] font-medium">{book.name}</h3>
                <span
                  className={`inline-block mt-1.5 text-[10px] px-2 py-0.5 rounded-full font-mono ${
                    book.unlocked ? "bg-[#7CB342]/20 text-[#9FD16A]" : "bg-white/10 text-[#8FA8B2]"
                  }`}
                >
                  {book.unlocked ? "✓ Sbloccato" : "🔒 Bloccato"}
                </span>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}

