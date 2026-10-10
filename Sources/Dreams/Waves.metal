#include <metal_stdlib>
using namespace metal;

struct Uniforms { float2 resolution; float time; float brightness; float period; };
struct VertexOutput { float4 position [[position]]; };

vertex VertexOutput waveVertex(uint id [[vertex_id]]) {
    float2 vertices[] = {float2(-1,-1), float2(3,-1), float2(-1,3)};
    return {float4(vertices[id], 0, 1)};
}

struct MatrixCell { float4 rect; float4 uv; float4 color; };
struct MatrixOutput {
    float4 position [[position]];
    float2 uv;
    float2 localUV;
    float4 color;
    uint seed [[flat]];
};

vertex MatrixOutput matrixVertex(uint vertexID [[vertex_id]], uint instanceID [[instance_id]],
    const device MatrixCell *cells [[buffer(0)]]) {
    float2 corners[] = {float2(0,0), float2(1,0), float2(0,1), float2(1,0), float2(1,1), float2(0,1)};
    MatrixCell cell = cells[instanceID];
    float2 corner = corners[vertexID];
    float2 position = cell.rect.xy + corner * cell.rect.zw;
    MatrixOutput out;
    out.position = float4(position.x * 2 - 1, 1 - position.y * 2, 0, 1);
    out.uv = cell.uv.xy + corner * cell.uv.zw;
    out.localUV = corner;
    out.color = cell.color;
    uint2 grid = uint2(cell.rect.xy * 65535.0);
    out.seed = grid.x * 1597334677u ^ grid.y * 3812015801u;
    return out;
}

// Integer hashing avoids extra textures and trigonometry for per-glyph phosphor grain.
float glyphNoise(uint value) {
    value ^= value >> 16;
    value *= 0x7feb352du;
    value ^= value >> 15;
    value *= 0x846ca68bu;
    value ^= value >> 16;
    return float(value & 0x00ffffffu) / 16777215.0;
}

float lightCloud(float2 p, uint seed) {
    uint2 cell = uint2(floor(p) + 4096.0);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    uint key = seed ^ (cell.x * 374761393u) ^ (cell.y * 668265263u);
    float a = glyphNoise(key);
    float b = glyphNoise(seed ^ ((cell.x + 1u) * 374761393u) ^ (cell.y * 668265263u));
    float c = glyphNoise(seed ^ (cell.x * 374761393u) ^ ((cell.y + 1u) * 668265263u));
    float d = glyphNoise(seed ^ ((cell.x + 1u) * 374761393u) ^ ((cell.y + 1u) * 668265263u));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

fragment float4 matrixFragment(MatrixOutput in [[stage_in]], texture2d<float> atlas [[texture(0)]],
    constant float4 &noiseParameters [[buffer(0)]]) {
    constexpr sampler glyphSampler(filter::linear, address::clamp_to_edge);
    float alpha = atlas.sample(glyphSampler, in.uv).r;
    if (noiseParameters.z > 0.5) {
        // Smooth, loosely mottled scattering. Fine phosphor grain stays in the core.
        float2 drift = float2(noiseParameters.x * 0.025, -noiseParameters.x * 0.020);
        float cloud = 0.70 * lightCloud(in.localUV * float2(5, 6) + drift, in.seed)
            + 0.30 * lightCloud(in.localUV * float2(11, 13) - drift, in.seed ^ 2246822519u);
        float2 edge = min(in.localUV, 1.0 - in.localUV);
        float skirt = smoothstep(0.0, 0.12, min(edge.x, edge.y));
        return float4(in.color.rgb, alpha * in.color.a * (0.65 + 0.65 * cloud) * skirt);
    }
    float gain = 1;
    if (noiseParameters.y > 0 && alpha > 0.01) {
        // A small, fixed grain lattice inside each letter, independent of its glyph shape.
        uint2 grain = uint2(in.localUV * 14.0);
        uint key = in.seed ^ (grain.x * 374761393u) ^ (grain.y * 668265263u);
        float structure = 0.55 + 0.9 * glyphNoise(key);
        float phase = noiseParameters.x * 8.0 + float(in.seed & 255u) / 256.0;
        uint tick = uint(floor(phase));
        float blend = fract(phase);
        blend = blend * blend * (3 - 2 * blend);
        float shimmer = mix(glyphNoise(key ^ (tick * 2246822519u)),
            glyphNoise(key ^ ((tick + 1u) * 2246822519u)), blend);
        float scanline = (grain.y % 3u == 0u) ? 0.88 : 1.0;
        gain = mix(1.0, structure * (0.90 + 0.20 * shimmer) * scanline, noiseParameters.y);
    }
    return float4(in.color.rgb * gain, alpha * in.color.a);
}

fragment float4 waveFragment(VertexOutput in [[stage_in]], constant Uniforms &u [[buffer(0)]]) {
    float2 p = (in.position.xy - 0.5 * u.resolution) / u.resolution.y;
    float phase = 6.2831853 * u.time / u.period;
    float field = p.x * 4.8 + p.y * 2.2
        + 0.65 * sin(3.2 * p.y + phase * 0.5)
        + 0.35 * sin(2.1 * p.x - 2.8 * p.y - phase * 0.25);
    float hue = field + phase;
    float3 rainbow = 0.5 + 0.5 * cos(hue + float3(0, 2.0943951, 4.1887902));
    float glow = 0.35 + 0.65 * pow(0.5 + 0.5 * sin(field * 2.2 - phase), 2.0);
    return float4(u.brightness * glow * (0.06 + 0.94 * rainbow), 1);
}
