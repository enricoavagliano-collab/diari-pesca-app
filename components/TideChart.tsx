"use client";

interface TidePoint {
  time: string; // HH:mm
  type: "alta" | "bassa";
  height: number;
}

function timeToMinutes(t: string): number {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}

/**
 * Disegna una curva di marea approssimata (interpolazione cosinusoidale tra i
 * punti alta/bassa reali) — non è il dato grezzo orario, ma visivamente
 * rappresenta bene l'andamento reale tra i picchi che abbiamo.
 */
export default function TideChart({ points }: { points: TidePoint[] }) {
  if (points.length < 2) return null;

  const width = 340;
  const height = 140;
  const padTop = 15;
  const padBottom = 30;
  const plotH = height - padTop - padBottom;

  const heights = points.map((p) => p.height);
  const minH = Math.min(...heights, -0.1);
  const maxH = Math.max(...heights, 0.1);
  const range = maxH - minH || 1;

  function yFor(h: number): number {
    return padTop + plotH - ((h - minH) / range) * plotH;
  }
  function xFor(minutes: number): number {
    return (minutes / 1440) * width;
  }

  // Genera la curva passando dolcemente da un punto al successivo (Catmull-Rom semplificato)
  const sorted = [...points].sort((a, b) => timeToMinutes(a.time) - timeToMinutes(b.time));
  let path = "";
  const steps = 60;
  for (let i = 0; i < sorted.length - 1; i++) {
    const p0 = sorted[i];
    const p1 = sorted[i + 1];
    const t0 = timeToMinutes(p0.time);
    const t1 = timeToMinutes(p1.time);
    for (let s = 0; s <= steps; s++) {
      const frac = s / steps;
      // Interpolazione coseno: transizione morbida tra un picco e il successivo
      const smooth = (1 - Math.cos(frac * Math.PI)) / 2;
      const h = p0.height + (p1.height - p0.height) * smooth;
      const t = t0 + (t1 - t0) * frac;
      const x = xFor(t);
      const y = yFor(h);
      path += i === 0 && s === 0 ? `M${x},${y} ` : `L${x},${y} `;
    }
  }

  return (
    <svg viewBox={`0 0 ${width} ${height}`} className="w-full" style={{ height: 150 }}>
      <path d={path} fill="none" stroke="#2CA6A4" strokeWidth={2} strokeLinecap="round" />
      {sorted.map((p, i) => {
        const x = xFor(timeToMinutes(p.time));
        const y = yFor(p.height);
        return (
          <g key={i}>
            <circle cx={x} cy={y} r={3.5} fill="#FF9A3C" />
            <text
              x={x}
              y={p.type === "alta" ? y - 9 : y + 16}
              fontSize="9"
              fill="#8FA8B2"
              textAnchor="middle"
              fontFamily="var(--font-mono)"
            >
              {p.time}
            </text>
          </g>
        );
      })}
      {[0, 6, 12, 18, 24].map((h) => (
        <text
          key={h}
          x={xFor(h * 60)}
          y={height - 6}
          fontSize="8.5"
          fill="#8FA8B2"
          textAnchor="middle"
          fontFamily="var(--font-mono)"
        >
          {String(h).padStart(2, "0")}:00
        </text>
      ))}
    </svg>
  );
}

