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
        <h2 className="font-medium text-lg" style={{ fontFamily: "var(--font-fraunces)" }}>
          Il tuo diario digitale
        </h2>
        <button
          onClick={() => setFormOpen((o) => !o)}
          className="w-8 h-8 rounded-full bg-[#2CA6A4] text-white text-lg flex items-center justify-center"
        >
          {formOpen ? "×" : "+"}
        </button>
      </div>

      {formOpen && (
        <div className="space-y-3">
          {template.map((section, i) => (
            <div key={i} className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5">
              <h4 className="text-[11px] uppercase tracking-widest text-[#2CA6A4] mb-2.5 pb-2 border-b border-white/10">
                {section.title}
              </h4>

              {"fields" in section && (
                <div className="grid grid-cols-2 gap-2.5">
                  {section.fields.map((f) => (
                    <div key={f.key} className={f.type === "textarea" ? "col-span-2" : ""}>
                      {f.label && (
                        <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">
                          {f.label}
                        </label>
                      )}
                      {f.type === "textarea" ? (
                        <textarea
                          className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A] h-16"
                          placeholder={f.placeholder}
                          value={values[f.key] || ""}
                          onChange={(e) => setField(f.key, e.target.value)}
                        />
                      ) : (
                        <input
                          type={f.type}
                          className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A]"
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
                        <th key={c.key} className="text-left text-[9px] uppercase text-[#8FA8B2] pb-1">
                          {c.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {[0, 1, 2].map((row) => (
                      <tr key={row}>
                        {section.columns.map((c) => (
                          <td key={c.key} className="border-t border-white/10 py-1">
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
                        <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">
                          {b.label}
                        </label>
                        <input
                          className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A]"
                          placeholder="note"
                          value={values[b.key] || ""}
                          onChange={(e) => setField(b.key, e.target.value)}
                        />
                      </div>
                    ))}
                  </div>
                  {section.extraField && (
                    <div className="mt-2.5">
                      <label className="block text-[10px] uppercase text-[#8FA8B2] mb-1">
                        {section.extraField.label}
                      </label>
                      <textarea
                        className="w-full border border-white/10 rounded-md px-2 py-1.5 text-sm bg-[#0B1F2A] h-16"
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

      <p className="text-[11px] uppercase tracking-widest text-[#8FA8B2] pt-2">
        Voci precedenti ({entries.length})
      </p>

      {entries.length === 0 && (
        <p className="text-sm text-[#8FA8B2]">Nessuna voce ancora — inizia dal +</p>
      )}

      {entries.map((entry) => (
        <div key={entry.id} className="bg-[#124E5A] border border-white/10 rounded-xl p-3.5">
          <div className="flex justify-between items-start mb-1.5">
            <span className="text-xs text-[#8FA8B2] font-mono">
              {new Date(entry.createdAt).toLocaleDateString("it-IT", {
                day: "2-digit",
                month: "2-digit",
                year: "numeric",
              })}
            </span>
            <button
              onClick={() => remove(entry.id)}
              className="text-xs text-[#8FA8B2] hover:text-red-600"
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
                  className="text-[11px] bg-[#0B1F2A] border border-white/10 rounded-full px-2 py-0.5"
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

