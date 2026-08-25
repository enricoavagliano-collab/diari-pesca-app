#!/bin/bash
set -e
echo 'Aggiungo i tag/argomento agli articoli, con filtro dedicato...'
mkdir -p "app/articoli"
mkdir -p "lib"
cat > "lib/articoli.ts" << 'SETUP_EOF_MARKER'
export type Tag = "Tecnica" | "Specie" | "Esche" | "Attrezzatura" | "Spot" | "Diario";

export const TAGS: Tag[] = ["Tecnica", "Specie", "Esche", "Attrezzatura", "Spot", "Diario"];

export interface Articolo {
  title: string;
  url: string;
  tag: Tag;
}

export const ARTICOLI: Articolo[] = [
  { tag: "Tecnica", title: "Orata dalla scogliera: prepararsi alla riapertura con la bolognese e il granchio", url: "https://enricoavagliano.com/blog-detail/post/627391/orata-dalla-scogliera-prepararsi-alla-riapertura-con-la-bolognese-e-il-granchio" },
  { tag: "Diario", title: "Il diario di pesca feeder: perché iniziare a tenere i dati delle tue sessioni", url: "https://enricoavagliano.com/blog-detail/post/614519/il-diario-di-pesca-feeder:-perché-iniziare-a-tenere-i-dati-delle-tue-sessioni" },
  { tag: "Tecnica", title: "Feeder fishing: perché la differenza la fanno i dettagli", url: "https://enricoavagliano.com/blog-detail/post/612399/feeder-fishing:-perché-la-differenza-la-fanno-i-dettagli" },
  { tag: "Tecnica", title: "Pesca nei porti con sarda e alici: tecnica con bolognese", url: "https://enricoavagliano.com/blog-detail/post/605593/pesca-nei-porti-con-sarda-e-alici-tecnica-con-bolognese" },
  { tag: "Tecnica", title: "Pesca dalla spiaggia con bolognese e inglese", url: "https://enricoavagliano.com/blog-detail/post/604155/pesca-dalla-spiaggia-con-bolognese-e-inglese" },
  { tag: "Tecnica", title: "Fasi lunari e pesca: quanto influenzano davvero le catture in mare e foce", url: "https://enricoavagliano.com/blog-detail/post/601688/fasi-lunari-e-pesca:-quanto-influenzano-davvero-le-catture-in-mare-e-foce" },
  { tag: "Specie", title: "Finalmente primavera: le prime orate della stagione", url: "https://enricoavagliano.com/blog-detail/post/602244/finalmente-primavera-le-prime-orate-della-stagione" },
  { tag: "Specie", title: "Osservare il canale di Fiumicino quando le spigole entrano in attività", url: "https://enricoavagliano.com/blog-detail/post/600035/osservare-il-canale-di-fiumicino-quando-le-spigole-entrano-in-attivita." },
  { tag: "Tecnica", title: "Method invernale", url: "https://www.enricoavagliano.com/blog-detail/post/579195/method-invernale" },
  { tag: "Tecnica", title: "Barbo a specialist: lenze vincenti", url: "https://www.enricoavagliano.com/blog-detail/post/579197/barbo-a-specialist-lenze-vincenti" },
  { tag: "Attrezzatura", title: "Il lega ami Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579270/il-lega-ami-stonfo" },
  { tag: "Attrezzatura", title: "Sonda elite Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579271/sonda-elite-stonfo" },
  { tag: "Attrezzatura", title: "Porta finali 300 Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579272/porta-finali-300-stonfo" },
  { tag: "Tecnica", title: "Iniziare con la mosca giusta", url: "https://www.enricoavagliano.com/blog-detail/post/579273/iniziare-con-la-mosca-giusta" },
  { tag: "Attrezzatura", title: "Bottone service magnetico Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579274/botton-service-magnetico-stonfo" },
  { tag: "Spot", title: "A filo di banchina", url: "https://www.enricoavagliano.com/blog-detail/post/579280/https-www-enricoavagliano-it-single-post-a-filo-di-banchina" },
  { tag: "Specie", title: "Spigole nel gelo", url: "https://www.enricoavagliano.com/blog-detail/post/579281/spigole-nel-gelo" },
  { tag: "Esche", title: "Alla ricerca dell'esca perduta", url: "https://www.enricoavagliano.com/blog-detail/post/579282/alla-ricerca-dell-esca-perduta" },
  { tag: "Attrezzatura", title: "No nodo Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579257/no-nodo-stonfo" },
  { tag: "Attrezzatura", title: "Scatole magnetiche Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579258/scatole-magnetiche-stonfo" },
  { tag: "Spot", title: "I barbi del Liri", url: "https://www.enricoavagliano.com/blog-detail/post/579260/i-barbi-del-liri" },
  { tag: "Tecnica", title: "Alternativa antimurale", url: "https://www.enricoavagliano.com/blog-detail/post/579262/alternativa-antimurale" },
  { tag: "Attrezzatura", title: "Anti-tangle micro Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579265/anti-tangle-micro-stonfo" },
  { tag: "Spot", title: "Le breme del lago del Turano", url: "https://www.enricoavagliano.com/blog-detail/post/579266/le-breme-del-lago-del-turano" },
  { tag: "Tecnica", title: "Passate tiberine", url: "https://www.enricoavagliano.com/blog-detail/post/579268/passate-tiberine" },
  { tag: "Tecnica", title: "Trattenute salmastre in acque basse", url: "https://www.enricoavagliano.com/blog-detail/post/579259/trattenute-salmastre-in-acque-basse" },
  { tag: "Attrezzatura", title: "X series: catapult fionda", url: "https://www.enricoavagliano.com/blog-detail/post/579244/x-series-catapult-fionda-x-series" },
  { tag: "Specie", title: "Il fratello brutto del cavedano", url: "https://www.enricoavagliano.com/blog-detail/post/579245/il-fratello-brutto-del-cavedano" },
  { tag: "Attrezzatura", title: "Il re delle nostre lenze: il pallino di piombo", url: "https://www.enricoavagliano.com/blog-detail/post/579246/il-re-delle-nostre-lenze-il-pallino-di-piombo" },
  { tag: "Attrezzatura", title: "Travel lab bag Anglers", url: "https://www.enricoavagliano.com/blog-detail/post/579247/travel-lab-bag-anglers" },
  { tag: "Specie", title: "Presagi dorati", url: "https://www.enricoavagliano.com/blog-detail/post/579248/presagi-dorati" },
  { tag: "Diario", title: "Posa il fiasco", url: "https://www.enricoavagliano.com/blog-detail/post/579249/posa-il-fiasco" },
  { tag: "Esche", title: "L'oro nero: pesca con la cozza", url: "https://www.enricoavagliano.com/blog-detail/post/579252/l-oro-nero-pesca-con-la-cozza" },
  { tag: "Spot", title: "Riserva naturale regionale Nazzano Tevere Farfa", url: "https://www.enricoavagliano.com/blog-detail/post/579243/riserva-naturale-regionale-nazzano-tevere-farfa" },
  { tag: "Spot", title: "Lago di Canterno", url: "https://www.enricoavagliano.com/blog-detail/post/579254/lago-di-canterno" },
  { tag: "Tecnica", title: "Barbi a bolognese", url: "https://www.enricoavagliano.com/blog-detail/post/579215/barbi-a-bolognese" },
  { tag: "Tecnica", title: "Sagome in superficie", url: "https://www.enricoavagliano.com/blog-detail/post/579217/sagome-in-superficie" },
  { tag: "Tecnica", title: "Spigole in foce a bolognese e bigattini", url: "https://www.enricoavagliano.com/blog-detail/post/579218/spigole-in-foce-a-bolognese-e-bigattini" },
  { tag: "Tecnica", title: "Cefali a feeder fishing", url: "https://www.enricoavagliano.com/blog-detail/post/579221/cefali-a-feeder-fishing" },
  { tag: "Esche", title: "In pane veritas", url: "https://www.enricoavagliano.com/blog-detail/post/579222/in-pane-veritas" },
  { tag: "Tecnica", title: "Feeder ai laghi: primavera, ci riproviamo", url: "https://www.enricoavagliano.com/blog-detail/post/579223/feeder-ai-laghi-primavera-ci-riproviamo" },
  { tag: "Esche", title: "Mr Mais l'intramontabile", url: "https://www.enricoavagliano.com/blog-detail/post/579224/mr-mais-l-intramontabile" },
  { tag: "Diario", title: "Estrema ratio", url: "https://www.enricoavagliano.com/blog-detail/post/579225/estrema-ratio" },
  { tag: "Tecnica", title: "Correnti lunari", url: "https://www.enricoavagliano.com/blog-detail/post/579219/correnti-lunari" },
  { tag: "Tecnica", title: "Spigole in notturna", url: "https://www.enricoavagliano.com/blog-detail/post/579220/spigole-in-notturna" },
  { tag: "Spot", title: "Fly fishing in Austria by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579204/fly-fishing-in-austria-by-stonfo" },
  { tag: "Attrezzatura", title: "Method C", url: "https://www.enricoavagliano.com/blog-detail/post/579205/method-c" },
  { tag: "Tecnica", title: "Bolognese cefali by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579209/bolognese-cefali-by-stonfo" },
  { tag: "Tecnica", title: "Specialist al barbo", url: "https://www.enricoavagliano.com/blog-detail/post/579210/specialist-al-barbo" },
  { tag: "Tecnica", title: "Tinche all'inglese by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579211/tinche-all-inglese-by-stonfo" },
  { tag: "Specie", title: "Muggini & co", url: "https://www.enricoavagliano.com/blog-detail/post/579212/muggini-co" },
  { tag: "Esche", title: "Soluzioni idrosolubili", url: "https://www.enricoavagliano.com/blog-detail/post/579214/soluzioni-idrosolubili" },
  { tag: "Esche", title: "Come innescare una mini boiles by Stonfo", url: "https://www.enricoavagliano.com/blog-detail/post/579200/come-innescare-una-mini-boiles-by-stonfo" },
  { tag: "Tecnica", title: "Spigole in urban fishing", url: "https://www.enricoavagliano.com/blog-detail/post/579199/spigole-in-urban-fishing" },
];

SETUP_EOF_MARKER
cat > "app/articoli/page.tsx" << 'SETUP_EOF_MARKER'
"use client";

import { useState } from "react";
import Link from "next/link";
import { ARTICOLI, TAGS, Tag } from "@/lib/articoli";

function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, ""); // toglie gli accenti (é→e, ò→o, ecc.)
}

export default function ArticoliPage() {
  const [query, setQuery] = useState("");
  const [activeTag, setActiveTag] = useState<Tag | null>(null);

  const filtered = ARTICOLI.filter((a) => {
    const matchesTag = !activeTag || a.tag === activeTag;
    if (!matchesTag) return false;
    if (!query.trim()) return true;
    const titleNorm = normalize(a.title);
    const words = normalize(query).split(/\s+/).filter(Boolean);
    return words.every((w) => titleNorm.includes(w));
  });

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

        <div className="flex items-center gap-2 bg-white border border-[#E1DFD6] rounded-xl px-3.5 py-2.5 mb-3">
          <span>🔍</span>
          <input
            className="flex-1 outline-none text-sm bg-transparent"
            placeholder="Cerca un articolo…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        <div className="flex gap-1.5 overflow-x-auto pb-1 mb-4 -mx-1 px-1">
          <button
            onClick={() => setActiveTag(null)}
            className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
              activeTag === null
                ? "bg-[#0F2D3D] text-white border-[#0F2D3D]"
                : "bg-white border-[#E1DFD6] text-[#6B7E82]"
            }`}
          >
            Tutti
          </button>
          {TAGS.map((t) => (
            <button
              key={t}
              onClick={() => setActiveTag(t)}
              className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
                activeTag === t
                  ? "bg-[#2C6E71] text-white border-[#2C6E71]"
                  : "bg-white border-[#E1DFD6] text-[#6B7E82]"
              }`}
            >
              {t}
            </button>
          ))}
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
              <div className="flex items-start justify-between gap-3 mb-1">
                <span className="text-[10px] font-mono uppercase tracking-wide text-[#D98E4A]">
                  {a.tag}
                </span>
                <span className="text-[#6B7E82] text-sm flex-shrink-0">↗</span>
              </div>
              <h3 className="text-[14px] leading-snug" style={{ fontFamily: "Georgia, serif" }}>
                {a.title}
              </h3>
              <p className="text-[11px] text-[#6B7E82] mt-1.5">Leggi sul blog</p>
            </a>
          ))}
        </div>
      </div>
    </main>
  );
}

SETUP_EOF_MARKER
echo "Fatto: 6 categorie (Tecnica, Specie, Esche, Attrezzatura, Spot, Diario), filtro + ricerca combinati."