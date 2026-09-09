#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
// World-units-to-pixels for the glow math below — chosen in Dart so the
// shader's own fixed ringRadius (0.09 world units) lands at whatever
// pixel radius the caller wants (see `_MenuStarButton`: sized to match
// the icon drawn on top of this).
uniform float uScale;

out vec4 fragColor;

// One ray, tapering as it goes, extending in only *one* direction from
// center (unlike sky_supernova.frag's own horiz/vert/diag spikes, each
// really a bidirectional line straight through center) — a 5-pointed
// star has no opposite-side symmetry to mirror through, so each of its
// 10 vertices gets its own ray rather than sharing one line with another
// vertex 180 degrees away.
float uniRay(vec2 v, float angle, float baseW, float taperRate, float falloffRate) {
  float c = cos(angle);
  float s = sin(angle);
  float along = max(v.x * c + v.y * s, 0.0);
  float perp = -v.x * s + v.y * c;
  float width = baseW * exp(-along * taperRate);
  return smoothstep(width, 0.0, abs(perp)) * exp(-along * falloffRate);
}

// One fixed supernova glow — the same look shaders/sky_supernova.frag
// draws for each of the 8 life areas (see that file for the fuller
// per-term reasoning behind every one of these: glow, ring, a four-point
// star core, tapered four-point cross spikes, all the same shared gold),
// but with the 3D sky-direction/camera projection stripped out entirely.
// This decoration never moves with the sky — it always sits fixed right
// behind the menu button — so it has no camera to project through in the
// first place; [uv] here is just this canvas's own centered, scaled 2D
// coordinate.
vec3 supernovaGlow(vec2 uv, vec3 midColor, vec3 outerColor, float maxRadius) {
  float dist = length(uv);

  // A touch gentler than sky_supernova.frag's own 0.94/0.06 — that pulse
  // reads fine spread across a whole life area's worth of sky, but once
  // [glow]/[nearGlow] below were brought back up closer to that file's
  // own strength, the same swing here was rocking the button's own
  // brightness harder than a small, always-on control should.
  float pulse = 0.955 + 0.045 * sin(uTime * 0.6);

  // Strength brought back up from this button's first, too-washed-out
  // pass (0.5/0.55) toward sky_supernova.frag's own 0.9/1.1 — not all
  // the way, since the icon sitting right on top of this glow (unlike
  // the open sky around a real supernova) still needs the ring to read
  // as its own distinct thing rather than melting into one blob. [glow]'s
  // own reach is pulled way in too (rate 3.0 -> 18.0): it's the soft
  // background disc behind everything else here, and at the old, much
  // slower decay it kept glowing well past `ringRadius`, past where a
  // "glow around the ring" should still read as tucked behind it.
  float glow = exp(-dist * 18.0) * 0.7;
  // [nearGlow] is the star's own center glow — pushed hard past even
  // sky_supernova.frag's own 1.1, since asked for outright strong rather
  // than "brought back toward the original" — eased down just a hair
  // from that first strong pass.
  float nearGlow = exp(-dist * 22.0) * 1.9;

  // Thinned from 0.014, and now white rather than the shared gold —
  // [ring] gets its own weight in the colorCore mix below instead of
  // just adding brightness under whatever color [glow]/[spikes] mixed
  // to, the same way the real supernovas' own outer ring (the fixed
  // one, drawn in Dart — see `SkySupernova._paintOutlineIcon`'s
  // [outlinePainter] — while the glow *inside* it is what spins) reads
  // as a bright white band around a warmer glow rather than a gold one.
  // Strong enough on its own, and added to [brightness] below *after*
  // [pulse] rather than as part of the sum [pulse] scales, to read as a
  // full, steady line rather than something that breathes with
  // everything else behind it — pulled back from fully opaque (1.6) to
  // 80%, matching [Icons.star]'s own opacity right on top of it.
  float ringRadius = 0.09;
  float ring = smoothstep(0.008, 0.0, abs(dist - ringRadius)) * 1.28;
  // A softer halo just around [ring] itself — wider and dimmer than the
  // crisp line, warm rather than forced white (it skips the colorCore
  // mix below, same as [glow]) — so the ring reads as glowing, not just
  // as a hard-edged stroke.
  float ringGlow = exp(-abs(dist - ringRadius) * 35.0) * 0.5;

  // [Icons.star]'s glyph isn't drawn around the exact center of its own
  // em-square: measuring its actual path (a regular pentagram fits its
  // 5 tips to within a fraction of a degree once you do), the glyph's
  // true center sits about half a unit further down its 24-unit grid
  // than the box TextPainter centers on this canvas — worth correcting
  // for here since it's exactly the kind of few-degree miss that made
  // the rays look *close* to the points but not quite on them. Rays are
  // aimed from that true center instead of straight uv (0,0).
  vec2 rayUv = uv - vec2(0.0, 0.0043);

  // The 10 vertices of a 5-pointed star (screen angle, radians): 5 outer
  // "points" every 72 degrees starting straight up (-90 degrees, i.e.
  // -pi/2 — up is -y in this Y-down screen space), and 5 inner "valley"
  // vertices offset 36 degrees (pi/5) from those, right in between each
  // consecutive pair. On screen, [Icons.star]'s own glyph vertices land
  // on the *inner* angle here, not the outer one — the opposite
  // assumption had the long/bright rays shooting from the valleys and
  // the short/dim ones from the points, backwards from how a twinkling
  // star should read — so the inner angle gets the main (brighter,
  // longer) rays and the outer angle gets the secondary (dimmer,
  // shorter) ones. Both sized way down from the first pass (tuned for a
  // supernova far from the icon drawn on top of it, way too big for one
  // sitting right behind it) and shortened again since, three times over
  // now — each pass roughly halving the reach of the one before it. The
  // main rays' own taper is steeper still on top of that, so they thin
  // out faster toward their own tips instead of holding a near-constant
  // width.
  float spikes = 0.0;
  for (int k = 0; k < 5; k++) {
    float outerAngle = -1.5707963 + float(k) * 1.2566371;
    float innerAngle = outerAngle + 0.6283185;
    spikes += uniRay(rayUv, innerAngle, 0.005, 17.0, 100.0) * 1.4;
    spikes += uniRay(rayUv, outerAngle, 0.0025, 24.0, 150.0) * 0.4;
  }

  float starMetric = sqrt(abs(uv.x)) + sqrt(abs(uv.y));
  float core = smoothstep(0.22, 0.0, starMetric);

  float brightness = (
      core * 2.2 +
      spikes +
      glow + nearGlow + ringGlow
    ) * pulse + ring;

  // A safety net regardless of how [glow]/[spikes] above happen to be
  // tuned: this canvas is a small, fixed square (see
  // `_MenuStarButton._glowCanvasSize`), and any term whose value is
  // still nonzero right at that square's edge stops dead the instant
  // the canvas does — a faint but sharp square silhouette around the
  // button instead of a glow fading into nothing. Ramping brightness
  // down to exactly 0 before [dist] reaches the canvas edge (in these
  // same world units) removes that edge rather than just hiding it
  // better.
  brightness *= 1.0 - smoothstep(maxRadius * 0.6, maxRadius, dist);

  vec3 colorCore = vec3(1.0, 0.98, 0.9);
  vec3 color = mix(outerColor, midColor, smoothstep(0.0, 0.25, glow + spikes * 0.3));
  color = mix(color, colorCore, clamp(core * 1.5 + nearGlow * 0.3 + ring * 0.96, 0.0, 1.0));

  return color * brightness;
}

void main() {
  vec2 centered = FlutterFragCoord().xy - uResolution * 0.5;
  vec2 uv = centered / uScale;

  vec3 midColor = vec3(1.0, 0.78, 0.4);
  vec3 outerColor = vec3(0.85, 0.5, 0.15);
  // Canvas is square (uResolution.x == uResolution.y), in the same
  // world units as [uv] — the radius the glow must fade to 0 within.
  float maxRadius = uResolution.x * 0.5 / uScale;

  vec3 total = supernovaGlow(uv, midColor, outerColor, maxRadius);
  fragColor = vec4(total, 1.0);
}
