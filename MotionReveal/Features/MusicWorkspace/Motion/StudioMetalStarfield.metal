#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float studioStarfieldHash1(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

static float2 studioStarfieldHash2(float2 p) {
    float a = fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(p, float2(269.5, 183.3))) * 43758.5453);
    return float2(a, b);
}

[[ stitchable ]] half4 studioStarfield(
    float2 position,
    half4 color,
    float4 boundingRect,
    float time,
    float speed,
    float layers,
    float baseScale,
    float scaleStep,
    float density,
    float starSize,
    float twinkleSpeed,
    float twinkleAmount,
    half4 starColor,
    half4 background
) {
    float2 size = boundingRect.zw;
    float2 uv = position / max(size, float2(1.0));

    int count = max(1, min(int(layers), 8));
    float threshold = clamp(1.0 - density, 0.0, 1.0);
    float sizeFloor = max(starSize, 0.001);
    float amount = clamp(twinkleAmount, 0.0, 1.0);
    float3 starRGB = float3(starColor.rgb);
    float3 result = float3(0.0);

    for (int layer = 0; layer < count; layer++) {
        float layerFloat = float(layer);
        float scale = max(baseScale + layerFloat * scaleStep, 1.0);
        float layerSpeed = (0.03 + layerFloat * 0.02) * speed;
        float brightness = max(0.0, 1.0 - layerFloat * 0.25);

        float2 st = uv * scale;
        st.y += time * layerSpeed * scale;
        float2 cell = floor(st);
        float2 f = fract(st);
        float h = studioStarfieldHash1(cell);

        if (h > threshold) {
            float2 center = studioStarfieldHash2(cell);
            float distanceFromStar = length(f - center);
            float twinkle = sin(time * twinkleSpeed + h * 100.0) * amount + (1.0 - amount);
            float falloff = 1.0 - smoothstep(0.0, sizeFloor, distanceFromStar);
            result += starRGB * (falloff * twinkle * brightness);
        }
    }

    float3 bg = float3(background.rgb);
    return half4(half3(bg + result), 1.0);
}
