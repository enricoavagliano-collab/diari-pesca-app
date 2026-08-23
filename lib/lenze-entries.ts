import { sql } from "./db";
import { LenzaCategory } from "./lenze-official";

export interface LenzaEntry {
  id: string;
  deviceId: string;
  category: LenzaCategory;
  title: string;
  data: Record<string, string>;
  createdAt: string;
}

export async function addLenza(
  entry: Omit<LenzaEntry, "id" | "createdAt">
): Promise<LenzaEntry> {
  const [row] = await sql`
    INSERT INTO lenze_entries (device_id, category, title, data)
    VALUES (${entry.deviceId}, ${entry.category}, ${entry.title}, ${sql.json(entry.data)})
    RETURNING id, device_id, category, title, data, created_at
  `;
  return {
    id: row.id,
    deviceId: row.device_id,
    category: row.category,
    title: row.title,
    data: row.data,
    createdAt: row.created_at.toISOString(),
  };
}

export async function getLenze(
  deviceId: string,
  category: LenzaCategory
): Promise<LenzaEntry[]> {
  const rows = await sql`
    SELECT id, device_id, category, title, data, created_at
    FROM lenze_entries
    WHERE device_id = ${deviceId} AND category = ${category}
    ORDER BY created_at DESC
  `;
  return rows.map((row) => ({
    id: row.id,
    deviceId: row.device_id,
    category: row.category,
    title: row.title,
    data: row.data,
    createdAt: row.created_at.toISOString(),
  }));
}

export async function deleteLenza(id: string, deviceId: string): Promise<boolean> {
  const rows = await sql`
    DELETE FROM lenze_entries WHERE id = ${id} AND device_id = ${deviceId}
    RETURNING id
  `;
  return rows.length > 0;
}

