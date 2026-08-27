// Helper server-side per aggiungere un contatto a Brevo.
// La API key NON deve mai essere esposta al client: questo file va
// importato solo da route handler lato server (app/api/.../route.ts).

type BookKey = "feeder" | "marefoce";

const LIST_ID_BY_BOOK: Record<BookKey, string | undefined> = {
  feeder: process.env.BREVO_LIST_ID_FEEDER,
  marefoce: process.env.BREVO_LIST_ID_MAREFOCE,
};

export interface SubscribeResult {
  ok: boolean;
  status: number;
  error?: string;
}

export async function subscribeToBrevo(
  email: string,
  book: BookKey
): Promise<SubscribeResult> {
  const apiKey = process.env.BREVO_API_KEY;
  const listId = LIST_ID_BY_BOOK[book];

  if (!apiKey) {
    return { ok: false, status: 500, error: "BREVO_API_KEY mancante" };
  }
  if (!listId) {
    return { ok: false, status: 500, error: `Lista Brevo non configurata per '${book}'` };
  }

  const res = await fetch("https://api.brevo.com/v3/contacts", {
    method: "POST",
    headers: {
      "api-key": apiKey,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      email,
      listIds: [Number(listId)],
      // Se il contatto esiste già, lo aggiorna invece di fallire con 400
      updateEnabled: true,
      attributes: {
        LIBRO: book === "feeder" ? "Feeder" : "Mare e Foce",
        FONTE: "app_diari_pesca",
      },
    }),
  });

  if (res.ok || res.status === 204) {
    return { ok: true, status: res.status };
  }

  // Brevo risponde 400 con code "duplicate_parameter" se il contatto
  // esiste già con updateEnabled=false; con updateEnabled=true questo
  // in teoria non dovrebbe accadere, ma lo gestiamo comunque.
  let errorText = "";
  try {
    const data = await res.json();
    errorText = data?.message || JSON.stringify(data);
  } catch {
    errorText = await res.text();
  }

  return { ok: false, status: res.status, error: errorText };
}

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export type { BookKey };
