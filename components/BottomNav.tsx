"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Waves, CloudSun, BookOpen, MoreHorizontal } from "lucide-react";

const TABS = [
  { href: "/", label: "Home", Icon: Home },
  { href: "/maree", label: "Maree", Icon: Waves },
  { href: "/meteo", label: "Meteo", Icon: CloudSun },
  { href: "/diario", label: "Diario", Icon: BookOpen },
  { href: "/altro", label: "Altro", Icon: MoreHorizontal },
];

export default function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-[#0B1F2A] border-t border-white/10">
      <div className="max-w-md mx-auto flex" style={{ paddingBottom: "max(6px, env(safe-area-inset-bottom))" }}>
        {TABS.map(({ href, label, Icon }) => {
          const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className="flex-1 flex flex-col items-center gap-1 py-2.5"
            >
              <Icon
                size={20}
                strokeWidth={active ? 2.25 : 1.75}
                className={active ? "text-[#FF9A3C]" : "text-[#8FA8B2]"}
              />
              <span className={`text-[10.5px] ${active ? "text-[#FF9A3C] font-medium" : "text-[#8FA8B2]"}`}>
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

