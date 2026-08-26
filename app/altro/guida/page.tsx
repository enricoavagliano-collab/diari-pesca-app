import Link from "next/link";

const FAQ = [
  {
    q: "Come sblocco i contenuti di un libro?",
    a: "Inquadra il QR stampato nella prima pagina della tua copia con la fotocamera del telefono. In alternativa, vai su \"Hai un codice? Sbloccalo qui\" nella home e inseriscilo a mano.",
  },
  {
    q: "Ho sbloccato un libro su un dispositivo, funziona anche su un altro?",
    a: "Ogni codice funziona su un numero limitato di dispositivi (di solito 2-3), pensato per l'uso personale. Se hai finito i tentativi disponibili, contattaci per assistenza.",
  },
  {
    q: "Gli orari di marea sono precisi al minuto?",
    a: "Sono previsioni (non un dato ufficiale di navigazione) e possono scostarsi di qualche decina di minuti dal dato reale locale — utili per farsi un'idea, non per la sicurezza in mare.",
  },
  {
    q: "Il mio diario resta salvato se cambio telefono?",
    a: "No: il diario digitale, le lenze salvate e gli sblocchi restano legati al dispositivo/browser su cui li hai creati, non c'è un account centrale.",
  },
];

export default function GuidaPage() {
  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <Link href="/altro" className="text-xs text-[#8FA8B2]">
          ← Altro
        </Link>
        <h1 className="text-[22px] mt-2 mb-5" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Guida e supporto
        </h1>

        <div className="space-y-3 mb-6">
          {FAQ.map((item, i) => (
            <div key={i} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
              <h3 className="text-sm font-semibold mb-1.5">{item.q}</h3>
              <p className="text-[12.5px] text-[#8FA8B2] leading-relaxed">{item.a}</p>
            </div>
          ))}
        </div>

        <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
          <h3 className="text-sm font-semibold mb-1.5">Serve altro aiuto?</h3>
          <p className="text-[12.5px] text-[#8FA8B2] leading-relaxed mb-2">
            Scrivi a Enrico direttamente dal blog:
          </p>
          <a
            href="https://enricoavagliano.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-[#2CA6A4] underline"
          >
            enricoavagliano.com →
          </a>
        </div>
      </div>
    </main>
  );
}

