import Link from "next/link";
import { Anchor, CalendarDays, Newspaper, KeyRound, Settings, HelpCircle, Info, ChevronRight } from "lucide-react";

const VOCI = [
  { href: "/lenze", Icon: Anchor, title: "Le mie lenze", subtitle: "Le configurazioni di Enrico e le tue" },
  { href: "/specie", Icon: CalendarDays, title: "Specie e periodi", subtitle: "Calendario delle specie" },
  { href: "/articoli", Icon: Newspaper, title: "Articoli", subtitle: "Tutti gli articoli del blog" },
  { href: "/sblocca", Icon: KeyRound, title: "Hai un codice?", subtitle: "Accedi ai contenuti esclusivi" },
];

const VOCI_APP = [
  { href: "/altro/impostazioni", Icon: Settings, title: "Impostazioni" },
  { href: "/altro/guida", Icon: HelpCircle, title: "Guida e supporto" },
  { href: "/altro/info", Icon: Info, title: "Informazioni sull'app" },
];

export default function AltroPage() {
  return (
    <main className="min-h-screen bg-[#0B1F2A] text-[#F6F5F1] flex justify-center pb-24">
      <div className="w-full max-w-md p-5">
        <h1 className="text-[22px] mb-5" style={{ fontFamily: "var(--font-fraunces)", fontWeight: 500 }}>
          Altro
        </h1>

        <div className="space-y-2.5 mb-6">
          {VOCI.map(({ href, Icon, title, subtitle }) => (
            <Link
              key={href}
              href={href}
              className="flex items-center gap-3 bg-[#124E5A] border border-white/10 rounded-xl p-3.5"
            >
              <div className="w-9 h-9 rounded-lg bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                <Icon size={18} strokeWidth={1.75} className="text-[#2CA6A4]" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-sm">{title}</h3>
                <p className="text-xs text-[#8FA8B2]">{subtitle}</p>
              </div>
              <ChevronRight size={16} className="text-[#8FA8B2] flex-shrink-0" />
            </Link>
          ))}
        </div>

        <div className="border-t border-white/10 pt-4 space-y-1">
          {VOCI_APP.map(({ href, Icon, title }) => (
            <Link key={href} href={href} className="flex items-center gap-3 py-2.5">
              <Icon size={17} strokeWidth={1.75} className="text-[#8FA8B2]" />
              <span className="text-sm flex-1">{title}</span>
              <ChevronRight size={15} className="text-[#8FA8B2]" />
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}

