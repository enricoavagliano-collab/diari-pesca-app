import postgres from "postgres";

// Su Vercel: collega "Vercel Postgres" dalla dashboard (tab Storage) e la
// variabile DATABASE_URL (o POSTGRES_URL) viene impostata in automatico.
// In locale: usa il file .env.local con la stessa variabile.
//
// La connessione è "pigra" (lazy): non si crea quando il file viene importato,
// solo alla prima query vera. Così l'app si pubblica anche prima di collegare
// il database — semplicemente le funzioni che lo usano daranno errore finché
// non è collegato, invece di bloccare l'intera pubblicazione.

declare global {
  // eslint-disable-next-line no-var
  var __sql: ReturnType<typeof postgres> | undefined;
}

function getSql() {
  if (global.__sql) return global.__sql;

  const connectionString =
    process.env.DATABASE_URL || process.env.POSTGRES_URL || "";

  if (!connectionString) {
    throw new Error(
      "Manca DATABASE_URL (o POSTGRES_URL). Collega un database dalla tab Storage su Vercel."
    );
  }

  const client = postgres(connectionString, {
    ssl: connectionString.includes("localhost") ? false : "require",
  });

  if (process.env.NODE_ENV !== "production") {
    global.__sql = client;
  }

  return client;
}

// Proxy: si comporta come "sql" ma crea la connessione solo al primo uso reale
export const sql = new Proxy((() => {}) as unknown as ReturnType<typeof postgres>, {
  apply(_target, _thisArg, args) {
    return (getSql() as unknown as (...a: unknown[]) => unknown)(...args);
  },
  get(_target, prop) {
    const client = getSql() as unknown as Record<string | symbol, unknown>;
    return client[prop];
  },
});