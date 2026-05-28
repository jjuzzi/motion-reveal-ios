import { AbsoluteFill, Easing, interpolate, useCurrentFrame, useVideoConfig } from "remotion";

const clamp = {
  extrapolateLeft: "clamp" as const,
  extrapolateRight: "clamp" as const,
};

const easeOut = Easing.bezier(0.16, 1, 0.3, 1);
const magnetic = Easing.bezier(0.2, 0.92, 0.18, 1);
const tuck = Easing.bezier(0.58, 0, 0.18, 1);
const settle = Easing.bezier(0.18, 1.18, 0.22, 1);

const mix = (from: number, to: number, progress: number) => from + (to - from) * progress;

const p = (
  frame: number,
  start: number,
  end: number,
  easing: (value: number) => number = easeOut,
) =>
  interpolate(frame, [start, end], [0, 1], {
    ...clamp,
    easing,
  });

export const IslandDiscRitual = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sleeveWake = p(frame, 0.06 * fps, 0.82 * fps, Easing.bezier(0.34, 1.28, 0.4, 1));
  const mouthRelease = p(frame, 0.32 * fps, 1.1 * fps, Easing.bezier(0.32, 0.02, 0.24, 1));
  const lift = p(frame, 0.5 * fps, 2.78 * fps, magnetic);
  const turn = p(frame, 1.2 * fps, 3.02 * fps, tuck);
  const finalTuck = p(frame, 2.94 * fps, 3.68 * fps, Easing.in(Easing.cubic));
  const islandSettle = p(frame, 3.34 * fps, 4.18 * fps, settle);
  const shimmer = p(frame, 0.2 * fps, 3.1 * fps, Easing.inOut(Easing.sin));
  const pullThread = p(frame, 2.72 * fps, 3.78 * fps, easeOut);
  const insertCompression = Math.sin(finalTuck * Math.PI) * (1 - islandSettle * 0.3);
  const emergencePop = Math.sin(mouthRelease * Math.PI);
  const coverWake = p(frame, 0.02 * fps, 0.72 * fps, Easing.bezier(0.25, 1.24, 0.34, 1));
  const sourceBeam = p(frame, 0.28 * fps, 1.46 * fps, Easing.inOut(Easing.sin));
  const catchBeam = p(frame, 2.92 * fps, 3.74 * fps, Easing.inOut(Easing.sin));
  const catchPrep = p(frame, 2.62 * fps, 3.08 * fps, Easing.bezier(0.22, 1, 0.36, 1));
  const catchImpact = p(frame, 3.0 * fps, 3.32 * fps, Easing.bezier(0.18, 1.42, 0.22, 1));
  const catchAbsorb = p(frame, 3.14 * fps, 3.82 * fps, settle);
  const catchSnap = Math.sin(catchImpact * Math.PI) * Math.pow(1 - catchAbsorb, 0.54);
  const catchHold = catchPrep * (1 - catchAbsorb);
  const traceFade = 1 - p(frame, 3.15 * fps, 3.54 * fps, Easing.in(Easing.cubic));

  const discX = mix(194, 196, lift) + Math.sin(lift * Math.PI) * 5;
  const discY = mix(602, 128, lift) - 28 * Math.sin(lift * Math.PI) - finalTuck * 42;
  const discScale = mix(1.07, 0.57, turn) * mix(1, 0.86, finalTuck) + emergencePop * 0.035;
  const discRotateX = mix(0, 82, turn) + insertCompression * 8;
  const discRotateZ = mix(-13, 28, lift) + 4.5 * Math.sin(frame / 7.4) * (1 - finalTuck);
  const discSquash = mix(1, 0.88, turn) * mix(1, 0.68, finalTuck);
  const discOpacity = 1 - Math.pow(finalTuck, 0.82) * 0.98;
  const contactY = mix(612, 154, lift) - finalTuck * 22;
  const contactOpacity = (0.22 + (1 - lift) * 0.56 + insertCompression * 0.2) * (1 - finalTuck);
  const sleeveOpen = 1 - p(frame, 1.15 * fps, 2.15 * fps, Easing.inOut(Easing.cubic)) * 0.55;
  const mouthMaskOpacity = (0.34 - mouthRelease * 0.3) * (1 - lift * 0.46);
  const slotPulse = Math.sin(islandSettle * Math.PI);
  const islandBreathe = insertCompression * 0.12 + catchSnap * 0.22 + slotPulse * 0.08;
  const irisOpacity = Math.max(emergencePop * 0.38 * (1 - lift), slotPulse * 0.34, catchSnap * 0.58);
  const sourceTilt = -4 + coverWake * 4 + Math.sin(frame / 24) * 0.65 * (1 - lift);
  const imageColorShift = Math.sin(frame / 38) * 0.5 + 0.5;
  const swallowedEdge = Math.max(catchHold * 0.34, insertCompression * 0.26) * Math.pow(1 - catchAbsorb, 1.75);
  const cameraDriftX = Math.sin(frame / 42) * 1.8 + catchSnap * -0.8;
  const cameraDriftY = Math.cos(frame / 55) * 1.1 + catchSnap * 0.6;
  const stageFocus = p(frame, 0.12 * fps, 0.9 * fps, Easing.bezier(0.22, 1, 0.36, 1));

  return (
    <AbsoluteFill className="scene">
      <div
        className="capture-frame"
        style={{
          transform: `translate(${cameraDriftX}px, ${cameraDriftY}px) rotateX(${catchSnap * 0.18}deg) rotateY(${cameraDriftX * 0.03}deg)`,
        }}
      >
        <div
          className="image-color-field"
          style={{
            opacity: 0.2 + sleeveWake * 0.08,
            transform: `translate(-50%, -50%) rotate(${mix(-4, 8, imageColorShift)}deg) scale(${mix(1, 1.08, imageColorShift)})`,
          }}
        />
        <div
          className="studio-surface"
          style={{
            opacity: 0.12 + stageFocus * 0.24,
            transform: `translate(-50%, -50%) rotateX(64deg) translateY(${mix(18, 0, stageFocus)}px)`,
          }}
        />
        <div className="device-glass" />
        <div
          className="screen-vignette"
          style={{
            opacity: 0.24 + insertCompression * 0.18,
          }}
        />
        <div className="ambient-grain" />
        <div className="status-row">
          <span>12:46</span>
          <span className="status-icons">•••  5G  ▱</span>
        </div>

        <div
        className="hardware-island"
        style={{
          transform: `translateX(-50%) translateY(${catchSnap * 1.8}px) scaleX(${1 + islandBreathe}) scaleY(${1 + islandBreathe * 0.42})`,
        }}
      />
      <div
        className="island-elastic-lip"
        style={{
          opacity: catchHold * 0.68,
          transform: `translateX(-50%) translateY(${mix(-2, 7, catchImpact)}px) scaleX(${mix(0.42, 1.02, catchPrep)}) scaleY(${mix(0.18, 0.92, catchSnap)})`,
        }}
      />
      <div
        className="hardware-throat"
        style={{
          opacity: 0.18 + finalTuck * 0.58 + catchHold * 0.2,
          transform: `translateX(-50%) scaleX(${mix(0.72, 1.1, Math.max(finalTuck, catchPrep))}) scaleY(${mix(0.46, 1.08, Math.max(finalTuck, catchSnap))})`,
        }}
      />
      <div
        className="slot-pressure"
        style={{
          opacity: Math.max(slotPulse * 0.36, catchSnap * 0.46) * Math.pow(1 - catchAbsorb, 0.8),
          transform: `translateX(-50%) scaleX(${mix(0.54, 1.18, Math.max(slotPulse, catchSnap))})`,
        }}
      />
      <div
        className="swallowed-edge"
        style={{
          opacity: swallowedEdge,
          transform: `translateX(-50%) translateY(${mix(8, -5, catchAbsorb)}px) scaleX(${mix(0.62, 0.96, catchSnap)}) scaleY(${mix(0.12, 0.64, catchHold)})`,
        }}
      />
      <div
        className="catch-ripple"
        style={{
          opacity: catchSnap * 0.26 * Math.pow(1 - catchAbsorb, 0.7),
          transform: `translateX(-50%) scaleX(${mix(0.62, 1.24, catchImpact)}) scaleY(${mix(0.42, 1.0, catchImpact)})`,
        }}
      />
      <div
        className="island-border-beam"
        style={{
          opacity: Math.max(catchBeam * (1 - islandSettle * 0.84) * 0.14, catchSnap * 0.18) * Math.pow(1 - catchAbsorb, 0.64),
          transform: `translateX(-50%) rotate(${mix(18, 230, catchBeam)}deg) scaleX(${mix(0.7, 1.02, insertCompression)})`,
        }}
      />
      <div
        className="island-iris"
        style={{
          opacity: irisOpacity,
          transform: `translate(-50%, -50%) scale(${mix(0.7, 1.45, Math.max(emergencePop, slotPulse))}) rotate(${mix(-12, 18, shimmer)}deg)`,
        }}
      />

      <div
        className="pull-thread"
        style={{
          opacity: pullThread * 0.16 * traceFade,
          transform: `translate(-50%, ${mix(-10, 12, pullThread)}px) scaleY(${mix(0.08, 0.42, pullThread)})`,
        }}
      />

      <div
        className="source-glow"
        style={{
          opacity: 0.24 * sleeveWake * (1 - finalTuck),
          transform: `translate(-50%, -50%) scale(${mix(0.78, 1.12, sleeveWake)})`,
        }}
      />
      <div
        className="source-iris"
        style={{
          opacity: emergencePop * 0.42 * (1 - lift * 0.72),
          transform: `translate(-50%, -50%) scale(${mix(0.72, 1.34, emergencePop)}) rotate(${mix(-20, 16, shimmer)}deg)`,
        }}
      />
      <div
        className="album-object"
        style={{
          opacity: 0.18 + coverWake * 0.82,
          transform: `translate(-50%, -50%) translateY(${mix(28, 0, coverWake)}px) rotateX(58deg) rotateZ(${sourceTilt}deg) scale(${mix(0.92, 1, coverWake)})`,
        }}
      >
        <div className="album-depth" />
        <div className="album-cover">
          <div
            className="album-border-beam"
            style={{
              opacity: sourceBeam * (1 - lift * 0.52),
              transform: `rotate(${mix(18, 326, sourceBeam)}deg)`,
            }}
          />
          <div className="album-art" />
          <div className="album-papergrain" />
          <div className="album-label">
            <span />
            <span />
          </div>
          <div className="album-track-strip">
            <i />
            <i />
            <i />
            <i />
            <i />
            <i />
          </div>
        </div>
        <div className="album-mouth-shadow" />
      </div>

      <div
        className="sleeve-stack"
        style={{
          transform: `translate(-50%, -50%) translateY(${mix(18, 0, sleeveWake)}px) scale(${mix(0.94, 1, sleeveWake)})`,
          opacity: 0.28 + sleeveWake * 0.72,
        }}
      >
        <div className="sleeve-shadow" />
        <div className="sleeve-body">
          <div className="sleeve-fabric" />
          <div
            className="sleeve-slit"
            style={{
              transform: `translateX(-50%) scaleX(${mix(0.62, 1.0, sleeveWake)}) scaleY(${sleeveOpen})`,
            }}
          />
          <div className="sleeve-lip" />
          <div
            className="sleeve-inner-shadow"
            style={{
              opacity: 0.42 + mouthRelease * 0.2,
            }}
          />
        </div>
      </div>

      <div
        className="disc-contact"
        style={{
          top: contactY + insertCompression * -28,
          opacity: contactOpacity,
          transform: `translate(-50%, -50%) scaleX(${mix(1.18, 0.56, turn)}) scaleY(${mix(1, 0.38, turn)})`,
        }}
      />

      <div
        className="disc-flight"
        style={{
          left: discX,
          top: discY,
          opacity: discOpacity,
          transform: `translate(-50%, -50%) perspective(560px) rotateX(${discRotateX}deg) rotateZ(${discRotateZ}deg) scale(${discScale}) scaleY(${discSquash})`,
        }}
      >
        <div className="disc-rim" />
        <div
          className="disc-side-band"
          style={{
            opacity: turn * (1 - finalTuck * 0.42),
            transform: `translate(-50%, -50%) scaleX(${mix(0.66, 1.08, turn)}) scaleY(${mix(0.38, 0.82, finalTuck)})`,
          }}
        />
        <div
          className="disc-face"
          style={{
            backgroundPosition: `${mix(10, 78, shimmer)}% ${mix(42, 56, Math.sin(frame / 16) * 0.5 + 0.5)}%`,
            opacity: 1 - turn * 0.28,
          }}
        >
          <div className="disc-arc disc-arc-a" />
          <div className="disc-arc disc-arc-b" />
          <div className="disc-hole" />
          <div className="disc-sheen" />
        </div>
      </div>

      <div
        className="edge-glint"
        style={{
          opacity: turn * (1 - finalTuck) * 0.86,
          top: discY,
          transform: `translate(-50%, -50%) rotate(${mix(-8, 2, turn)}deg) scaleX(${mix(0.6, 1.18, turn)}) scaleY(${mix(0.8, 1.2, insertCompression)})`,
        }}
      />

      <div
        className="sleeve-mouth-mask"
        style={{
          opacity: mouthMaskOpacity,
          transform: `translate(-50%, -50%) translateY(${mix(10, 0, sleeveWake)}px) scaleX(${mix(0.9, 1.02, mouthRelease)})`,
        }}
      >
        <div className="sleeve-mask-lip" />
      </div>

      <div
        className="occlusion-fade"
        style={{
          opacity: finalTuck,
        }}
      />
      </div>
    </AbsoluteFill>
  );
};
