#!/bin/bash
set -e
echo 'Aggiungo la sezione Articoli con 54 articoli tecnici dal blog...'
mkdir -p "app"
mkdir -p "app/articoli"
mkdir -p "lib"
cat > "lib/articoli.ts" << 'SETUP_EOF_MARKER'
export interface Articolo {
  title: string;
  url: string;
}

export const ARTICOLI: Articolo[] = [
  { title: "Orata dalla scogliera: prepararsi alla riapertura con la bolognese e il granchio", url: "https://enricoavagliano.com/blog-detail/post/627391/orata-dalla-scogliera-prepararsi-alla-riapertura-con-la-bolognese-e-il-granchio" },
  { title: "Il diario di pesca feeder: perché iniziare a tenere i dati delle tue sessioni", url: "https://enricoavagliano.com/blog-detail/post/614519/il-diario-di-pesca-feeder:-perché-iniziare-a-tenere-i-dati-delle-tue-sessioni" },
  { title: "Feeder fishing: perché la differenza la fanno i dettagli", url: "https://enricoavagliano.com/blog-detail/post/612399/feeder-fishing:-perché-la-differenza-la-fanno-i-dettagli" },
  { title: "Pesca nei porti con sarda e alici: tecnica con bolognese", url: "https://enricoavagliano.com/blog-detail/post/605593/pesca-nei-porti-con-sarda-e-alici-tecnica-con-bolognese" },
  { title: "Pesca dalla spiaggia con bolognese e inglese", url: "https://enricoavagliano.com/blog-detail/post/604155/pesca-dalla-spiaggia-con-bolognese-e-inglese" },
  { title: "Fasi lunari e pesca: quanto influenzano davvero le catture in mare e foce", url: "https://enricoavagliano.com/blog-detail/post/601688/fasi-lunari-e-pesca:-quanto-influenzano-davvero-le-catture-in-mare-e-foce" },
  { title: "Finalmente primavera: le prime orate della stagione", url: "https://enricoavagliano.com/blog-detail/post/602244/finalmente-primavera-le-prime-orate-della-stagione" },
  { title: "Osservare il canale di Fiumicino quando le spigole entrano in attività", url: "https://enricoavagliano.com/blog-detail/post/600035/osservare-il-canale-di-fiumicino-quando-le-spigole-entrano-in-attivita." },
  { title: "Method invernale", url: "https://www.enricoavagliano.com/blog-detail/post/579195/method-invernale" },
  { title: "Barbo a specialist: lenze vincenti", url: "https://www.enricoavagliano.com/blog-detail/post/579197/barbo-a-specialist-lenze-vincenti" },
  { title: "Il lega ami Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579270/il-lega-ami-stonfo" },
  { title: "Sonda elite Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579271/sonda-elite-stonfo" },
  { title: "Porta finali 300 Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579272/porta-finali-300-stonfo" },
  { title: "Iniziare con la mosca giusta", url: "https://www.enricoavagliano.com/blog-detail/post/579273/iniziare-con-la-mosca-giusta" },
  { title: "Bottone service magnetico Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579274/botton-service-magnetico-stonfo" },
  { title: "A filo di banchina", url: "https://www.enricoavagliano.com/blog-detail/post/579280/https-www-enricoavagliano-it-single-post-a-filo-di-banchina" },
  { title: "Spigole nel gelo", url: "https://www.enricoavagliano.com/blog-detail/post/579281/spigole-nel-gelo" },
  { title: "Alla ricerca dell'esca perduta", url: "https://www.enricoavagliano.com/blog-detail/post/579282/alla-ricerca-dell-esca-perduta" },
  { title: "No nodo Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579257/no-nodo-stonfo" },
  { title: "Scatole magnetiche Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579258/scatole-magnetiche-stonfo" },
  { title: "I barbi del Liri", url: "https://www.enricoavagliano.com/blog-detail/post/579260/i-barbi-del-liri" },
  { title: "Alternativa antimurale", url: "https://www.enricoavagliano.com/blog-detail/post/579262/alternativa-antimurale" },
  { title: "Anti-tangle micro Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579265/anti-tangle-micro-stonfo" },
  { title: "Le breme del lago del Turano", url: "https://www.enricoavagliano.com/blog-detail/post/579266/le-breme-del-lago-del-turano" },
  { title: "Passate tiberine", url: "https://www.enricoavagliano.com/blog-detail/post/579268/passate-tiberine" },
  { title: "Trattenute salmastre in acque basse", url: "https://www.enricoavagliano.com/blog-detail/post/579259/trattenute-salmastre-in-acque-basse" },
  { title: "X series: catapult fionda", url: "https://www.enricoavagliano.com/blog-detail/post/579244/x-series-catapult-fionda-x-series" },
  { title: "Il fratello brutto del cavedano", url: "https://www.enricoavagliano.com/blog-detail/post/579245/il-fratello-brutto-del-cavedano" },
  { title: "Il re delle nostre lenze: il pallino di piombo", url: "https://www.enricoavagliano.com/blog-detail/post/579246/il-re-delle-nostre-lenze-il-pallino-di-piombo" },
  { title: "Travel lab bag Anglers", url: "https://www.enricoavagliano.com/blog-detail/post/579247/travel-lab-bag-anglers" },
  { title: "Presagi dorati", url: "https://www.enricoavagliano.com/blog-detail/post/579248/presagi-dorati" },
  { title: "Posa il fiasco", url: "https://www.enricoavagliano.com/blog-detail/post/579249/posa-il-fiasco" },
  { title: "L'oro nero: pesca con la cozza", url: "https://www.enricoavagliano.com/blog-detail/post/579252/l-oro-nero-pesca-con-la-cozza" },
  { title: "Riserva naturale regionale Nazzano Tevere Farfa", url: "https://www.enricoavagliano.com/blog-detail/post/579243/riserva-naturale-regionale-nazzano-tevere-farfa" },
  { title: "Lago di Canterno", url: "https://www.enricoavagliano.com/blog-detail/post/579254/lago-di-canterno" },
  { title: "Barbi a bolognese", url: "https://www.enricoavagliano.com/blog-detail/post/579215/barbi-a-bolognese" },
  { title: "Sagome in superficie", url: "https://www.enricoavagliano.com/blog-detail/post/579217/sagome-in-superficie" },
  { title: "Spigole in foce a bolognese e bigattini", url: "https://www.enricoavagliano.com/blog-detail/post/579218/spigole-in-foce-a-bolognese-e-bigattini" },
  { title: "Cefali a feeder fishing", url: "https://www.enricoavagliano.com/blog-detail/post/579221/cefali-a-feeder-fishing" },
  { title: "In pane veritas", url: "https://www.enricoavagliano.com/blog-detail/post/579222/in-pane-veritas" },
  { title: "Feeder ai laghi: primavera, ci riproviamo", url: "https://www.enricoavagliano.com/blog-detail/post/579223/feeder-ai-laghi-primavera-ci-riproviamo" },
  { title: "Mr Mais l'intramontabile", url: "https://www.enricoavagliano.com/blog-detail/post/579224/mr-mais-l-intramontabile" },
  { title: "Estrema ratio", url: "https://www.enricoavagliano.com/blog-detail/post/579225/estrema-ratio" },
  { title: "Correnti lunari", url: "https://www.enricoavagliano.com/blog-detail/post/579219/correnti-lunari" },
  { title: "Spigole in notturna", url: "https://www.enricoavagliano.com/blog-detail/post/579220/spigole-in-notturna" },
  { title: "Fly fishing in Austria by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579204/fly-fishing-in-austria-by-stonfo" },
  { title: "Method C", url: "https://www.enricoavagliano.com/blog-detail/post/579205/method-c" },
  { title: "Bolognese cefali by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579209/bolognese-cefali-by-stonfo" },
  { title: "Specialist al barbo", url: "https://www.enricoavagliano.com/blog-detail/post/579210/specialist-al-barbo" },
  { title: "Tinche all'inglese by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579211/tinche-all-inglese-by-stonfo" },
  { title: "Muggini & co", url: "https://www.enricoavagliano.com/blog-detail/post/579212/muggini-co" },
  { title: "Soluzioni idrosolubili", url: "https://www.enricoavagliano.com/blog-detail/post/579214/soluzioni-idrosolubili" },
  { title: "Come innescare una mini boiles by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579200/come-innescare-una-mini-boiles-by-stonfo" },
  { title: "Spigole in urban fishing", url: "https://www.enricoavagliano.com/blog-detail/post/579199/spigole-in-urban-fishing" },
];

SETUP_EOF_MARKER
cat > "app/articoli/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useState } from "react";
import Link from "next/link";
import { ARTICOLI } from "@/lib/articoli";

export default function ArticoliPage() {
  const [query, setQuery] = useState("");

  const filtered = query.trim()
    ? ARTICOLI.filter((a) => a.title.toLowerCase().includes(query.toLowerCase()))
    : ARTICOLI;

  return (
    <main className="min-h-screen bg-[#F6F5F1] flex justify-center">
      <div className="w-full max-w-md p-5 pb-16">
        <Link href="/" className="text-xs text-[#6B7E82]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-1" style={{ fontFamily: "Georgia, serif" }}>
          Articoli
        </h1>
        <p className="text-xs text-[#6B7E82] mb-4">{ARTICOLI.length} articoli dal blog</p>

        <div className="flex items-center gap-2 bg-white border border-[#E1DFD6] rounded-xl px-3.5 py-2.5 mb-4">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca un articolo…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        {filtered.length === 0 && (
          <p className="text-sm text-[#6B7E82]">Nessun articolo trovato per questa ricerca.</p>
        )}

        <div className="space-y-2.5">
          {filtered.map((a) => (
            <a
              key={a.url}
              href={a.url}
              target="_blank"
              rel="noopener noreferrer"
              className="block bg-white border border-[#E1DFD6] rounded-xl p-3.5"
            >
              <div className="flex items-start justify-between gap-3">
                <h3 className="text-[14px] leading-snug" style={{ fontFamily: "Georgia, serif" }}>
                  {a.title}
                </h3>
                <span className="text-[#6B7E82] text-sm flex-shrink-0 mt-0.5">↗</span>
              </div>
              <p className="text-[11px] text-[#6B7E82] mt-1.5">Leggi sul blog</p>
            </a>
          ))}
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
cat > "app/page.tsx" << 'SETUP_EOF_MARKER'
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
          href="/articoli"
          className="bg-white border border-[#E1DFD6] rounded-xl p-3.5 flex items-center gap-3 mb-3"
        >
          <div className="w-9 h-9 rounded-lg bg-[#F6F5F1] flex items-center justify-center text-lg flex-shrink-0">
            📰
          </div>
          <div>
            <h3 className="font-semibold text-sm">Articoli</h3>
            <p className="text-xs text-[#6B7E82]">Tutti i contenuti tecnici dal blog</p>
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

SETUP_EOF_MARKER
echo "Fatto: 54 articoli, ricerca inclusa, aperta a tutti."