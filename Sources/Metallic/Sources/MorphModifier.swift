//
// Copyright (c) Nathan Tannar
//

#if !os(watchOS)

import SwiftUI

/// A transition that morphs the view
@frozen
@MainActor @preconcurrency
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct MorphTransition: Transition {

    public init() { }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(
                MorphModifier(
                    progress: phase.isIdentity ? 0 : 1,
                )
            )
    }

    public static var properties: TransitionProperties {
        TransitionProperties(hasMotion: false)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
extension Transition where Self == MorphTransition {

    public static var morph: MorphTransition { .init() }
}

/// A modifier that morphs the view based on an alpha threshold
@frozen
@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
public struct MorphModifier: ViewModifier, Animatable {

    public var progress: CGFloat

    public nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    @inlinable
    public init(progress: CGFloat) {
        self.progress = progress
    }

    public func body(content: Content) -> some View {
        content
            .compositingGroup()
            .visualEffect { content, proxy in
                content
                    .blur(radius: max(proxy.size.width, proxy.size.height) / 2 * progress)
                    .layerEffect(
                        Shader(
                            function: ShaderFunction(
                                library: ShaderLibrary.bundle(.module),
                                name: "alphaThreshold"
                            ),
                            arguments: []
                        ),
                        maxSampleOffset: proxy.size
                    )
            }
    }
}

// MARK: - Previews

@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
@available(watchOS, unavailable)
struct MorphTransition_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                Toggle(isOn: $flag.animation()) { EmptyView() }
                    .labelsHidden()

                Image(systemName: flag ? "star.fill" : "heart.fill")
                    .font(.system(size: 100))
                    .transition(.morph)
                    .id(flag)
            }
        }
    }
}

#endif
