import { sql } from "./db";
import { BookId } from "./books";

export interface CatchEntry {
  id: string;
  specie: string;
  lunghezza?: string;
  peso?: string;
  time: string; // HH:mm
  foto?: string; // immagine compressa, salvata come data URL
  nota?: string;
  lat?: number;
  lon?: number;
  locationName?: string;
}

export interface MeteoSnapshot {
  locationName: string;
  tempC?: number;
  windSpeed?: number;
  windDirection?: number;
  pressure?: number;
  description?: string;
  icon?: string;
}

export interface DiarioEntryData {
  fields: Record<string, string>;
  catture: CatchEntry[];
  meteo?: MeteoSnapshot;
  condizioni: string[];
  note: string;
}

export interface DiarioEntry {
  id: string;
  bookId: BookId;
  deviceId: string;
  createdAt: string;
  data: DiarioEntryData;
}

function parseData(raw: unknown): DiarioEntryData {
  if (typeof raw === "string") return JSON.parse(raw);
  return raw as DiarioEntryData;
}

export async function addEntry(
  entry: Omit<DiarioEntry, "id" | "createdAt">
): Promise<DiarioEntry> {
  const [row] = await sql`
    INSERT INTO diario_entries (book_id, device_id, data)
    VALUES (${entry.bookId}, ${entry.deviceId}, ${sql.json(entry.data as unknown as never)})
    RETURNING id, book_id, device_id, data, created_at
  `;
  return {
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: parseData(row.data),
    createdAt: row.created_at.toISOString(),
  };
}

export async function getEntries(
  bookId: BookId,
  deviceId: string
): Promise<DiarioEntry[]> {
  const rows = await sql`
    SELECT id, book_id, device_id, data, created_at
    FROM diario_entries
    WHERE book_id = ${bookId} AND device_id = ${deviceId}
    ORDER BY created_at DESC
  `;
  return rows.map((row) => ({
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: parseData(row.data),
    createdAt: row.created_at.toISOString(),
  }));
}

export async function updateEntry(
  id: string,
  deviceId: string,
  data: DiarioEntryData
): Promise<DiarioEntry | null> {
  const [row] = await sql`
    UPDATE diario_entries
    SET data = ${sql.json(data as unknown as never)}
    WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id, book_id, device_id, data, created_at
  `;
  if (!row) return null;
  return {
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: parseData(row.data),
    createdAt: row.created_at.toISOString(),
  };
}

export async function deleteEntry(id: string, deviceId: string): Promise<boolean> {
  const rows = await sql`
    DELETE FROM diario_entries WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id
  `;
  return rows.length > 0;
}

