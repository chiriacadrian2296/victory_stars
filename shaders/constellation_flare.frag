#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform float uTime;
uniform float uFlareRadius;
uniform vec2 uPositions[24];
// A star's own *normalized* (0..1, within its constellation's own local
// shape space) position — stable across pan/zoom, unlike [uPositions]
// above (absolute canvas pixels, which shift continuously as the camera
// moves and the constellation's on-screen size/position changes with it).
// Used only for [starHash] below (flicker phase, rotation) — using
// [uPositions] for that instead made every star's rotation jump to a new
// value the instant the view changed, since the hash's own input value
// was changing too, not just the star's actual screen position.
uniform vec2 uSeeds[24];

out vec4 fragColor;

// The exact same glow/spike/core recipe as `nebula_particles.frag`'s own
// `flareStarLayer()` — see that function's own comments for the fuller
// explanation of each term — applied to a small, fixed set of *specific*
// star positions (a constellation's own lit stars) instead of a
// procedural lattice, the same way `sky_supernova.frag`'s own main() loops
// over its 8 fixed supernova positions rather than a lattice too. This
// replaced two earlier attempts at the same look: a shader baked once to
// a static sprite (stamped via canvas.drawAtlas — always showed a faint
// square silhouette from its own texture bounds no matter how far its
// alpha was pushed toward zero at the edge) and a hand-built Canvas
// gradient+Path approximation (a gradient only interpolates linearly
// between a handful of stops, and a filled Path has hard geometric edges
// — neither reproduces the smooth, continuous exponential falloff this
// shader computes fresh per pixel). This one is evaluated live, every
// frame, exactly like the bg stars are.
const vec3 kGold = vec3(0.9490, 0.7216, 0.2941);   // #F2B84B
const vec3 kCore = vec3(1.0, 0.98, 0.9);

// Comfortably above any real constellation's star count (shape points +
// habits) — [uPositions] entries beyond however many stars actually exist
// are set to (-1, -1) by the Dart side and skipped below via the
// `pos.x < 0.0` check, so this only ever costs a few cheap early-outs, not
// full falloff math, for the unused tail of the array.
const int kMaxStars = 24;

// Deterministic pseudo-random 0..1 from a star's own canvas position (in
// place of `nebula_particles.frag`'s per-cell hash, or `entityId` — this
// shader only ever sees positions, not ids) plus a salt so the same star
// gets several uncorrelated values from it.
float starHash(vec2 pos, float salt) {
  return fract(sin(dot(pos, vec2(12.9898, 78.233)) + salt * 37.719) * 43758.5453);
}

void main() {
  vec2 fragPos = FlutterFragCoord().xy;
  vec3 total = vec3(0.0);
  float totalAlpha = 0.0;

  for (int i = 0; i < kMaxStars; i++) {
    vec2 pos = uPositions[i];
    if (pos.x < 0.0) continue;
    vec2 seed = uSeeds[i];

    float h = starHash(seed, 1.0);
    // Same 2-sine-product occasional flicker `flareStarLayer()` and
    // `sky_supernova.frag`'s own flicker use.
    float flickerRaw = sin(uTime * 2.3 + h * 41.0) * sin(uTime * 0.9 + h * 17.0);
    float flicker = pow(clamp(flickerRaw, 0.0, 1.0), 3.0);

    // A random per-star base angle plus a slow per-star drift, computed
    // straight from this star's own hash rather than passed in — so the
    // rays don't all point the same cardinal directions, and slowly spin
    // at slightly different speeds star to star.
    float rotation = starHash(seed, 2.0) * 6.28318530718 +
        uTime * (0.08 + starHash(seed, 3.0) * 0.08);
    float cosR = cos(-rotation);
    float sinR = sin(-rotation);
    vec2 diff = fragPos - pos;
    vec2 rotated = vec2(
      diff.x * cosR - diff.y * sinR,
      diff.x * sinR + diff.y * cosR
    );
    // Normalized into "sparkle radius" units, then the *exact* same 2.2
    // scale `flareStarLayer()` itself applies to its own (already
    // roughly-unit-scale) diff — every constant below this line is a
    // direct, unmodified port of that function's own glow/spike/core
    // recipe, not a re-tuned variant of it, so this reads as the same
    // star rather than a reinterpretation of it.
    vec2 uv = (rotated / uFlareRadius) * 2.2;
    float dist = length(uv);

    float glow = exp(-dist * 9.0) * (0.7 + flicker * 0.8);
    float baseWidth = 0.045;
    float widthX = baseWidth * exp(-abs(uv.x) * 5.0);
    float widthY = baseWidth * exp(-abs(uv.y) * 5.0);
    float horizSpike = smoothstep(widthX, 0.0, abs(uv.y)) * exp(-abs(uv.x) * 5.0);
    float vertSpike = smoothstep(widthY, 0.0, abs(uv.x)) * exp(-abs(uv.y) * 5.0);
    // Baseline raised (was 0.8) — the rays read as too faint at rest,
    // between flare-ups.
    float spikes = (horizSpike + vertSpike) * (1.05 + flicker * 0.55);
    float core = smoothstep(0.1, 0.0, dist) * (1.0 + flicker * 0.5);

    vec3 color = kGold * (glow + spikes) + kCore * core * 1.5;
    float alpha = clamp(glow + spikes + core, 0.0, 1.0);

    // Additive color, max'd alpha — two overlapping stars (rare, but not
    // impossible for a dense/small constellation) brighten rather than
    // one cutting a hole through the other's glow.
    total += color * alpha;
    totalAlpha = max(totalAlpha, alpha);
  }

  fragColor = vec4(total, totalAlpha);
}
