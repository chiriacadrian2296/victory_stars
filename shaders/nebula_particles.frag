#version 460 core

#include <flutter/runtime_effect.glsl>

// highp, not mediump: the hash()/valueNoise() below multiply by large
// constants (43758.5453123 etc.), which needs real precision to work —
// desktop/emulator GPUs often silently treat mediump as highp anyway
// (masking this), but real mobile GPUs (Adreno/Mali) enforce the lower
// precision, degrading the hash badly enough that the whole screen reads
// as flat near-black instead of noise.
precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uPan;
uniform float uZoom;

out vec4 fragColor;

// The app's own deep-blue "crisis gradient" tones (AppColors.dark) plus its
// gold accent — this shader is meant to feel like part of Victory Stars,
// not a generic copy of whatever reference wallpaper inspired it.
const vec3 kDeepOuter = vec3(0.0196, 0.0275, 0.0510);  // #05070D
const vec3 kDeepMid = vec3(0.0627, 0.0863, 0.1686);    // #10162B
const vec3 kDeepCenter = vec3(0.1098, 0.1529, 0.2784); // #1C2747
const vec3 kGold = vec3(0.9490, 0.7216, 0.2941);       // #F2B84B

float hash(vec2 p) {
  // Wrapping the input keeps sin()'s argument bounded — without this,
  // coordinates that grow large (through fbm's octave doubling, or just
  // uTime accumulating over a long session) push sin() into a range where
  // mobile GPUs lose enough precision to band/tile visibly, even at highp
  // (desktop/emulator GPUs mostly don't show this, which is why it wasn't
  // caught until testing on the real phone).
  p = mod(p, 289.0);
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian motion — a handful of octaves of valueNoise stacked at
// shrinking amplitude/growing frequency, which is what turns flat noise
// into the soft, cloud-like drift a nebula needs.
float fbm(vec2 p) {
  float total = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 5; i++) {
    total += amplitude * valueNoise(p);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return total;
}

// One layer of a procedural starfield: a grid of cells, each with a
// pseudo-random chance of holding a star at a pseudo-random offset within
// the cell, glowing and twinkling. No texture asset needed — every star is
// generated purely from its cell's hash.
float starLayer(vec2 uv, float density, float twinkleSpeed, float seed) {
  vec2 grid = uv * density;
  vec2 cell = floor(grid);
  vec2 local = fract(grid) - 0.5;

  float h = hash(cell + seed);
  vec2 starPos =
      (vec2(hash(cell + seed * 2.0), hash(cell + seed * 3.0)) - 0.5) * 0.7;
  float dist = length(local - starPos);

  float twinkle = 0.6 + 0.4 * sin(uTime * twinkleSpeed + h * 6.2831853);
  float brightness = step(0.8, h) * twinkle;
  return smoothstep(0.1, 0.0, dist) * brightness;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 aspectUv = vec2(uv.x * uResolution.x / uResolution.y, uv.y);

  // Pan/zoom applied here, in world space, rather than scaling the
  // rendered bitmap — since the nebula/stars are procedural (not a fixed
  // texture), this stays perfectly sharp at any zoom level instead of
  // blurring like a scaled-up image would.
  aspectUv = (aspectUv - 0.5) / uZoom + 0.5 + uPan;

  vec2 flow = aspectUv * 1.6 + vec2(uTime * 0.02, -uTime * 0.015);
  float n = fbm(flow);
  float n2 = fbm(flow * 1.7 + 4.0);

  // Mostly the deep blue palette, with gold reserved for the brightest
  // noise peaks only (pow(n2, 4.0) stays low until n2 is high, so it reads
  // as scattered highlights rather than a wash of gold across the screen).
  vec3 nebula = mix(kDeepOuter, kDeepCenter, n);
  nebula = mix(nebula, kGold, pow(n2, 4.0) * 0.65);

  float stars = 0.0;
  stars += starLayer(aspectUv, 18.0, 1.6, 1.0);
  stars += starLayer(aspectUv, 34.0, 2.3, 7.0) * 0.8;
  stars += starLayer(aspectUv, 60.0, 3.1, 13.0) * 0.6;

  vec3 color = nebula + kGold * stars;
  fragColor = vec4(color, 1.0);
}
