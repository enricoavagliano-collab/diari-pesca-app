import { sql } from "./db";
import { BookId } from "./books";

export interface DiarioEntry {
  id: string;
  bookId: BookId;
  deviceId: string;
  createdAt: string;
  data: Record<string, string>;
}

export async function addEntry(
  entry: Omit<DiarioEntry, "id" | "createdAt">
): Promise<DiarioEntry> {
  const [row] = await sql`
    INSERT INTO diario_entries (book_id, device_id, data)
    VALUES (${entry.bookId}, ${entry.deviceId}, ${sql.json(entry.data)})
    RETURNING id, book_id, device_id, data, created_at
  `;
  return {
    id: row.id,
    bookId: row.book_id,
    deviceId: row.device_id,
    data: row.data,
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
    data: row.data,
    createdAt: row.created_at.toISOString(),
  }));
}

export async function deleteEntry(id: string, deviceId: string): Promise<boolean> {
  const rows = await sql`
    DELETE FROM diario_entries WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id
  `;
  return rows.length > 0;
}

