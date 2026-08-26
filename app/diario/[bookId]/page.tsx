import { cookies } from "next/headers";
import Link from "next/link";
import Image from "next/image";
import { FileText } from "lucide-react";
import { BOOKS, BookId } from "@/lib/books";
import { DIARIO_TEMPLATES } from "@/lib/diario-templates";
import DiarioForm from "@/components/DiarioForm";

// Link Drive reali forniti da Enrico + argomenti dei 4 PDF per libro
const PDF_FOLDERS: Record<string, { link: string; topics: string[] }> = {
  feeder: {
    link: "https://drive.google.com/drive/folders/1x3cVL9F61G6g7b6Q3gmwp7dLVxY9AZfV",
    topics: ["Feeder generale", "Pasturazione", "Attrezzatura", "Lenze Feeder"],
  },
  "mare-e-foce": {
    link: "https://drive.google.com/drive/folders/1Q2wTAyLYlg0hmYlo9l-H-1ZRWANmzS5a",
    topics: ["Mare e Foce", "Maree", "Luna", "Lenze"],
  },
};

const COVERS: Record<string, string> = {
  feeder: "/covers/feeder.jpg",
  "mare-e-foce": "/covers/mare-e-foce.jpg",
  "senso-acqua": "/covers/senso-acqua.jpg",
};

export default async function DiarioBookPage({
  params,
}: {
  params: Promise<{ bookId: string }>;
}) {
  const { bookId } = await params;
  const book = BOOKS[bookId as BookId];
  const cookieStore = await cookies();
  const unlocked = cookieStore.get(`unlock_${bookId}`)?.value === "1";

  if (!book || !(bookId in DIARIO_TEMPLATES)) {
    return (
      <main className="min-h-screen flex items-center justify-center bg-[#0B1F2A]">
        <p className="text-[#8FA8B2]">Libro non trovato.</p>
      </main>
    );
  }

  if (!unlocked) {
    return (
      <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
        <div className="w-full max-w-md p-5 pb-24 text-center pt-20">
          <div className="text-4xl mb-4">🔒</div>
          <h1 className="text-lg font-medium mb-2">{book.name}</h1>
          <p className="text-sm text-[#8FA8B2] mb-6">
            Inquadra il QR nella prima pagina della tua copia per sbloccare i contenuti.
          </p>
          <Link href="/" className="text-sm text-[#2CA6A4] underline">
            ← Torna alla home
          </Link>
        </div>
      </main>
    );
  }

  const template = DIARIO_TEMPLATES[bookId as "feeder" | "mare-e-foce"];
  const pdf = PDF_FOLDERS[bookId];

  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/diario" className="text-xs text-[#8FA8B2]">
          ← Diario
        </Link>

        <div className="flex items-center gap-3 mt-2 mb-5">
          <div className="relative w-14 h-20 rounded-md overflow-hidden flex-shrink-0 border border-white/10">
            <Image src={COVERS[bookId]} alt={book.name} fill sizes="56px" className="object-cover" />
          </div>
          <div>
            <h1 className="text-[19px]" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
              {book.name}
            </h1>
            <span className="inline-block mt-1 text-[10px] px-2 py-0.5 rounded-full font-mono bg-[#7CB342]/20 text-[#9FD16A]">
              ✓ Sbloccato
            </span>
          </div>
        </div>

        <h2 className="text-[11px] uppercase tracking-[0.08em] text-[#8FA8B2] font-medium mb-2.5">
          PDF inclusi
        </h2>
        <div className="grid grid-cols-2 gap-2.5 mb-6">
          {pdf.topics.map((topic) => (
            <a
              key={topic}
              href={pdf.link}
              target="_blank"
              rel="noopener noreferrer"
              className="bg-[#124E5A] border border-white/10 rounded-xl p-3 flex flex-col gap-2"
            >
              <div className="w-8 h-8 rounded-md bg-[#0B1F2A] flex items-center justify-center">
                <FileText size={15} strokeWidth={1.75} className="text-[#FF9A3C]" />
              </div>
              <span className="text-[12.5px] leading-snug">{topic}</span>
              <span className="text-[10px] text-[#2CA6A4]">Apri →</span>
            </a>
          ))}
        </div>

        <DiarioForm bookId={bookId as BookId} template={template} />
      </div>
    </main>
  );
}

