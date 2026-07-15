//
// ThanosSnap.metal
//

#include <TargetConditionals.h>

#if !TARGET_OS_WATCH

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

static float hash21(float2 p)
{
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float2 hash22(float2 p)
{
    return float2(hash21(p), hash21(p + 91.13));
}

[[ stitchable ]]
half4 dissolve(float2 position, SwiftUI::Layer layer, float2 size, float progress, float2 origin, float2 direction, float scale)
{
    if (progress <= 0.0) {
        return layer.sample(position);
    }

    // The view is broken into small particle "cells". Each cell has its own
    // randomized moment to disintegrate and its own drift direction, so the
    // whole surface crumbles unevenly instead of a single wipe sweeping
    // across it.
    float2 cell = floor(position / scale);
    float2 cellCenter = (cell + 0.5) * scale;

    float2 driftSeed = hash22(cell + 17.0) - 0.5;
    float speedVariance = 0.6 + hash21(cell + 41.0) * 0.8;

    // Per-cell swirl parameters: each particle curves along its own random
    // frequency, phase and amplitude instead of every particle following
    // a straight path in the same direction.
    float wobbleFreq = 2.0 + hash21(cell + 61.0) * 5.0;
    float wobblePhase = hash21(cell + 77.0) * 6.2831853;
    float wobbleAmp = 8.0 + hash21(cell + 89.0) * 24.0;
    float sizeSeed = 0.7 + hash21(cell + 131.0) * 0.6;

    // A zero-length direction means "no dominant direction" — particles
    // should scatter outward from `origin` instead of silently defaulting
    // to any particular side.
    bool hasDirection = length(direction) > 0.001;
    float2 dirNorm = hasDirection ? normalize(direction) : float2(0.0);

    float2 delta = cellCenter - origin;
    float diag = max(length(size), 1.0);
    float projected = dot(delta, dirNorm) / diag;
    float radial = length(delta) / diag;

    // If a direction was supplied, bias timing along that axis so the
    // dissolve still visibly originates from `origin` and sweeps toward
    // `direction`. Otherwise fall back to a purely radial bias so it still
    // spreads outward from `origin` with no directional favoritism.
    float directionalBias = hasDirection
        ? saturate(0.5 + projected * 1.4)
        : saturate(radial * 1.4);

    // Blend with the per-cell random hash via `mix` rather than adding it.
    // A mix of two values already in [0, 1] can never overshoot and get
    // clamped, so cells don't pile up at the extremes — they finish across
    // the whole progress range at an even pace instead of bunching up
    // near the end.
    float rawOrder = mix(hash21(cell), directionalBias, 0.45);

    // Remap into [spread, 1 - spread] rather than [0, 1]. This guarantees
    // every cell's fade window (order ± spread) fits entirely inside the
    // progress range: the earliest cells still start right as progress
    // leaves 0, and the latest cells finish (p reaches 1) by the time
    // progress reaches 1.
    const float spread = 0.22;
    float order = mix(spread, 1.0 - spread, rawOrder);
    float p = smoothstep(order - spread, order + spread, progress);

    // Base drift along `direction` (e.g. upward), accelerating with age,
    // plus a per-cell lateral bias so particles fan out rather than all
    // travelling in parallel. When no direction is supplied, `dirNorm` is
    // zero, so motion is driven entirely by the random per-cell scatter —
    // an outward "explosion" rather than a push toward any side.
    float eased = p * p;
    float travelled = eased * 140.0 * speedVariance;
    float2 offset = dirNorm * travelled + driftSeed * travelled * 1.2;

    // Swirl: push each particle sideways (perpendicular to its direction
    // of travel) with a per-cell sine wave, so paths curve and cross
    // rather than radiating out in straight lines. With no direction this
    // naturally has no effect, which is correct — there's no axis to
    // swirl around.
    float2 perp = float2(-dirNorm.y, dirNorm.x);
    float swirl = sin(p * wobbleFreq * 6.2831853 + wobblePhase) * wobbleAmp * eased;
    offset += perp * swirl;

    // Two layers of turbulence sampled at different scales of `p`, so the
    // random jitter itself evolves over the particle's lifetime instead
    // of just being a single fixed offset.
    float2 turbulenceA = hash22(cell + p * 6.0) - 0.5;
    float2 turbulenceB = hash22(cell + 53.0 + p * 13.0) - 0.5;
    offset += turbulenceA * eased * 16.0;
    offset += turbulenceB * eased * eased * 34.0;

    // Never drift further than the view's own dimensions, regardless of
    // how large the combined drift/swirl/turbulence terms above add up
    // to — keeps displacement sane on small views instead of scaling
    // with fixed pixel constants.
    offset = clamp(offset, -size, size);

    float2 samplePos = position - offset;
    if (samplePos.x < 0.0 || samplePos.y < 0.0 ||
        samplePos.x > size.x || samplePos.y > size.y) {
        return half4(0.0);
    }

    half4 color = layer.sample(samplePos);

    // Shrink each particle as it ages, with a softened (anti-aliased)
    // edge so specks fade smoothly rather than popping off in hard-edged
    // blocks. `startRadius` is intentionally larger than a cell's corner
    // distance (0.5*sqrt2 ≈ 0.707) so the mask fully covers the cell at
    // eased ≈ 0 — otherwise the round particle shape would clip the cell
    // corners before the piece has even started to dissolve.
    float2 sampleCell = floor(samplePos / scale);
    float2 withinCell = (samplePos - sampleCell * scale) / scale;
    float startRadius = 1.0;
    float endRadius = 0.1 * sizeSeed;
    float radius = mix(startRadius, endRadius, eased);
    float dist = distance(withinCell, float2(0.5));
    float coverage = 1.0 - smoothstep(max(radius - 0.12, 0.0), radius, dist);

    // Smooth (ease-in-out) overall fade instead of a linear ramp, so
    // opacity doesn't step or pop as particles cross cell boundaries.
    float fade = 1.0 - (p * p * (3.0 - 2.0 * p));
    float alpha = fade * coverage;

    // `layer.sample` returns premultiplied color (rgb already has the
    // original alpha baked in). Scaling only `color.a` down here would
    // leave rgb too "hot" relative to the new alpha, which is what causes
    // a visible hue/brightness fringe once this is composited over other
    // content — scale every channel by the same factor to keep the
    // premultiplied color valid.
    color *= alpha;
    return color;
}

#endif
