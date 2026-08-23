import postgres from "postgres";

// Su Vercel: collega "Vercel Postgres" dalla dashboard (tab Storage) e la
// variabile DATABASE_URL (o POSTGRES_URL) viene impostata in automatico.
// In locale: usa il file .env.local con la stessa variabile.
const connectionString =
  process.env.DATABASE_URL || process.env.POSTGRES_URL || "";

if (!connectionString) {
  throw new Error(
    "Manca DATABASE_URL (o POSTGRES_URL). Collega un database o aggiungi .env.local."
  );
}

// Una sola connessione condivisa in tutta l'app (pattern consigliato su serverless)
declare global {
  // eslint-disable-next-line no-var
  var __sql: ReturnType<typeof postgres> | undefined;
}

export const sql =
  global.__sql ||
  postgres(connectionString, {
    ssl: connectionString.includes("localhost") ? false : "require",
  });

if (process.env.NODE_ENV !== "production") {
  global.__sql = sql;
}

