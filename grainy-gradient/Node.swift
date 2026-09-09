// Grainy Gradient — a two-colour gradient with animated film grain over it. A source: no input,
// so it renders the moment it is placed.
//
// The grain is not decoration. An 8-bit gradient across a big frame lands on visible bands; a little
// noise per pixel scatters each one across its neighbours and the eye reads a smooth ramp. That is
// why the default is on, and low.
//
// SAMPLED render template: a full-screen triangle, everything decided in the fragment shader.
@preconcurrency import Metal
import simd

final class Node: SZNode {
    /// Two colours, then the four knobs plus time, packed 16-byte aligned for `setFragmentBytes`.
    private struct Params {
        var top = SIMD4<Float>(1, 1, 1, 1)
        var bottom = SIMD4<Float>(0, 0, 0, 1)
        var knobs = SIMD4<Float>(0, 0, 0, 0)   // angle in radians, softness, grain, grain size
        var time = SIMD4<Float>(0, 0, 0, 0)
    }

    private var pipeline: MTLRenderPipelineState?

    func setup(_ ctx: SZSetupContext) {
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        struct VOut { float4 pos [[position]]; float2 uv; };
        struct Params { float4 top; float4 bottom; float4 knobs; float4 time; };

        vertex VOut v_main(uint vid [[vertex_id]]) {
            float2 p[3] = { float2(-1, -1), float2(3, -1), float2(-1, 3) };
            VOut o;
            o.pos = float4(p[vid], 0, 1);
            o.uv = float2(o.pos.x * 0.5 + 0.5, 0.5 - o.pos.y * 0.5);
            return o;
        }

        // A cheap per-pixel hash, no trig and no texture. The obvious fract(sin(dot(...)))
        // one correlates along diagonals and shows up as a weave at low amplitudes.
        float hash(float2 p) {
            float3 q = fract(float3(p.x, p.y, p.x) * 0.1031);
            q += dot(q, q.yzx + 33.33);
            return fract((q.x + q.y) * q.z);
        }

        fragment float4 f_main(VOut in [[stage_in]], constant Params &p [[buffer(0)]]) {
            float angle = p.knobs.x;
            float2 dir = float2(cos(angle), sin(angle));
            // Project onto the gradient direction and normalise, so the ramp spans the frame at
            // any angle rather than running out early on the diagonal.
            float2 c = in.uv - 0.5;
            float extent = abs(dir.x) + abs(dir.y);
            float t = saturate(dot(c, dir) / extent + 0.5);
            // Softness eases the ends; at 0 it is a straight ramp, at 1 a full smoothstep.
            t = mix(t, smoothstep(0.0, 1.0, t), saturate(p.knobs.y));
            float3 colour = mix(p.top.rgb, p.bottom.rgb, t);

            // Grain, animated by a per-frame offset so it shimmers instead of sitting still.
            float size = max(p.knobs.w, 0.5);
            float2 cell = floor(in.pos.xy / size) + p.time.xy;
            float n = hash(cell) - 0.5;
            // Strongest in the midtones, so the darks stay clean and the lights do not blow out.
            float shape = 1.0 - abs(t - 0.5) * 1.2;
            colour += n * p.knobs.z * shape;
            return float4(saturate(colour), 1.0);
        }
        """
        guard let library = try? ctx.device.makeLibrary(source: source, options: nil) else { return }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "v_main")
        descriptor.fragmentFunction = library.makeFunction(name: "f_main")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipeline = try? ctx.device.makeRenderPipelineState(descriptor: descriptor)
    }

    func update(_ ctx: SZFrameContext) {
        guard let out = ctx.outputTexture("output"), let pipeline else { return }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = out
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = ctx.commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        defer { encoder.endEncoding() }
        encoder.setRenderPipelineState(pipeline)

        var params = Params()
        params.top = Self.colour(ctx.inputFloats("topColor"), SIMD3<Float>(0.98, 0.45, 0.36))
        params.bottom = Self.colour(ctx.inputFloats("bottomColor"), SIMD3<Float>(0.20, 0.16, 0.42))
        params.knobs = SIMD4<Float>((ctx.inputFloat("angle") ?? 20) * .pi / 180,
                                    ctx.inputFloat("softness") ?? 0.5,
                                    ctx.inputFloat("grain") ?? 0.14,
                                    ctx.inputFloat("grainSize") ?? 1.0)
        // A whole-pixel jump per frame: the grain redraws rather than drifting.
        let step = Float(ctx.frameIndex % 64) * 37
        params.time = SIMD4<Float>(step, step * 1.7, 0, 0)
        encoder.setFragmentBytes(&params, length: MemoryLayout<Params>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }

    private static func colour(_ v: [Float]?, _ fallback: SIMD3<Float>) -> SIMD4<Float> {
        guard let v, v.count >= 3, v[0].isFinite, v[1].isFinite, v[2].isFinite else {
            return SIMD4<Float>(fallback.x, fallback.y, fallback.z, 1)
        }
        return SIMD4<Float>(v[0], v[1], v[2], 1)
    }
}

enum SZNodeMain { static func make() -> SZNode { Node() } }
