import {
  AbsoluteFill,
  Easing,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const clamp = {
  extrapolateLeft: "clamp" as const,
  extrapolateRight: "clamp" as const,
};

const mix = (from: number, to: number, progress: number) =>
  from + (to - from) * progress;

const progress = (
  frame: number,
  start: number,
  end: number,
  easing: (value: number) => number,
) =>
  interpolate(frame, [start, end], [0, 1], {
    ...clamp,
    easing,
  });

export const LaunchFlipStudy = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const wake = 1;
  const tapAt = 0.38 * fps;
  const mouth = progress(frame, tapAt, 0.82 * fps, Easing.out(Easing.cubic));
  const flip = progress(
    frame,
    0.72 * fps,
    1.42 * fps,
    Easing.bezier(0.2, 0.78, 0.18, 1),
  );
  const insert = progress(
    frame,
    1.36 * fps,
    2.3 * fps,
    Easing.bezier(0.18, 0.82, 0.18, 1),
  );
  const bite = progress(frame, 2.02 * fps, 2.42 * fps, Easing.out(Easing.cubic));
  const settle = progress(frame, 2.32 * fps, 2.9 * fps, Easing.out(Easing.cubic));
  const glint = progress(frame, 1.32 * fps, 2.42 * fps, Easing.inOut(Easing.sin));

  const discSize = mix(246, 132, insert);
  const discX = 196 + Math.sin(insert * Math.PI) * 2;
  const discY = mix(485, 99, insert) - Math.sin(insert * Math.PI) * 30;
  const rotateX = mix(0, 86, flip) + Math.sin(bite * Math.PI) * 5;
  const faceSquash = mix(1, 0.08, flip) * mix(1, 0.74, bite);
  const faceOpacity = (1 - flip * 0.92) * (1 - bite * 0.6);
  const edgeOpacity = flip * (1 - bite * 0.22);
  const edgeWidth = mix(166, 74, insert) * mix(1, 0.62, bite);
  const edgeHeight = mix(8, 4.5, bite);
  const slotBreath = Math.sin(bite * Math.PI) * 0.16 + mouth * 0.1;

  return (
    <AbsoluteFill
      style={{
        background:
          "radial-gradient(circle at 50% 58%, rgba(220, 196, 134, 0.13), transparent 26%), #050706",
        overflow: "hidden",
      }}
    >
      <div style={statusStyle}>
        <span>8:59</span>
        <span style={{ opacity: 0.72 }}>•••  5G  ▱</span>
      </div>

      <div style={hardwareIslandStyle} />

      <div
        style={{
          ...mouthBackStyle,
          opacity: 0.18 + mouth * 0.76,
          transform: `translateX(-50%) scaleX(${1 + slotBreath}) scaleY(${1 + mouth * 0.35})`,
        }}
      />
      <div
        style={{
          ...mouthLipStyle,
          opacity: 0.16 + mouth * 0.78,
          transform: `translateX(-50%) translateY(${mix(-2, 6, bite)}px) scaleX(${mix(0.72, 1.12, mouth)}) scaleY(${mix(0.72, 0.46, bite)})`,
        }}
      />
      <div
        style={{
          ...beamStyle,
          opacity: 0.18 + mouth * 0.42 + Math.sin(bite * Math.PI) * 0.22,
          transform: `translateX(-50%) scaleX(${1 + slotBreath * 0.7})`,
        }}
      />

      <div
        style={{
          position: "absolute",
          left: discX,
          top: discY,
          width: discSize,
          height: discSize,
          transform: `translate(-50%, -50%) perspective(640px) rotateX(${rotateX}deg) rotateZ(${mix(-5, 18, insert)}deg) scaleY(${faceSquash})`,
          transformStyle: "preserve-3d",
          opacity: wake,
          filter: `brightness(${1 - insert * 0.05})`,
        }}
      >
        <DiscFace opacity={faceOpacity} />
      </div>

      <div
        style={{
          ...discEdgeStyle,
          left: discX,
          top: discY + mix(0, -8, bite),
          width: edgeWidth,
          height: edgeHeight,
          opacity: edgeOpacity,
          transform: `translate(-50%, -50%) scaleX(${mix(0.82, 1.08, flip)})`,
        }}
      />

      <div
        style={{
          ...edgeGlintStyle,
          top: discY - 1,
          opacity: edgeOpacity * (1 - bite) * 0.72,
          transform: `translate(-50%, -50%) translateX(${mix(-42, 42, glint)}px)`,
        }}
      />

      <div
        style={{
          ...occluderStyle,
          opacity: bite,
          transform: `translateX(-50%) scaleX(${mix(0.72, 1.1, bite)})`,
        }}
      />

      <div
        style={{
          ...settleGlowStyle,
          opacity: Math.sin(settle * Math.PI) * 0.26,
          transform: `translateX(-50%) scaleX(${mix(0.72, 1.16, settle)})`,
        }}
      />
    </AbsoluteFill>
  );
};

const DiscFace = ({ opacity }: { opacity: number }) => (
  <div
    style={{
      position: "absolute",
      inset: 0,
      borderRadius: "50%",
      opacity,
      background:
        "conic-gradient(from 15deg, #fffdf5, #d9fbff, #f9e7ff, #ffffd8, #dffcff, #fffdf5)",
      boxShadow:
        "0 24px 70px rgba(0,0,0,0.36), inset 0 0 0 1px rgba(255,255,255,0.74), inset 0 0 45px rgba(255,255,255,0.56)",
    }}
  >
    <div style={discRingStyle} />
    <div style={discHoleStyle} />
    <div style={discSheenStyle} />
  </div>
);

const statusStyle: React.CSSProperties = {
  position: "absolute",
  top: 54,
  left: 32,
  right: 30,
  display: "flex",
  justifyContent: "space-between",
  color: "#f6f2e6",
  fontSize: 22,
  fontWeight: 760,
  zIndex: 20,
};

const hardwareIslandStyle: React.CSSProperties = {
  position: "absolute",
  top: 15,
  left: "50%",
  width: 128,
  height: 39,
  borderRadius: 999,
  transform: "translateX(-50%)",
  background: "#000",
  boxShadow: "0 2px 14px rgba(0,0,0,0.55)",
  zIndex: 30,
};

const mouthBackStyle: React.CSSProperties = {
  position: "absolute",
  top: 72,
  left: "50%",
  width: 132,
  height: 34,
  borderRadius: 999,
  background:
    "radial-gradient(ellipse at 50% 8%, rgba(0,0,0,0.98), rgba(0,0,0,0.74) 52%, rgba(0,0,0,0.08) 74%, transparent)",
  filter: "blur(0.3px)",
  zIndex: 24,
};

const mouthLipStyle: React.CSSProperties = {
  position: "absolute",
  top: 91,
  left: "50%",
  width: 132,
  height: 10,
  borderRadius: 999,
  background:
    "linear-gradient(180deg, rgba(255,255,255,0.22), rgba(214,190,124,0.18), rgba(0,0,0,0.94))",
  boxShadow: "0 6px 14px rgba(0,0,0,0.46)",
  zIndex: 33,
};

const beamStyle: React.CSSProperties = {
  position: "absolute",
  top: 68,
  left: "50%",
  width: 136,
  height: 42,
  borderRadius: 999,
  border: "1px solid rgba(229,205,129,0.34)",
  boxShadow:
    "0 0 12px rgba(112,224,202,0.13), inset 0 0 0 1px rgba(255,255,255,0.08)",
  zIndex: 35,
};

const discEdgeStyle: React.CSSProperties = {
  position: "absolute",
  borderRadius: 999,
  background:
    "linear-gradient(90deg, rgba(255,255,255,0.85), rgba(229,197,111,0.9), rgba(130,231,213,0.76), rgba(159,174,255,0.64), rgba(255,255,255,0.72))",
  boxShadow:
    "0 0 12px rgba(128,235,216,0.24), inset 0 1px 0 rgba(255,255,255,0.5), inset 0 -1px 0 rgba(0,0,0,0.24)",
  zIndex: 29,
};

const edgeGlintStyle: React.CSSProperties = {
  position: "absolute",
  left: "50%",
  width: 34,
  height: 2,
  borderRadius: 999,
  background: "rgba(255,255,255,0.86)",
  filter: "blur(1px)",
  zIndex: 31,
};

const occluderStyle: React.CSSProperties = {
  position: "absolute",
  top: 86,
  left: "50%",
  width: 126,
  height: 28,
  borderRadius: "0 0 999px 999px",
  background:
    "linear-gradient(180deg, rgba(0,0,0,0.14), rgba(0,0,0,0.94) 42%, #000)",
  zIndex: 34,
};

const settleGlowStyle: React.CSSProperties = {
  position: "absolute",
  top: 96,
  left: "50%",
  width: 104,
  height: 18,
  borderRadius: 999,
  background:
    "radial-gradient(ellipse at 50% 0%, rgba(108,228,209,0.36), transparent 72%)",
  filter: "blur(9px)",
  zIndex: 23,
};

const discRingStyle: React.CSSProperties = {
  position: "absolute",
  inset: "18%",
  borderRadius: "50%",
  border: "2px solid rgba(255,255,255,0.58)",
};

const discHoleStyle: React.CSSProperties = {
  position: "absolute",
  left: "50%",
  top: "50%",
  width: "25%",
  height: "25%",
  borderRadius: "50%",
  transform: "translate(-50%, -50%)",
  background: "#12130f",
  boxShadow:
    "inset 0 2px 8px rgba(0,0,0,0.8), 0 0 0 4px rgba(255,255,255,0.72)",
};

const discSheenStyle: React.CSSProperties = {
  position: "absolute",
  inset: "7%",
  borderRadius: "50%",
  background:
    "linear-gradient(135deg, transparent 28%, rgba(255,255,255,0.48), transparent 55%)",
  mixBlendMode: "screen",
};
