# Grainy Gradient — `grainy-gradient`

A two-color gradient with film grain over it, as a texture source: no input, so it renders the moment
it is placed. Written for this example library rather than lifted from the built-in one.

- **Reuse:** `copy-as-is`. Pure GPU, no device, no permissions. Ships both platforms.
- **Why the grain is not decoration:** an 8-bit ramp across a large frame lands on visible bands. A
  little noise per pixel scatters each band across its neighbours and the eye reads a smooth ramp.
  That is why the default is on, and low. Turn `grain` to 0 and the banding comes back.
- **Implementation:** SAMPLED render template, everything in the fragment shader. The gradient
  parameter is the pixel projected onto `vec2(cos(angle), sin(angle))`, divided by `|x| + |y|` so the
  ramp spans the frame at any angle instead of running out early on the diagonal. `softness` mixes
  between a straight ramp and a smoothstep. The grain is shaped by `1 - |t - 0.5| * 1.2`, strongest
  in the midtones, so the darks stay clean and the lights do not blow out.
- **The hash matters.** The obvious `fract(sin(dot(p, vec2(12.9898, 78.233))))` correlates along
  diagonals and reads as a woven texture at low amplitudes, which is exactly the amplitude grain
  wants. Both files use a trig-free hash instead.
- **Knobs:** `topColor` / `bottomColor` (colorRGB), `angle` (degrees), `softness`, `grain`,
  `grainSize`. All live-tunable and all wireable.
- **Web:** ships `Node.js`. One contract serves both files; uv is flipped to a top-left origin on the
  web side so `angle` means the same thing on either platform.
