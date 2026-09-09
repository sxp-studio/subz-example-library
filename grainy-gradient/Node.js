// Grainy Gradient: a two-color gradient with film grain over it. No input texture — a source.
// The same node as Node.swift, one contract for both: uv is flipped to a top-left origin so `angle`
// means the same thing on either platform, and the knobs read from the same port names.

const SHADER = `
uniform vec4 uTop;
uniform vec4 uBottom;
uniform float uAngle;
uniform float uSoftness;
uniform float uGrain;
uniform float uGrainSize;

// A cheap per-pixel hash, no trig. The obvious fract(sin(dot(...))) one correlates along
// diagonals and shows up as a weave at low amplitudes.
float hash(vec2 p) {
  vec3 q = fract(vec3(p.x, p.y, p.x) * 0.1031);
  q += dot(q, q.yzx + 33.33);
  return fract((q.x + q.y) * q.z);
}

void main() {
  vec2 uv = vec2(vUv.x, 1.0 - vUv.y);   // top-left origin, so angle matches Node.swift
  vec2 dir = vec2(cos(uAngle), sin(uAngle));
  // Project onto the gradient direction and normalise, so the ramp spans the frame at any angle
  // rather than running out early on the diagonal.
  float extent = abs(dir.x) + abs(dir.y);
  float t = clamp(dot(uv - 0.5, dir) / extent + 0.5, 0.0, 1.0);
  t = mix(t, smoothstep(0.0, 1.0, t), clamp(uSoftness, 0.0, 1.0));
  vec3 colour = mix(uTop.rgb, uBottom.rgb, t);

  // Grain, redrawn per frame so it shimmers instead of sitting still.
  float size = max(uGrainSize, 0.5);
  vec2 cell = floor(uv * uResolution / size) + floor(uTime * 60.0) * vec2(37.0, 62.9);
  float n = hash(cell) - 0.5;
  // Strongest in the midtones, so the darks stay clean and the lights do not blow out.
  float shape = 1.0 - abs(t - 0.5) * 1.2;
  colour += n * uGrain * shape;
  fragColor = vec4(clamp(colour, 0.0, 1.0), 1.0);
}`;

export default class Node {
  setup(ctx) {
    // Nothing to build: shaderPass caches its material per source string.
  }

  update(ctx) {
    ctx.shaderPass(SHADER, {
      uTop: rgb(ctx.inputFloats("topColor"), [0.98, 0.45, 0.36]),
      uBottom: rgb(ctx.inputFloats("bottomColor"), [0.20, 0.16, 0.42]),
      uAngle: (ctx.inputFloat("angle") ?? 20) * Math.PI / 180,
      uSoftness: ctx.inputFloat("softness") ?? 0.5,
      uGrain: ctx.inputFloat("grain") ?? 0.14,
      uGrainSize: ctx.inputFloat("grainSize") ?? 1.0,
    }, ctx.outputTexture("output"));
  }
}

// A colorRGB input arrives as 3 numbers; guard the count before trusting it.
function rgb(v, fallback) {
  const c = v && v.length >= 3 ? v.slice(0, 3) : fallback;
  return [c[0], c[1], c[2], 1];
}
