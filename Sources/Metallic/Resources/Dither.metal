//
// Copyright (c) Nathan Tannar
//

#include <TargetConditionals.h>

#if !TARGET_OS_WATCH

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

constant float bayer8x8[64] = {
     0, 32,  8, 40,  2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44,  4, 36, 14, 46,  6, 38,
    60, 28, 52, 20, 62, 30, 54, 22,
     3, 35, 11, 43,  1, 33,  9, 41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21
};

inline float bayerThreshold(float2 position)
{
    int x = int(position.x) % 8;
    int y = int(position.y) % 8;
    return (bayer8x8[y * 8 + x] + 0.5) / 64.0;
}

[[ stitchable ]]
half4 dither(float2 position, SwiftUI::Layer layer, float scale, float levels)
{
    half4 color = layer.sample(position);
    if (color.a <= 0.0) {
        return half4(0.0);
    }

    half3 rgb = color.rgb / color.a;
    float threshold = bayerThreshold(position / max(scale, 1.0));
    float steps = max(levels - 1.0, 1.0);

    half3 dithered = half3(
        floor(float(rgb.r) * steps + threshold) / steps,
        floor(float(rgb.g) * steps + threshold) / steps,
        floor(float(rgb.b) * steps + threshold) / steps
    );
    dithered = clamp(dithered, half3(0.0), half3(1.0));

    return half4(dithered * color.a, color.a);
}

#endif
