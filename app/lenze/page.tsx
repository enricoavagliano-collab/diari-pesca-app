import { cookies } from "next/headers";
import LenzeClient from "./LenzeClient";

export default async function LenzePage() {
  const cookieStore = await cookies();
  const unlockedMare = cookieStore.get("unlock_mare-e-foce")?.value === "1";
  const unlockedFeeder = cookieStore.get("unlock_feeder")?.value === "1";

  return <LenzeClient unlockedMare={unlockedMare} unlockedFeeder={unlockedFeeder} />;
}

