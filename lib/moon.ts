import * as Astronomy from "astronomy-engine";

export interface MoonData {
  phaseName: string;
  illuminationPercent: number;
  moonrise: string | null; // HH:mm locale, null se non sorge in quel giorno
  moonset: string | null;
  upperTransit: string | null; // "transito superiore" — la luna è più alta in cielo
  lowerTransit: string | null; // "transito inferiore" — la luna è opposta, sotto l'orizzonte
}

const PHASE_NAMES = [
  { max: 1, name: "Luna nuova" },
  { max: 49, name: "Luna crescente" },
  { max: 51, name: "Primo quarto" },
  { max: 99, name: "Gibbosa crescente" },
  { max: 100.01, name: "Luna piena" },
];

function phaseNameFromAngle(phaseAngleDeg: number, illumination: number): string {
  // phaseAngleDeg: 0 = luna nuova, 180 = luna piena, cresce 0→360 in un ciclo
  const waxing = phaseAngleDeg < 180;
  if (illumination < 1.5) return "Luna nuova";
  if (illumination > 98.5) return "Luna piena";
  if (Math.abs(illumination - 50) < 3) {
    return waxing ? "Primo quarto" : "Ultimo quarto";
  }
  if (illumination < 50) {
    return waxing ? "Luna crescente" : "Luna calante";
  }
  return waxing ? "Gibbosa crescente" : "Gibbosa calante";
}

function formatTime(date: Date | null, timezone: string): string | null {
  if (!date) return null;
  return date.toLocaleTimeString("it-IT", {
    hour: "2-digit",
    minute: "2-digit",
    timeZone: timezone,
  });
}

export function getMoonData(
  lat: number,
  lon: number,
  date: Date,
  timezone: string
): MoonData {
  const observer = new Astronomy.Observer(lat, lon, 0);

  // Fase e illuminazione
  const illumInfo = Astronomy.Illumination(Astronomy.Body.Moon, date);
  const illuminationPercent = Math.round(illumInfo.phase_fraction * 100);
  const phaseAngle = Astronomy.MoonPhase(date); // 0-360

  // Alba/tramonto lunare: cerca eventi nelle 24h a partire da inizio giornata locale
  const startOfDay = new Date(date);
  startOfDay.setUTCHours(0, 0, 0, 0);

  let moonrise: Date | null = null;
  let moonset: Date | null = null;
  try {
    const riseEvent = Astronomy.SearchRiseSet(
      Astronomy.Body.Moon,
      observer,
      +1,
      startOfDay,
      1
    );
    moonrise = riseEvent ? riseEvent.date : null;
  } catch {
    moonrise = null;
  }
  try {
    const setEvent = Astronomy.SearchRiseSet(
      Astronomy.Body.Moon,
      observer,
      -1,
      startOfDay,
      1
    );
    moonset = setEvent ? setEvent.date : null;
  } catch {
    moonset = null;
  }

  // Transito superiore (culminazione, la luna passa per il meridiano, punto più alto)
  // e transito inferiore (12h circa dopo/prima, punto opposto)
  let upperTransit: Date | null = null;
  let lowerTransit: Date | null = null;
  try {
    const upper = Astronomy.SearchHourAngle(
      Astronomy.Body.Moon,
      observer,
      0,
      startOfDay,
      1
    );
    upperTransit = upper ? upper.time.date : null;
  } catch {
    upperTransit = null;
  }
  try {
    const lower = Astronomy.SearchHourAngle(
      Astronomy.Body.Moon,
      observer,
      12,
      startOfDay,
      1
    );
    lowerTransit = lower ? lower.time.date : null;
  } catch {
    lowerTransit = null;
  }

  return {
    phaseName: phaseNameFromAngle(phaseAngle, illuminationPercent),
    illuminationPercent,
    moonrise: formatTime(moonrise, timezone),
    moonset: formatTime(moonset, timezone),
    upperTransit: formatTime(upperTransit, timezone),
    lowerTransit: formatTime(lowerTransit, timezone),
  };
}

