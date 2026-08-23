import { sql } from "./db";
import { BookId } from "./books";

/**
 * Prova a registrare un dispositivo per un libro.
 * Ritorna { ok: true } se sbloccato (nuovo o già registrato),
 * { ok: false } se il limite dispositivi è stato raggiunto.
 */
export async function tryActivate(
  bookId: BookId,
  deviceId: string,
  maxActivations: number
): Promise<{ ok: boolean; reason?: string }> {
  // Dispositivo già registrato → sempre ok, nessun consumo di slot
  const existing = await sql`
    SELECT 1 FROM activations WHERE book_id = ${bookId} AND device_id = ${deviceId}
  `;
  if (existing.length > 0) {
    return { ok: true };
  }

  // Nuovo dispositivo: controlla il limite corrente
  const [{ count }] = await sql`
    SELECT COUNT(*)::int AS count FROM activations WHERE book_id = ${bookId}
  `;
  if (Number(count) >= maxActivations) {
    return { ok: false, reason: "Limite dispositivi raggiunto per questo codice." };
  }

  await sql`
    INSERT INTO activations (book_id, device_id) VALUES (${bookId}, ${deviceId})
    ON CONFLICT (book_id, device_id) DO NOTHING
  `;
  return { ok: true };
}

