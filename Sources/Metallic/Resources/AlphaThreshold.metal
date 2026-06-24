//
// Copyright (c) Nathan Tannar
//

#include <TargetConditionals.h>

#if !TARGET_OS_WATCH

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

[[ stitchable ]]
half4 alphaThreshold(float2 position, SwiftUI::Layer layer)
{
    half4 color = layer.sample(position);
    half alpha = color.a;

    if (alpha > 0.5) {
        return half4(color.rgb / alpha, 1.0);
    } else {
        return half4(0.0);
    }
}

#endif
