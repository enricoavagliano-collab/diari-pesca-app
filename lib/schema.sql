-- Schema del database "Diari di Pesca".
-- Su Vercel: dalla dashboard del database (tab Storage → il tuo DB → Query),
-- incolla e esegui questo file una sola volta dopo aver collegato il database.

CREATE TABLE IF NOT EXISTS activations (
  id SERIAL PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (book_id, device_id)
);

CREATE TABLE IF NOT EXISTS diario_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_diario_book_device
  ON diario_entries (book_id, device_id);

CREATE INDEX IF NOT EXISTS idx_activations_book
  ON activations (book_id);

