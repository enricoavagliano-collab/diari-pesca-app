#!/bin/bash
set -e
echo 'Creo le cartelle...'
mkdir -p "app"
mkdir -p "app/api/diario"
mkdir -p "app/api/diario/[id]"
mkdir -p "app/api/unlock"
mkdir -p "app/diario/[bookId]"
mkdir -p "app/sblocca"
mkdir -p "components"
mkdir -p "lib"
echo 'Creo i file...'
cat > "package.json" << 'SETUP_EOF_MARKER'
{
  "name": "diari-pesca-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint"
  },
  "dependencies": {
    "next": "16.3.2",
    "postgres": "^3.4.9",
    "react": "19.2.8",
    "react-dom": "19.2.8"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "eslint-config-next": "16.3.2",
    "tailwindcss": "^4",
    "typescript": "^5"
  }
}

SETUP_EOF_MARKER
cat > "tsconfig.json" << 'SETUP_EOF_MARKER'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    ".next/dev/types/**/*.ts",
    "**/*.mts"
  ],
  "exclude": ["node_modules"]
}

SETUP_EOF_MARKER
cat > "next.config.ts" << 'SETUP_EOF_MARKER'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
};

export default nextConfig;

SETUP_EOF_MARKER
cat > "postcss.config.mjs" << 'SETUP_EOF_MARKER'
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;

SETUP_EOF_MARKER
cat > ".gitignore" << 'SETUP_EOF_MARKER'
node_modules/
.next/
.env*.local
.activations.json
.diario-entries.json
*.log

SETUP_EOF_MARKER
cat > ".env.example" << 'SETUP_EOF_MARKER'
# Copia questo file in .env.local e inserisci la stringa del tuo database
# (su Vercel: Storage → il tuo Postgres → tab .env.local, copia da lì)
DATABASE_URL=postgres://user:password@host:5432/dbname

SETUP_EOF_MARKER
cat > "app/layout.tsx" << 'SETUP_EOF_MARKER'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Diari di Pesca",
  description: "Companion app per i libri di Enrico Avagliano",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="it" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}

SETUP_EOF_MARKER
cat > "app/page.tsx" << 'SETUP_EOF_MARKER'
import { cookies } from "next/headers";
import Link from "next/link";
import { BOOKS } from "@/lib/books";

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

        <div className="mt-6 p-3 border border-dashed border-[#E1DFD6] rounded-xl text-xs text-[#6B7E82] leading-relaxed">
          🔧 Per testare: apri{" "}
          <code className="bg-[#eeece3] px-1 rounded">
            /sblocca?codice=FEEDER-2026-DEMO
          </code>{" "}
          per simulare la scansione del QR del Diario Feeder.
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/globals.css" << 'SETUP_EOF_MARKER'
@import "tailwindcss";

:root {
  --background: #ffffff;
  --foreground: #171717;
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);
}

@media (prefers-color-scheme: dark) {
  :root {
    --background: #0a0a0a;
    --foreground: #ededed;
  }
}

body {
  background: var(--background);
  color: var(--foreground);
  font-family: Arial, Helvetica, sans-serif;
}

SETUP_EOF_MARKER
cat > "app/sblocca/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";

function getDeviceId(): string {
  const key = "device_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

function SbloccaContent() {
  const params = useSearchParams();
  const router = useRouter();
  const [status, setStatus] = useState<"loading" | "ok" | "error">("loading");
  const [message, setMessage] = useState("Sto verificando il codice…");
  const [bookName, setBookName] = useState("");

  useEffect(() => {
    const code = params.get("codice");
    if (!code) {
      setStatus("error");
      setMessage("Nessun codice trovato nel link. Riprova a inquadrare il QR nel libro.");
      return;
    }

    const deviceId = getDeviceId();

    fetch("/api/unlock", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ code, deviceId }),
    })
      .then((r) => r.json())
      .then((data) => {
        if (data.ok) {
          setStatus("ok");
          setBookName(data.bookName);
          setMessage(`${data.bookName} sbloccato su questo dispositivo.`);
          setTimeout(() => router.push("/"), 1800);
        } else {
          setStatus("error");
          setMessage(data.error || "Codice non valido.");
        }
      })
      .catch(() => {
        setStatus("error");
        setMessage("Errore di connessione. Riprova.");
      });
  }, [params, router]);

  return (
    <div className="max-w-sm w-full text-center">
      {status === "loading" && <div className="text-4xl mb-4">⏳</div>}
      {status === "ok" && <div className="text-4xl mb-4">✓</div>}
      {status === "error" && <div className="text-4xl mb-4">⚠️</div>}
      <h1 className="text-xl font-medium mb-2">
        {status === "ok" ? bookName : "Sblocco libro"}
      </h1>
      <p className="text-[#a9bcc2] text-sm">{message}</p>
    </div>
  );
}

export default function SbloccaPage() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-[#0F2D3D] text-[#F6F5F1] p-6">
      <Suspense fallback={<div className="text-sm text-[#a9bcc2]">Caricamento…</div>}>
        <SbloccaContent />
      </Suspense>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/diario/[bookId]/page.tsx" << 'SETUP_EOF_MARKER'
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

SETUP_EOF_MARKER
cat > "app/api/unlock/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { findBookByCode } from "@/lib/books";
import { tryActivate } from "@/lib/activations";

export async function POST(req: NextRequest) {
  const { code, deviceId } = await req.json();

  if (!code || !deviceId) {
    return NextResponse.json(
      { ok: false, error: "Dati mancanti." },
      { status: 400 }
    );
  }

  const book = findBookByCode(code);
  if (!book) {
    return NextResponse.json(
      { ok: false, error: "Codice non valido." },
      { status: 404 }
    );
  }

  const result = await tryActivate(book.id, deviceId, book.maxActivations);
  if (!result.ok) {
    return NextResponse.json(
      { ok: false, error: result.reason },
      { status: 403 }
    );
  }

  const res = NextResponse.json({ ok: true, bookId: book.id, bookName: book.name });

  // Cookie di sblocco: 1 anno, leggibile lato client per mostrare lo stato "Sbloccato"
  res.cookies.set(`unlock_${book.id}`, "1", {
    maxAge: 60 * 60 * 24 * 365,
    path: "/",
    sameSite: "lax",
  });

  return res;
}

SETUP_EOF_MARKER
cat > "app/api/diario/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { addEntry, getEntries } from "@/lib/diario-entries";
import { BookId } from "@/lib/books";

export async function POST(req: NextRequest) {
  const { bookId, deviceId, data } = await req.json();

  if (!bookId || !deviceId || !data) {
    return NextResponse.json({ ok: false, error: "Dati mancanti." }, { status: 400 });
  }

  const entry = await addEntry({ bookId: bookId as BookId, deviceId, data });
  return NextResponse.json({ ok: true, entry });
}

export async function GET(req: NextRequest) {
  const bookId = req.nextUrl.searchParams.get("bookId") as BookId | null;
  const deviceId = req.nextUrl.searchParams.get("deviceId");

  if (!bookId || !deviceId) {
    return NextResponse.json({ ok: false, error: "Parametri mancanti." }, { status: 400 });
  }

  const entries = await getEntries(bookId, deviceId);
  return NextResponse.json({ ok: true, entries });
}

SETUP_EOF_MARKER
cat > "app/api/diario/[id]/route.ts" << 'SETUP_EOF_MARKER'
import { NextRequest, NextResponse } from "next/server";
import { deleteEntry } from "@/lib/diario-entries";

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { deviceId } = await req.json();

  if (!deviceId) {
    return NextResponse.json({ ok: false, error: "Dispositivo mancante." }, { status: 400 });
  }

  const ok = await deleteEntry(id, deviceId);
  if (!ok) {
    return NextResponse.json({ ok: false, error: "Voce non trovata." }, { status: 404 });
  }

  return NextResponse.json({ ok: true });
}

SETUP_EOF_MARKER
cat > "components/DiarioForm.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useEffect, useState } from "react";
import { BookId } from "@/lib/books";
import { DiarioTemplate } from "@/lib/diario-templates";

function getDeviceId(): string {
  const key = "device_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

interface Entry {
  id: string;
  createdAt: string;
  data: Record<string, string>;
}

export default function DiarioForm({
  bookId,
  template,
}: {
  bookId: BookId;
  template: DiarioTemplate;
}) {
  const [formOpen, setFormOpen] = useState(false);
  const [values, setValues] = useState<Record<string, string>>({});
  const [entries, setEntries] = useState<Entry[]>([]);
  const [saving, setSaving] = useState(false);

  const deviceId = typeof window !== "undefined" ? getDeviceId() : "";

  useEffect(() => {
    if (!deviceId) return;
    fetch(`/api/diario?bookId=${bookId}&deviceId=${deviceId}`)
      .then((r) => r.json())
      .then((d) => {
        if (d.ok) setEntries(d.entries);
      });
  }, [bookId, deviceId]);

  function setField(key: string, value: string) {
    setValues((v) => ({ ...v, [key]: value }));
  }

  async function save() {
    setSaving(true);
    const res = await fetch("/api/diario", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ bookId, deviceId, data: values }),
    });
    const d = await res.json();
    setSaving(false);
    if (d.ok) {
      setEntries((e) => [d.entry, ...e]);
      setValues({});
      setFormOpen(false);
    }
  }

  async function remove(id: string) {
    const res = await fetch(`/api/diario/${id}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ deviceId }),
    });
    const d = await res.json();
    if (d.ok) setEntries((e) => e.filter((x) => x.id !== id));
  }

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <h2 className="font-medium text-lg" style={{ fontFamily: "Georgia, serif" }}>
          Il tuo diario digitale
        </h2>
        <button
          onClick={() => setFormOpen((o) => !o)}
          className="w-8 h-8 rounded-full bg-[#2C6E71] text-white text-lg flex items-center justify-center"
        >
          {formOpen ? "×" : "+"}
        </button>
      </div>

      {formOpen && (
        <div className="space-y-3">
          {template.map((section, i) => (
            <div key={i} className="bg-white border border-[#E1DFD6] rounded-xl p-3.5">
              <h4 className="text-[11px] uppercase tracking-widest text-[#2C6E71] mb-2.5 pb-2 border-b border-[#E1DFD6]">
                {section.title}
              </h4>

              {"fields" in section && (
                <div className="grid grid-cols-2 gap-2.5">
                  {section.fields.map((f) => (
                    <div key={f.key} className={f.type === "textarea" ? "col-span-2" : ""}>
                      {f.label && (
                        <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">
                          {f.label}
                        </label>
                      )}
                      {f.type === "textarea" ? (
                        <textarea
                          className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1] h-16"
                          placeholder={f.placeholder}
                          value={values[f.key] || ""}
                          onChange={(e) => setField(f.key, e.target.value)}
                        />
                      ) : (
                        <input
                          type={f.type}
                          className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1]"
                          placeholder={f.placeholder}
                          value={values[f.key] || ""}
                          onChange={(e) => setField(f.key, e.target.value)}
                        />
                      )}
                    </div>
                  ))}
                </div>
              )}

              {"type" in section && section.type === "table" && (
                <table className="w-full text-xs">
                  <thead>
                    <tr>
                      {section.columns.map((c) => (
                        <th key={c.key} className="text-left text-[9px] uppercase text-[#6B7E82] pb-1">
                          {c.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {[0, 1, 2].map((row) => (
                      <tr key={row}>
                        {section.columns.map((c) => (
                          <td key={c.key} className="border-t border-[#E1DFD6] py-1">
                            <input
                              className="w-full bg-transparent text-xs"
                              value={values[`${c.key}_${row}`] || ""}
                              onChange={(e) => setField(`${c.key}_${row}`, e.target.value)}
                            />
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}

              {"type" in section && section.type === "boxes" && (
                <>
                  <div className="grid grid-cols-2 gap-2.5">
                    {section.boxes.map((b) => (
                      <div key={b.key}>
                        <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">
                          {b.label}
                        </label>
                        <input
                          className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1]"
                          placeholder="note"
                          value={values[b.key] || ""}
                          onChange={(e) => setField(b.key, e.target.value)}
                        />
                      </div>
                    ))}
                  </div>
                  {section.extraField && (
                    <div className="mt-2.5">
                      <label className="block text-[10px] uppercase text-[#6B7E82] mb-1">
                        {section.extraField.label}
                      </label>
                      <textarea
                        className="w-full border border-[#E1DFD6] rounded-md px-2 py-1.5 text-sm bg-[#F6F5F1] h-16"
                        value={values[section.extraField.key] || ""}
                        onChange={(e) => setField(section.extraField!.key, e.target.value)}
                      />
                    </div>
                  )}
                </>
              )}
            </div>
          ))}

          <button
            onClick={save}
            disabled={saving}
            className="w-full bg-[#0F2D3D] text-white rounded-xl py-3 text-sm font-medium disabled:opacity-50"
          >
            {saving ? "Salvataggio…" : "Salva voce nel diario"}
          </button>
        </div>
      )}

      <p className="text-[11px] uppercase tracking-widest text-[#6B7E82] pt-2">
        Voci precedenti ({entries.length})
      </p>

      {entries.length === 0 && (
        <p className="text-sm text-[#6B7E82]">Nessuna voce ancora — inizia dal +</p>
      )}

      {entries.map((entry) => (
        <div key={entry.id} className="bg-white border border-[#E1DFD6] rounded-xl p-3.5">
          <div className="flex justify-between items-start mb-1.5">
            <span className="text-xs text-[#6B7E82] font-mono">
              {new Date(entry.createdAt).toLocaleDateString("it-IT", {
                day: "2-digit",
                month: "2-digit",
                year: "numeric",
              })}
            </span>
            <button
              onClick={() => remove(entry.id)}
              className="text-xs text-[#6B7E82] hover:text-red-600"
            >
              elimina
            </button>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {Object.entries(entry.data)
              .filter(([, v]) => v)
              .slice(0, 6)
              .map(([k, v]) => (
                <span
                  key={k}
                  className="text-[11px] bg-[#F6F5F1] border border-[#E1DFD6] rounded-full px-2 py-0.5"
                >
                  {v}
                </span>
              ))}
          </div>
        </div>
      ))}
    </div>
  );
}

SETUP_EOF_MARKER
cat > "lib/books.ts" << 'SETUP_EOF_MARKER'
// Configurazione centrale: un libro = un codice di sblocco (dal QR stampato nella prima pagina)
// Il codice va cambiato ad ogni ristampa (rotazione) per limitare la condivisione.

export type BookId = "feeder" | "mare-e-foce" | "senso-acqua";

export interface Book {
  id: BookId;
  name: string;
  unlockCode: string; // in produzione: da variabile d'ambiente, non hardcoded
  maxActivations: number; // limite dispositivi per codice
}

export const BOOKS: Record<BookId, Book> = {
  feeder: {
    id: "feeder",
    name: "Diario Feeder",
    unlockCode: process.env.UNLOCK_CODE_FEEDER || "FEEDER-2026-DEMO",
    maxActivations: 3,
  },
  "mare-e-foce": {
    id: "mare-e-foce",
    name: "Mare e Foce",
    unlockCode: process.env.UNLOCK_CODE_MAREFOCE || "MAREFOCE-2026-DEMO",
    maxActivations: 3,
  },
  "senso-acqua": {
    id: "senso-acqua",
    name: "Il senso dell'acqua",
    unlockCode: process.env.UNLOCK_CODE_SENSOACQUA || "SENSOACQUA-2026-DEMO",
    maxActivations: 3,
  },
};

export function findBookByCode(code: string): Book | undefined {
  return Object.values(BOOKS).find(
    (b) => b.unlockCode.toLowerCase() === code.trim().toLowerCase()
  );
}

SETUP_EOF_MARKER
cat > "lib/activations.ts" << 'SETUP_EOF_MARKER'
import { sql } from "./db";
import { BookId } from "./books";

/**
 * Prova a registrare un dispositivo per un libro.
 * Ritorna { ok: true } se sbloccato (nuovo o già registrato),
 * { ok: false } se il limite dispositivi è stato raggiunto.
 */
export async function tryActivate(
  bookId: BookId,
  deviceId: string,
  maxActivations: number
): Promise<{ ok: boolean; reason?: string }> {
  // Dispositivo già registrato → sempre ok, nessun consumo di slot
  const existing = await sql`
    SELECT 1 FROM activations WHERE book_id = ${bookId} AND device_id = ${deviceId}
  `;
  if (existing.length > 0) {
    return { ok: true };
  }

  // Nuovo dispositivo: controlla il limite corrente
  const [{ count }] = await sql`
    SELECT COUNT(*)::int AS count FROM activations WHERE book_id = ${bookId}
  `;
  if (Number(count) >= maxActivations) {
    return { ok: false, reason: "Limite dispositivi raggiunto per questo codice." };
  }

  await sql`
    INSERT INTO activations (book_id, device_id) VALUES (${bookId}, ${deviceId})
    ON CONFLICT (book_id, device_id) DO NOTHING
  `;
  return { ok: true };
}

SETUP_EOF_MARKER
cat > "lib/diario-entries.ts" << 'SETUP_EOF_MARKER'
import { sql } from "./db";
import { BookId } from "./books";

export interface DiarioEntry {
  id: string;
  bookId: BookId;
  deviceId: string;
  createdAt: string;
  data: Record<string, string>;
}

export async function addEntry(
  entry: Omit<DiarioEntry, "id" | "createdAt">
): Promise<DiarioEntry> {
  const [row] = await sql`
    INSERT INTO diario_entries (book_id, device_id, data)
    VALUES (${entry.bookId}, ${entry.deviceId}, ${sql.json(entry.data)})
    RETURNING id, book_id, device_id, data, created_at
  `;
  return {
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: row.data,
    createdAt: row.created_at.toISOString(),
  };
}

export async function getEntries(
  bookId: BookId,
  deviceId: string
): Promise<DiarioEntry[]> {
  const rows = await sql`
    SELECT id, book_id, device_id, data, created_at
    FROM diario_entries
    WHERE book_id = ${bookId} AND device_id = ${deviceId}
    ORDER BY created_at DESC
  `;
  return rows.map((row) => ({
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: row.data,
    createdAt: row.created_at.toISOString(),
  }));
}

export async function deleteEntry(id: string, deviceId: string): Promise<boolean> {
  const rows = await sql`
    DELETE FROM diario_entries WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id
  `;
  return rows.length > 0;
}

SETUP_EOF_MARKER
cat > "lib/diario-templates.ts" << 'SETUP_EOF_MARKER'
import { BookId } from "./books";

export type FieldType = "text" | "date" | "time" | "textarea" | "number";

export interface DiarioField {
  key: string;
  label: string;
  type: FieldType;
  placeholder?: string;
}

export interface DiarioSection {
  title: string;
  fields: DiarioField[];
}

export interface CatchTableSection {
  title: string;
  type: "table";
  columns: { key: string; label: string }[];
}

export interface CatchBoxesSection {
  title: string;
  type: "boxes";
  boxes: { key: string; label: string }[];
  extraField?: DiarioField; // es. "Altro"
}

export type DiarioTemplate = (DiarioSection | CatchTableSection | CatchBoxesSection)[];

// Struttura 1:1 con le pagine dei PDF caricati da Enrico
export const DIARIO_TEMPLATES: Record<Extract<BookId, "feeder" | "mare-e-foce">, DiarioTemplate> = {
  feeder: [
    {
      title: "Sessione",
      fields: [
        { key: "data", label: "Data", type: "date" },
        { key: "luogo", label: "Luogo", type: "text" },
        { key: "durata", label: "Durata", type: "text", placeholder: "es. 3h" },
      ],
    },
    {
      title: "Meteo e spot",
      fields: [
        { key: "meteo", label: "Meteo", type: "text", placeholder: "☀️ 🌤️ ☁️ 🌦️ ⛈️" },
        { key: "temperatura", label: "Temperatura", type: "text", placeholder: "°C" },
        { key: "spot", label: "Spot", type: "text" },
      ],
    },
    {
      title: "Pasturatori",
      fields: [
        { key: "cage", label: "Cage (gr)", type: "number" },
        { key: "block_end", label: "Block End (gr)", type: "number" },
        { key: "pellet", label: "Pellet (gr)", type: "number" },
        { key: "method", label: "Method (gr)", type: "number" },
      ],
    },
    {
      title: "Esche e pasture",
      fields: [
        { key: "esche_dure", label: "Esche dure", type: "text" },
        { key: "esche_naturali", label: "Esche naturali", type: "text" },
        { key: "pastura", label: "Pastura", type: "text" },
      ],
    },
    {
      title: "Assetto pescante",
      fields: [
        { key: "canna", label: "Canna (mt)", type: "text" },
        { key: "mulinello", label: "Mulinello", type: "text" },
        { key: "lenza_madre", label: "Lenza madre (mm)", type: "text" },
        { key: "terminale", label: "Terminale (mm)", type: "text" },
        { key: "amo", label: "Amo (nr)", type: "text" },
      ],
    },
    {
      title: "Catture",
      type: "table",
      columns: [
        { key: "specie", label: "Specie" },
        { key: "peso", label: "Peso" },
        { key: "lunghezza", label: "Lungh." },
        { key: "nr", label: "Nr" },
      ],
    },
    {
      title: "Analisi",
      fields: [
        { key: "cosa_ha_funzionato", label: "Cosa ha funzionato", type: "textarea" },
        { key: "cosa_migliorare", label: "Cosa migliorare", type: "textarea" },
      ],
    },
    {
      title: "Note",
      fields: [{ key: "note", label: "", type: "textarea" }],
    },
  ],

  "mare-e-foce": [
    {
      title: "Sessione di pesca",
      fields: [
        { key: "data", label: "Data", type: "date" },
        { key: "luogo", label: "Luogo", type: "text" },
        { key: "temperatura_aria", label: "Temperatura aria", type: "text", placeholder: "°C" },
        { key: "orario", label: "Orario", type: "time" },
        { key: "vento", label: "Vento", type: "text" },
        { key: "profondita", label: "Profondità", type: "text", placeholder: "mt" },
      ],
    },
    {
      title: "Note sessione",
      fields: [{ key: "note_sessione", label: "", type: "textarea" }],
    },
    {
      title: "Assetto tecnico",
      fields: [
        { key: "canna", label: "Canna (mt)", type: "text" },
        { key: "mulinello", label: "Mulinello", type: "text" },
        { key: "amo", label: "Amo", type: "text" },
        { key: "galleggiante", label: "Galleggiante (gr)", type: "text" },
        { key: "filo_madre", label: "Filo madre (mm)", type: "text" },
        { key: "terminale", label: "Terminale (mm)", type: "text" },
      ],
    },
    {
      title: "Catture",
      type: "boxes",
      boxes: [
        { key: "spigola", label: "🐟 Spigola" },
        { key: "orata", label: "🐟 Orata" },
        { key: "sarago", label: "🐟 Sarago" },
        { key: "cefalo", label: "🐟 Cefalo" },
      ],
      extraField: { key: "altro", label: "Altro", type: "textarea" },
    },
    {
      title: "Note",
      fields: [{ key: "note", label: "", type: "textarea" }],
    },
  ],
};

SETUP_EOF_MARKER
cat > "lib/db.ts" << 'SETUP_EOF_MARKER'
import postgres from "postgres";

// Su Vercel: collega "Vercel Postgres" dalla dashboard (tab Storage) e la
// variabile DATABASE_URL (o POSTGRES_URL) viene impostata in automatico.
// In locale: usa il file .env.local con la stessa variabile.
const connectionString =
  process.env.DATABASE_URL || process.env.POSTGRES_URL || "";

if (!connectionString) {
  throw new Error(
    "Manca DATABASE_URL (o POSTGRES_URL). Collega un database o aggiungi .env.local."
  );
}

// Una sola connessione condivisa in tutta l'app (pattern consigliato su serverless)
declare global {
  // eslint-disable-next-line no-var
  var __sql: ReturnType<typeof postgres> | undefined;
}

export const sql =
  global.__sql ||
  postgres(connectionString, {
    ssl: connectionString.includes("localhost") ? false : "require",
  });

if (process.env.NODE_ENV !== "production") {
  global.__sql = sql;
}

SETUP_EOF_MARKER
cat > "lib/schema.sql" << 'SETUP_EOF_MARKER'
-- Schema del database "Diari di Pesca".
-- Su Vercel: dalla dashboard del database (tab Storage → il tuo DB → Query),
-- incolla e esegui questo file una sola volta dopo aver collegato il database.

CREATE TABLE IF NOT EXISTS activations (
  id SERIAL PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (book_id, device_id)
);

CREATE TABLE IF NOT EXISTS diario_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_diario_book_device
  ON diario_entries (book_id, device_id);

CREATE INDEX IF NOT EXISTS idx_activations_book
  ON activations (book_id);

SETUP_EOF_MARKER
echo '✓ Progetto ricreato correttamente.'
echo 'File e cartelle create:'
find . -maxdepth 2 -not -path './.git*' -not -name 'README.md' | sort