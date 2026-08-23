import { cookies } from "next/headers";
import Link from "next/link";
import { BOOKS, BookId } from "@/lib/books";
import { DIARIO_TEMPLATES } from "@/lib/diario-templates";
import DiarioForm from "@/components/DiarioForm";

// Link Drive reali forniti da Enrico + argomenti dei 4 PDF per libro
const PDF_FOLDERS: Record<string, { link: string; topics: string }> = {
  feeder: {
    link: "https://drive.google.com/drive/folders/1x3cVL9F61G6g7b6Q3gmwp7dLVxY9AZfV",
    topics: "Feeder generale, Pasturazione, Attrezzatura, Lenze Feeder",
  },
  "mare-e-foce": {
    link: "https://drive.google.com/drive/folders/1Q2wTAyLYlg0hmYlo9l-H-1ZRWANmzS5a",
    topics: "Mare e Foce, Maree, Luna, Lenze",
  },
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
      <main className="min-h-screen flex items-center justify-center bg-[#F6F5F1]">
        <p className="text-[#6B7E82]">Libro non trovato.</p>
      </main>
    );
  }

  if (!unlocked) {
    return (
      <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
        <div className="w-full max-w-md p-5 text-center pt-20">
          <div className="text-4xl mb-4">🔒</div>
          <h1 className="text-lg font-medium mb-2">{book.name}</h1>
          <p className="text-sm text-[#6B7E82] mb-6">
            Inquadra il QR nella prima pagina della tua copia per sbloccare i contenuti.
          </p>
          <Link href="/" className="text-sm text-[#2C6E71] underline">
            ← Torna alla home
          </Link>
        </div>
      </main>
    );
  }

  const template = DIARIO_TEMPLATES[bookId as "feeder" | "mare-e-foce"];
  const pdf = PDF_FOLDERS[bookId];

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "Georgia, serif" }}>
          {book.name}
        </h1>

        <a
          href={pdf.link}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-3 bg-[#0F2D3D] text-white rounded-xl p-3.5 mb-5"
        >
          <div className="w-10 h-10 rounded-lg bg-[#D98E4A] text-[#0F2D3D] flex items-center justify-center text-lg flex-shrink-0">
            📁
          </div>
          <div className="flex-1">
            <h3 className="text-sm font-semibold">I tuoi 4 PDF — {book.name}</h3>
            <p className="text-[11px] text-[#a9bcc2]">{pdf.topics}</p>
          </div>
          <span className="text-[11px] bg-[#2C6E71] px-2.5 py-1.5 rounded-md flex-shrink-0">
            Apri
          </span>
        </a>

        <DiarioForm bookId={bookId as BookId} template={template} />
      </div>
    </main>
  );
}

