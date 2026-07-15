//
// Copyright (c) Nathan Tannar
//

#if !os(watchOS)

import SwiftUI

@frozen
@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
public struct DitherModifier: ViewModifier, Animatable {

    public var scale: CGFloat
    public var levels: CGFloat
    public var isEnabled: Bool

    public nonisolated var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(
                scale,
                levels
            )
        }
        set {
            scale = newValue.first
            levels = newValue.second
        }
    }

    @inlinable
    public init(
        scale: CGFloat = 4,
        levels: CGFloat = 4,
        isEnabled: Bool = true
    ) {
        self.scale = scale
        self.levels = levels
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .compositingGroup()
            .layerEffect(
                Shader(
                    function: ShaderFunction(
                        library: ShaderLibrary.bundle(.module),
                        name: "dither"
                    ),
                    arguments: [
                        .float(scale),
                        .float(levels),
                    ]
                ),
                maxSampleOffset: .zero,
                isEnabled: isEnabled
            )
    }
}

// MARK: - Previews

@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
@available(watchOS, unavailable)
struct DitherModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var scale: CGFloat = 4
        @State var levels: CGFloat = 4

        var body: some View {
            VStack {
                #if !os(tvOS)
                VStack {
                    Stepper("Scale: \(scale)", value: $scale, step: 1)

                    Stepper("Levels: \(levels)", value: $levels, step: 1)
                }
                .padding(.horizontal)
                #endif

                Image(systemName: "heart.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.red.gradient)
                    .modifier(
                        DitherModifier(
                            scale: scale,
                            levels: levels
                        )
                    )
            }
        }
    }
}

#endif
