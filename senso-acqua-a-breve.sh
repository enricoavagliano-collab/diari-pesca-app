#!/bin/bash
set -e

echo "=== Aggiungo (a breve online) alla dicitura Il senso dell'acqua ==="

cat > app/lenze/LenzeClient.tsx << 'LENZECLIENTEOF'
"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Waves, Link2, CircleDot, Weight, Fish as FishIcon, Plus, Package, Wheat } from "lucide-react";
import {
  LenzaCategory,
  Tecnica,
  TECNICHE,
  TECNICA_VARIANTI,
  getOfficialLenza,
  OFFICIAL_ASSETTI,
  LENZA_FIELDS_MARE,
  ASSETTO_FIELDS_FEEDER,
  LenzaSpec,
} from "@/lib/lenze-official";

interface LenzaEntry {
  id: string;
  title: string;
  data: Record<string, string>;
  createdAt: string;
}

function getDeviceId(): string {
  const key = "device_id";
  let id = localStorage.getItem(key);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(key, id);
  }
  return id;
}

function fieldIcon(key: string) {
  const map: Record<string, typeof Waves> = {
    madre: Waves,
    lenzaMadre: Waves,
    finale: Link2,
    terminale: Link2,
    galleggiante: CircleDot,
    piombatura: Weight,
    amo: FishIcon,
    pasturatore: Package,
    esche: Wheat,
    pastura: Wheat,
  };
  return map[key] || CircleDot;
}

export default function LenzeClient({
  unlockedMare,
  unlockedFeeder,
  unlockedSensoAcqua,
}: {
  unlockedMare: boolean;
  unlockedFeeder: boolean;
  unlockedSensoAcqua: boolean;
}) {
  const [category, setCategory] = useState<LenzaCategory>("mare");
  const [subtab, setSubtab] = useState<"enrico" | "mie">("enrico");
  const [tecnica, setTecnica] = useState<Tecnica>("trattenuta");
  const [variante, setVariante] = useState<string>(TECNICA_VARIANTI["trattenuta"][0].id);

  const [mine, setMine] = useState<LenzaEntry[]>([]);
  const [formOpen, setFormOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [values, setValues] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const deviceId = typeof window !== "undefined" ? getDeviceId() : "";

  const loadMine = useCallback(
    (cat: LenzaCategory) => {
      if (!deviceId) return;
      fetch(`/api/lenze?deviceId=${deviceId}&category=${cat}`)
        .then((r) => r.json())
        .then((d) => {
          if (d.ok) setMine(d.entries);
        });
    },
    [deviceId]
  );

  useEffect(() => {
    loadMine(category);
  }, [category, loadMine]);

  useEffect(() => {
    // Quando cambia la tecnica, seleziona la prima variante disponibile
    setVariante(TECNICA_VARIANTI[tecnica][0].id);
  }, [tecnica]);

  function setField(key: string, value: string) {
    setValues((v) => ({ ...v, [key]: value }));
  }

  function copyToMine(spec: LenzaSpec) {
    setValues({
      madre: spec.madre,
      finale: spec.finale,
      galleggiante: spec.galleggiante,
      piombatura: spec.piombatura,
      amo: spec.amo,
    });
    setTitle(
      `${TECNICHE.find((t) => t.id === tecnica)?.label} — ${
        TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label
      } (copia)`
    );
    setSubtab("mie");
    setFormOpen(true);
  }

  async function save() {
    if (!title.trim()) return;
    setSaving(true);
    const res = await fetch("/api/lenze", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ deviceId, category, title, data: values }),
    });
    const d = await res.json();
    setSaving(false);
    if (d.ok) {
      setMine((m) => [d.entry, ...m]);
      setTitle("");
      setValues({});
      setFormOpen(false);
    }
  }

  async function remove(id: string) {
    const res = await fetch(`/api/lenze/${id}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ deviceId }),
    });
    const d = await res.json();
    if (d.ok) setMine((m) => m.filter((x) => x.id !== id));
  }

  const spec = category === "mare" ? getOfficialLenza(tecnica, variante) : null;
  const personalFields = category === "mare" ? LENZA_FIELDS_MARE : ASSETTO_FIELDS_FEEDER;
  const categoryUnlocked = category === "mare" ? unlockedMare || unlockedSensoAcqua : unlockedFeeder;

  return (
    <main className="min-h-screen bg-[#0B1F2A] flex justify-center">
      <div className="w-full max-w-md p-5 pb-24">
        <Link href="/" className="text-xs text-[#8FA8B2]">
          ← Home
        </Link>
        <h1 className="text-xl font-medium mt-2 mb-4" style={{ fontFamily: "var(--font-fraunces)" }}>
          Le mie lenze
        </h1>

        {/* Categoria principale */}
        <div className="flex gap-1.5 mb-3">
          <button
            onClick={() => setCategory("mare")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "mare"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🌊 Mare / Foce {!(unlockedMare || unlockedSensoAcqua) && "🔒"}
          </button>
          <button
            onClick={() => setCategory("feeder")}
            className={`text-[12px] font-mono px-2.5 py-1 rounded-full border flex items-center gap-1 ${
              category === "feeder"
                ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
            }`}
          >
            🎣 Feeder {!unlockedFeeder && "🔒"}
          </button>
        </div>

        {!categoryUnlocked ? (
          <div className="bg-[#124E5A] border border-white/10 rounded-xl p-6 text-center mt-4">
            <div className="text-3xl mb-3">🔒</div>
            <h2 className="font-medium text-[15px] mb-1.5">
              {category === "mare" ? "Sblocca con Mare e Foce o Il senso dell'acqua (a breve online)" : "Sblocca con Diario Feeder"}
            </h2>
            <p className="text-sm text-[#8FA8B2] leading-relaxed">
              Questa sezione fa parte dei contenuti del diario{" "}
              {category === "mare" ? "Mare e Foce (o de Il senso dell'acqua, a breve online)" : "Feeder"} — inquadra il QR nella prima
              pagina della tua copia per sbloccarla.
            </p>
          </div>
        ) : (
          <>
            {/* Sotto-schede */}
        <div className="flex gap-1 mb-4 bg-[#0B1F2A] rounded-xl p-1">
          <button
            onClick={() => setSubtab("enrico")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "enrico" ? "bg-[#124E5A] text-[#F6F5F1]" : "text-[#8FA8B2]"
            }`}
          >
            Da Enrico
          </button>
          <button
            onClick={() => setSubtab("mie")}
            className={`flex-1 text-center py-2 rounded-lg text-[13px] font-semibold ${
              subtab === "mie" ? "bg-[#124E5A] text-[#F6F5F1]" : "text-[#8FA8B2]"
            }`}
          >
            Le mie
          </button>
        </div>

        {/* ===== DA ENRICO — MARE/FOCE ===== */}
        {subtab === "enrico" && category === "mare" && (
          <div>
            <div className="flex gap-1.5 overflow-x-auto pb-1 mb-3 -mx-1 px-1">
              {TECNICHE.map((t) => (
                <button
                  key={t.id}
                  onClick={() => setTecnica(t.id)}
                  className={`text-[12px] font-medium px-3 py-1.5 rounded-full whitespace-nowrap border ${
                    tecnica === t.id
                      ? "bg-[#2CA6A4] text-[#0B1F2A] border-[#2CA6A4]"
                      : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            <div className="flex flex-wrap gap-1.5 mb-4">
              {TECNICA_VARIANTI[tecnica].map((v) => (
                <button
                  key={v.id}
                  onClick={() => setVariante(v.id)}
                  className={`text-[11.5px] px-2.5 py-1.5 rounded-lg border ${
                    variante === v.id
                      ? "bg-[#2CA6A4] text-white border-[#2CA6A4]"
                      : "bg-[#124E5A] border-white/10 text-[#8FA8B2]"
                  }`}
                >
                  {v.label}
                </button>
              ))}
            </div>

            {spec && (
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {TECNICHE.find((t) => t.id === tecnica)?.label} —{" "}
                  {TECNICA_VARIANTI[tecnica].find((v) => v.id === variante)?.label}
                </h3>
                <p className="text-[11px] text-[#8FA8B2] mb-3">di Enrico Avagliano</p>

                <div className="space-y-2.5 pt-2.5 border-t border-white/10">
                  {[
                    { Icon: Waves, label: "Madre", value: spec.madre },
                    { Icon: Link2, label: "Finale", value: spec.finale },
                    { Icon: CircleDot, label: "Galleggiante", value: spec.galleggiante },
                    { Icon: FishIcon, label: "Amo", value: spec.amo },
                  ].map(({ Icon, label, value }) => (
                    <div key={label} className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                        <Icon size={15} strokeWidth={1.75} className="text-[#2CA6A4]" />
                      </div>
                      <span className="text-[12.5px] flex-1">{label}</span>
                      <span className="font-mono text-[12.5px] text-[#F6F5F1]">{value}</span>
                    </div>
                  ))}
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                      <Weight size={15} strokeWidth={1.75} className="text-[#2CA6A4]" />
                    </div>
                    <div className="flex-1">
                      <span className="text-[12.5px]">Piombatura</span>
                      <p className="text-[11.5px] text-[#8FA8B2] leading-relaxed mt-0.5">{spec.piombatura}</p>
                    </div>
                  </div>
                </div>

                <p className="text-[12px] text-[#8FA8B2] italic mt-3 leading-relaxed">{spec.nota}</p>

                <button
                  onClick={() => copyToMine(spec)}
                  className="w-full flex items-center justify-center gap-1.5 border border-[#2CA6A4] text-[#2CA6A4] rounded-full py-2 text-[12.5px] font-medium mt-3"
                >
                  <Plus size={14} /> Aggiungi alle mie
                </button>

                {unlockedSensoAcqua ? (
                  <div className="mt-3 pt-3 border-t border-white/10">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-[10.5px] text-[#FF9A3C] font-medium">
                        ✎ Disegno esclusivo — Il senso dell&apos;acqua (a breve online)
                      </span>
                    </div>
                    <div className="bg-[#0B1F2A] border border-dashed border-white/10 rounded-lg h-32 flex items-center justify-center text-[11px] text-[#8FA8B2]">
                      📐 Disegno del montaggio — in arrivo
                    </div>
                  </div>
                ) : (
                  <div className="mt-3 pt-3 border-t border-white/10 flex items-center gap-2.5 bg-[#0B1F2A] rounded-lg p-2.5">
                    <span className="text-lg flex-shrink-0">🔒</span>
                    <p className="text-[11px] text-[#8FA8B2] leading-relaxed">
                      Disegno del montaggio disponibile solo per chi ha Il senso dell&apos;acqua (a breve online).
                    </p>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* ===== DA ENRICO — FEEDER ===== */}
        {subtab === "enrico" && category === "feeder" && (
          <div className="space-y-3">
            {OFFICIAL_ASSETTI.map((a, i) => (
              <div key={i} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <h3 className="font-medium text-[15px] mb-1" style={{ fontFamily: "var(--font-fraunces)" }}>
                  {a.title}
                </h3>
                <p className="text-[11px] text-[#8FA8B2] mb-3">di Enrico Avagliano</p>
                <div className="grid grid-cols-2 gap-2.5 pt-2.5 border-t border-white/10">
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Pasturatore</div>
                    <div className="font-mono text-[12.5px]">{a.pasturatore}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Terminale</div>
                    <div className="font-mono text-[12.5px]">{a.terminale}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Lenza madre</div>
                    <div className="font-mono text-[12.5px]">{a.lenzaMadre}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Amo</div>
                    <div className="font-mono text-[12.5px]">{a.amo}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Esche</div>
                    <div className="font-mono text-[12.5px]">{a.esche}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-[#8FA8B2] tracking-wide">Pastura</div>
                    <div className="font-mono text-[12.5px]">{a.pastura}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ===== LE MIE (personali, sia mare che feeder) ===== */}
        {subtab === "mie" && (
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-xs text-[#8FA8B2]">{mine.length} salvate</span>
              <button
                onClick={() => setFormOpen((o) => !o)}
                className="w-8 h-8 rounded-full bg-[#2CA6A4] text-white text-lg flex items-center justify-center"
              >
                {formOpen ? "×" : "+"}
              </button>
            </div>

            {formOpen && (
              <div className="bg-[#124E5A] border border-white/10 rounded-xl p-4 space-y-3">
                <div>
                  <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">Nome</label>
                  <input
                    className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                    placeholder={
                      category === "mare" ? "es. La mia bolognese da canale" : "es. Il mio assetto da corrente"
                    }
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                  />
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  {personalFields.map((f) => (
                    <div key={f.key}>
                      <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">{f.label}</label>
                      <input
                        className="w-full border border-white/10 rounded-md px-2.5 py-2 text-sm bg-[#0B1F2A]"
                        value={values[f.key] || ""}
                        onChange={(e) => setField(f.key, e.target.value)}
                      />
                    </div>
                  ))}
                </div>
                <button
                  onClick={save}
                  disabled={saving || !title.trim()}
                  className="w-full bg-[#2CA6A4] text-[#0B1F2A] rounded-xl py-2.5 text-sm font-medium disabled:opacity-50"
                >
                  {saving ? "Salvataggio…" : "Salva"}
                </button>
              </div>
            )}

            {mine.length === 0 && !formOpen && (
              <p className="text-sm text-[#8FA8B2]">Nessuna lenza salvata ancora — inizia dal +</p>
            )}

            {mine.map((entry) => (
              <div key={entry.id} className="bg-[#124E5A] border border-white/10 rounded-xl p-4">
                <div className="flex justify-between items-start mb-2.5 pb-2.5 border-b border-white/10">
                  <h3 className="font-medium text-[15px]" style={{ fontFamily: "var(--font-fraunces)" }}>
                    {entry.title}
                  </h3>
                  <button
                    onClick={() => remove(entry.id)}
                    className="text-xs text-[#8FA8B2] hover:text-red-400 flex-shrink-0"
                  >
                    elimina
                  </button>
                </div>
                <div className="space-y-2">
                  {personalFields
                    .filter((f) => entry.data[f.key])
                    .map((f) => {
                      const FieldIcon = fieldIcon(f.key);
                      return (
                        <div key={f.key} className="flex items-center gap-2.5">
                          <div className="w-7 h-7 rounded-full bg-[#0B1F2A] flex items-center justify-center flex-shrink-0">
                            <FieldIcon size={13} strokeWidth={1.75} className="text-[#2CA6A4]" />
                          </div>
                          <span className="text-[12px] flex-1 text-[#8FA8B2]">{f.label}</span>
                          <span className="font-mono text-[12px]">{entry.data[f.key]}</span>
                        </div>
                      );
                    })}
                </div>
              </div>
            ))}
          </div>
        )}
          </>
        )}
      </div>
    </main>
  );
}

LENZECLIENTEOF

echo "=== File aggiornato: app/lenze/LenzeClient.tsx ==="
echo ""
echo "Tutte le menzioni de 'Il senso dell'acqua' relative ai disegni"
echo "esclusivi ora specificano '(a breve online)', per non far pensare"
echo "che il libro sia gia' acquistabile."
echo ""
echo "Ricorda: bash senso-acqua-a-breve.sh, poi:"
echo "git add -A && git commit -m 'aggiunge (a breve online) alle menzioni de Il senso dellacqua' && git push"
