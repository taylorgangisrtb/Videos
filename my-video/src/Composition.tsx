import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

// ─── Data ────────────────────────────────────────────────────────────────────
// Tampa Bay MSA (Hillsborough + Pinellas + Pasco + Hernando counties)
// Sources: U.S. Census Bureau decennial / ACS / projections
const DATA = [
  { year: "1990", value: 2067 },
  { year: "1995", value: 2255 },
  { year: "2000", value: 2396 },
  { year: "2005", value: 2603 },
  { year: "2010", value: 2783 },
  { year: "2015", value: 3003 },
  { year: "2020", value: 3175 },
  { year: "2026", value: 3480 },
];

// ─── Palette ─────────────────────────────────────────────────────────────────
const C = {
  bg: "#000000",
  surface: "#0f0f0f",
  gold: "#FFC000",
  goldLight: "#FFD44D",
  goldDark: "#B38600",
  white: "#ffffff",
  dim: "rgba(255,255,255,0.45)",
  faint: "rgba(255,255,255,0.10)",
  barGlow: "rgba(255,192,0,0.18)",
};

const FONT = "'Helvetica Neue', Helvetica, Arial, sans-serif";

// ─── Layout ───────────────────────────────────────────────────────────────────
const W = 1080;
const H = 1920;
const PAD_L = 88;
const PAD_R = 48;
const PAD_TOP = 310;
const PAD_BOT = 230;
const CHART_W = W - PAD_L - PAD_R;
const CHART_H = H - PAD_TOP - PAD_BOT;

// Bar sizing
const BAR_SLOT = CHART_W / DATA.length;
const BAR_W = BAR_SLOT * 0.62;
const BAR_INSET = (BAR_SLOT - BAR_W) / 2;

// Y axis
const Y_MIN = 1700; // chart baseline (thousands)
const Y_MAX = Math.max(...DATA.map((d) => d.value)) * 1.08;
const toY = (v: number) =>
  PAD_TOP + CHART_H - ((v - Y_MIN) / (Y_MAX - Y_MIN)) * CHART_H;

// ─── Animation timing (frames) ───────────────────────────────────────────────
const T_TITLE = 0;
const T_GRID = 35;
const T_BARS = 55;
const BAR_STAGGER = 16;
const T_FOOTER = T_BARS + DATA.length * BAR_STAGGER + 45;

// ─── Y-axis grid labels ───────────────────────────────────────────────────────
const GRID_VALS = [2000, 2500, 3000, 3500];

// ─── Bar component ────────────────────────────────────────────────────────────
const Bar: React.FC<{
  index: number;
  datum: (typeof DATA)[0];
  isLast: boolean;
}> = ({ index, datum, isLast }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const barStart = T_BARS + index * BAR_STAGGER;

  const progress = spring({
    frame: frame - barStart,
    fps,
    config: { damping: 20, stiffness: 90, mass: 0.9 },
  });

  const ratio = (datum.value - Y_MIN) / (Y_MAX - Y_MIN);
  const fullH = ratio * CHART_H;
  const barH = fullH * progress;
  const x = PAD_L + index * BAR_SLOT + BAR_INSET;
  const y = PAD_TOP + CHART_H - barH;
  const midX = x + BAR_W / 2;
  const baseY = PAD_TOP + CHART_H;

  const labelOpacity = interpolate(frame, [barStart + 18, barStart + 36], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const yearOpacity = interpolate(frame, [barStart, barStart + 22], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const displayVal = (datum.value / 1000).toFixed(2) + "M";
  const gradId = `g${index}`;
  const shineId = `s${index}`;

  return (
    <g>
      {/* glow shadow behind bar */}
      <rect
        x={x - 6}
        y={y + 6}
        width={BAR_W + 12}
        height={barH}
        fill={C.barGlow}
        rx={8}
      />

      <defs>
        <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={C.goldLight} />
          <stop offset="55%" stopColor={C.gold} />
          <stop offset="100%" stopColor={C.goldDark} />
        </linearGradient>
        <linearGradient id={shineId} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="rgba(255,255,255,0.18)" />
          <stop offset="45%" stopColor="rgba(255,255,255,0.06)" />
          <stop offset="100%" stopColor="rgba(0,0,0,0.22)" />
        </linearGradient>
      </defs>

      {/* main bar */}
      <rect x={x} y={y} width={BAR_W} height={barH} fill={`url(#${gradId})`} rx={7} />

      {/* side-shine overlay */}
      <rect x={x} y={y} width={BAR_W} height={barH} fill={`url(#${shineId})`} rx={7} />

      {/* top highlight cap */}
      <rect
        x={x + 2}
        y={y}
        width={BAR_W - 4}
        height={8}
        fill="rgba(255,255,255,0.35)"
        rx={7}
      />

      {/* bottom edge darkening line for depth */}
      <rect
        x={x}
        y={baseY - 3}
        width={BAR_W}
        height={3}
        fill={C.goldDark}
        opacity={0.6}
      />

      {/* value label */}
      <text
        x={midX}
        y={y - 18}
        fill={isLast ? C.gold : C.white}
        fontSize={isLast ? 28 : 23}
        fontWeight={isLast ? 800 : 600}
        textAnchor="middle"
        fontFamily={FONT}
        opacity={labelOpacity}
      >
        {displayVal}
      </text>

      {/* year label */}
      <text
        x={midX}
        y={baseY + 46}
        fill={isLast ? C.gold : C.dim}
        fontSize={isLast ? 27 : 23}
        fontWeight={isLast ? 700 : 500}
        textAnchor="middle"
        fontFamily={FONT}
        opacity={yearOpacity}
      >
        {datum.year}
      </text>
    </g>
  );
};

// ─── Main composition ─────────────────────────────────────────────────────────
export const MyComposition: React.FC = () => {
  const frame = useCurrentFrame();

  // Title
  const titleOpacity = interpolate(frame, [T_TITLE, T_TITLE + 22], [0, 1], {
    extrapolateRight: "clamp",
  });
  const titleY = interpolate(frame, [T_TITLE, T_TITLE + 28], [-28, 0], {
    extrapolateRight: "clamp",
  });
  const subtitleOpacity = interpolate(frame, [T_TITLE + 18, T_TITLE + 38], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Grid
  const gridOpacity = interpolate(frame, [T_GRID, T_GRID + 20], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Footer
  const footerOpacity = interpolate(frame, [T_FOOTER, T_FOOTER + 25], [0, 1], {
    extrapolateRight: "clamp",
  });

  const pctGrowth = (
    ((DATA[DATA.length - 1].value - DATA[0].value) / DATA[0].value) *
    100
  ).toFixed(1);
  const addedK = (DATA[DATA.length - 1].value - DATA[0].value).toLocaleString();

  return (
    <AbsoluteFill style={{ backgroundColor: C.bg, fontFamily: FONT }}>

      {/* Dark surface radial gradient for depth */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at 50% 40%, ${C.surface} 0%, #000 70%)`,
        }}
      />

      {/* ── Title block ── */}
      <div
        style={{
          position: "absolute",
          top: 72,
          left: PAD_L,
          right: PAD_R,
          opacity: titleOpacity,
          transform: `translateY(${titleY}px)`,
        }}
      >
        {/* eyebrow */}
        <div
          style={{
            color: C.gold,
            fontSize: 22,
            fontWeight: 700,
            letterSpacing: 5,
            textTransform: "uppercase",
            marginBottom: 14,
          }}
        >
          Population Growth
        </div>

        {/* main title */}
        <div
          style={{
            color: C.white,
            fontSize: 58,
            fontWeight: 800,
            lineHeight: 1.08,
            letterSpacing: -1,
          }}
        >
          Tampa Bay{"\n"}Region
        </div>

        {/* gold rule */}
        <div
          style={{
            width: 64,
            height: 4,
            backgroundColor: C.gold,
            borderRadius: 2,
            marginTop: 18,
            marginBottom: 14,
          }}
        />

        {/* date range */}
        <div
          style={{
            opacity: subtitleOpacity,
            color: C.dim,
            fontSize: 22,
            fontWeight: 400,
            letterSpacing: 2,
          }}
        >
          1990 — 2026
        </div>
      </div>

      {/* ── SVG chart ── */}
      <svg
        style={{ position: "absolute", top: 0, left: 0 }}
        width={W}
        height={H}
        viewBox={`0 0 ${W} ${H}`}
      >
        {/* Y-axis grid lines */}
        {GRID_VALS.map((val) => {
          const gy = toY(val);
          return (
            <g key={val} opacity={gridOpacity}>
              <line
                x1={PAD_L}
                y1={gy}
                x2={W - PAD_R}
                y2={gy}
                stroke="rgba(255,255,255,0.07)"
                strokeWidth={1.5}
                strokeDasharray="5 10"
              />
              <text
                x={PAD_L - 12}
                y={gy + 6}
                fill="rgba(255,255,255,0.32)"
                fontSize={19}
                textAnchor="end"
                fontFamily={FONT}
                fontWeight={400}
              >
                {(val / 1000).toFixed(1)}M
              </text>
            </g>
          );
        })}

        {/* Baseline */}
        <line
          x1={PAD_L}
          y1={PAD_TOP + CHART_H}
          x2={W - PAD_R}
          y2={PAD_TOP + CHART_H}
          stroke="rgba(255,192,0,0.35)"
          strokeWidth={2}
          opacity={gridOpacity}
        />

        {/* Bars */}
        {DATA.map((d, i) => (
          <Bar key={d.year} index={i} datum={d} isLast={i === DATA.length - 1} />
        ))}

        {/* Y axis rotated label */}
        <text
          x={22}
          y={PAD_TOP + CHART_H / 2}
          fill="rgba(255,255,255,0.25)"
          fontSize={18}
          fontFamily={FONT}
          fontWeight={400}
          textAnchor="middle"
          transform={`rotate(-90, 22, ${PAD_TOP + CHART_H / 2})`}
          opacity={gridOpacity}
        >
          Population (millions)
        </text>
      </svg>

      {/* ── Footer stats ── */}
      <div
        style={{
          position: "absolute",
          bottom: 60,
          left: PAD_L,
          right: PAD_R,
          opacity: footerOpacity,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-end",
        }}
      >
        {/* Growth % */}
        <div>
          <div
            style={{
              color: "rgba(255,255,255,0.38)",
              fontSize: 17,
              letterSpacing: 3,
              textTransform: "uppercase",
              marginBottom: 4,
            }}
          >
            Total Growth
          </div>
          <div
            style={{
              color: C.gold,
              fontSize: 62,
              fontWeight: 800,
              lineHeight: 1,
              letterSpacing: -1,
            }}
          >
            +{pctGrowth}%
          </div>
        </div>

        {/* Divider */}
        <div
          style={{
            width: 1,
            height: 70,
            backgroundColor: "rgba(255,192,0,0.25)",
          }}
        />

        {/* Added population */}
        <div style={{ textAlign: "right" }}>
          <div
            style={{
              color: "rgba(255,255,255,0.38)",
              fontSize: 17,
              letterSpacing: 3,
              textTransform: "uppercase",
              marginBottom: 4,
            }}
          >
            Residents Added
          </div>
          <div
            style={{
              color: C.white,
              fontSize: 44,
              fontWeight: 700,
              lineHeight: 1,
            }}
          >
            +{addedK}K
          </div>
        </div>
      </div>

      {/* ── Source note ── */}
      <div
        style={{
          position: "absolute",
          bottom: 20,
          left: PAD_L,
          right: PAD_R,
          opacity: footerOpacity * 0.5,
          color: "rgba(255,255,255,0.22)",
          fontSize: 14,
          letterSpacing: 1,
        }}
      >
        Source: U.S. Census Bureau | *2026 projected
      </div>
    </AbsoluteFill>
  );
};
