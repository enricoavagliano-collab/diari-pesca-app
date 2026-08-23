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

