#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uForward;
uniform vec3 uRight;
uniform vec3 uUp;
uniform float uZoom;

out vec4 fragColor;

// Another alternative take on the same slot sky_decorations.frag and
// sky_wisps.frag filled before it (see NebulaScreen.build — only one of
// the three is ever wired in at a time): a single Gargantua-style black
// hole — a solid event horizon plus a tilted, glowing accretion disk whose
// light appears to wrap all the way around the horizon (a circular "halo"
// ring, standing in for real gravitational lensing without an actual
// ray-traced light-bending simulation) — modeled after a reference photo
// of exactly that look. Deliberately just one, at one fixed spot in the
// sky, for now.
//
// Unlike sky_decorations.frag/sky_wisps.frag, this is NOT purely additive
// (see the SkyBlackHole widget — plain alpha blending, not
// BlendMode.plus): a black hole has to be able to occlude whatever's
// behind it (the base starfield/nebula) with genuine opaque black, which
// an additive blend can never do — additive can only ever add light on
// top, never remove it.

float hash3(vec3 p) {
  p = mod(p, 289.0);
  return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

float valueNoise3(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  vec3 u = f * f * (3.0 - 2.0 * f);

  float c000 = hash3(i + vec3(0.0, 0.0, 0.0));
  float c100 = hash3(i + vec3(1.0, 0.0, 0.0));
  float c010 = hash3(i + vec3(0.0, 1.0, 0.0));
  float c110 = hash3(i + vec3(1.0, 1.0, 0.0));
  float c001 = hash3(i + vec3(0.0, 0.0, 1.0));
  float c101 = hash3(i + vec3(1.0, 0.0, 1.0));
  float c011 = hash3(i + vec3(0.0, 1.0, 1.0));
  float c111 = hash3(i + vec3(1.0, 1.0, 1.0));

  float x00 = mix(c000, c100, u.x);
  float x10 = mix(c010, c110, u.x);
  float x01 = mix(c001, c101, u.x);
  float x11 = mix(c011, c111, u.x);
  float y0 = mix(x00, x10, u.y);
  float y1 = mix(x01, x11, u.y);
  return mix(y0, y1, u.z);
}

float fbm3(vec3 p) {
  float total = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 4; i++) {
    total += amplitude * valueNoise3(p);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return total;
}

void main() {
  // Same free-orientation inverse-stereographic projection as
  // nebula_particles.frag — see that file's main() for the full
  // explanation of every step.
  vec2 centered = FlutterFragCoord().xy - uResolution * 0.5;
  vec2 tangent = centered / uResolution.y / uZoom;

  float tx = tangent.x;
  float ty = -tangent.y;
  float rho2 = tx * tx + ty * ty;
  float denom = 4.0 + rho2;
  vec3 dir = normalize(
    uRight * (4.0 * tx / denom) +
    uUp * (4.0 * ty / denom) +
    uForward * ((4.0 - rho2) / denom)
  );

  // Fixed world direction — one black hole, always at the same spot on
  // the sky sphere regardless of camera orientation, the same way every
  // constellation has its own fixed (never-camera-relative) spot (see
  // constellationWorldPosition in constellation_field.dart). Placed right
  // near (1,0,0) — NebulaScreen's own default camera forward direction at
  // (azimuthTurns: 0, elevationTurns: 0) — purely so it's immediately in
  // view on a fresh launch without having to pan to find it; not
  // meaningful placement otherwise at this single-object stage.
  vec3 center = normalize(vec3(1.0, 0.05, 0.0));

  vec3 reference = abs(center.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
  vec3 axisA = normalize(cross(reference, center));
  vec3 axisB = cross(center, axisA);
  vec2 uv = vec2(dot(dir - center, axisA), dot(dir - center, axisB));

  // {center, axisA, axisB} is an orthonormal basis, so both hemispheres of
  // the sphere sweep through the exact same (axisA, axisB) range — without
  // this check, [uv] can't tell "near center" from "near center's
  // antipode", and this whole object gets drawn a second time, mirrored,
  // on the far side of the sky. [hemisphereFade] (not a hard cutoff) ramps
  // this to zero smoothly just before the boundary, rather than clipping
  // off whatever brightness the disk/halo still has left there — see
  // sky_supernova.frag's identical fix for the full explanation of both.
  float hemisphereFade = smoothstep(0.0, 0.22, dot(dir, center));
  if (hemisphereFade <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  float dist = length(uv);

  // The disk's own tilt — a fixed rotation of the (u, v) plane, then a
  // squash of one axis, is what turns a circular ring into the tilted
  // ellipse look of a disk seen at an angle (like Saturn's rings drawn in
  // 2D) rather than head-on.
  float tiltAngle = 0.5;
  float cosT = cos(tiltAngle);
  float sinT = sin(tiltAngle);
  vec2 rotated = vec2(uv.x * cosT + uv.y * sinT, -uv.x * sinT + uv.y * cosT);
  float squash = 0.26;

  float horizonRadius = 0.13;
  float diskInner = horizonRadius * 1.1;
  float diskOuter = horizonRadius * 3.4;

  // The disk plane's own in-plane radius (unsquashing [rotated] first is
  // what makes this a true radius *within the tilted plane*, not just a
  // screen-space one) — slow rotation over time is the disk's own spin.
  float spin = uTime * 0.05;
  vec2 spun = vec2(
    rotated.x * cos(spin) - (rotated.y / squash) * sin(spin),
    rotated.x * sin(spin) + (rotated.y / squash) * cos(spin)
  );
  float diskRadius = length(vec2(spun.x, rotated.y / squash));
  float diskAngle = atan(spun.y, spun.x);

  // Turbulent brightness variation along the ring, so it reads as
  // swirling plasma rather than a flat gradient band — sampled in the
  // disk's own unsquashed polar space so the turbulence itself rotates
  // and stretches naturally with the ring instead of being a static
  // screen-space texture.
  float turbulence = fbm3(vec3(cos(diskAngle) * 3.0, sin(diskAngle) * 3.0, diskRadius * 8.0 - uTime * 0.15));

  float diskMask = smoothstep(diskInner, diskInner * 1.4, diskRadius) *
      smoothstep(diskOuter, diskOuter * 0.65, diskRadius);
  float thickness = squash * diskRadius * 0.6 + horizonRadius * 0.15;
  float bandMask = smoothstep(thickness, thickness * 0.25, abs(rotated.y));
  float disk = diskMask * bandMask * (0.6 + 0.4 * turbulence);

  // A circular (not squashed/tilted) halo ring right around the horizon —
  // standing in for the gravitational lensing that would otherwise bend
  // the disk's far side up and over the horizon, so the glow reads as
  // wrapping all the way around the black sphere rather than only
  // crossing its sides the way a plain tilted ring would.
  float haloRadius = horizonRadius * 1.3;
  float haloWidth = horizonRadius * 0.6;
  float halo = smoothstep(haloWidth, 0.0, abs(dist - haloRadius));

  float glow = clamp(disk * 1.4 + halo * 0.85, 0.0, 1.4);

  // Hot near-white close to the horizon, cooling through orange, with a
  // faint violet-blue tint at the outer edge — matching the reference's
  // own color progression. Uses the true circular [dist] (not the
  // squashed/tilted [diskRadius]) specifically so the halo ring — which
  // sits at a fixed *circular* radius, and would otherwise map to a huge,
  // artificially "far/cool" apparent diskRadius wherever it crosses the
  // disk plane's own squashed minor axis — reads exactly as hot as
  // anything else this close to the horizon, matching the reference's own
  // ring, which is uniformly white-hot all the way around rather than
  // cooling on two sides.
  float heat = 1.0 - clamp((dist - horizonRadius) / (diskOuter - horizonRadius), 0.0, 1.0);
  vec3 colorWarm = vec3(1.0, 0.5, 0.12);
  vec3 colorHot = vec3(1.0, 0.96, 0.88);
  vec3 colorOuter = vec3(0.55, 0.5, 0.95);
  vec3 diskColor = mix(colorWarm, colorHot, pow(heat, 2.2));
  diskColor = mix(diskColor, colorOuter, smoothstep(diskOuter * 0.6, diskOuter, dist));

  vec3 color = diskColor * glow;
  float alpha = clamp(glow, 0.0, 1.0);

  // The event horizon itself: solid opaque black, painted last so it
  // occludes the glow behind it — except along the disk's own near edge
  // ([front], the half of the tilted plane closest to the viewer), where
  // the real photo shows the bright band crossing visibly *in front of*
  // the black sphere rather than being hidden by it.
  float insideHorizon = step(dist, horizonRadius);
  float front = step(0.0, rotated.y);
  float keepGlow = front * step(0.35, bandMask);
  float paintBlack = insideHorizon * (1.0 - keepGlow);

  color = mix(color, vec3(0.0), paintBlack);
  alpha = mix(alpha, 1.0, paintBlack);
  alpha *= hemisphereFade;

  fragColor = vec4(color * alpha, alpha);
}
