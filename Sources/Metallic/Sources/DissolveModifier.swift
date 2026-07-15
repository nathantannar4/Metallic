//
// Copyright (c) Nathan Tannar
//

#if !os(watchOS)

import SwiftUI

/// A transition that dissolves the view
@frozen
@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
public struct DissolveTransition: Transition {

    public var startPoint: UnitPoint
    public var endPoint: UnitPoint
    public var scale: CGFloat

    public init(
        startPoint: UnitPoint = .center,
        endPoint: UnitPoint = .center,
        scale: CGFloat = 1
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.scale = scale
    }

    public func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(
                DissolveModifier(
                    progress: phase.isIdentity ? 0 : 1,
                    startPoint: startPoint,
                    endPoint: endPoint,
                    scale: scale
                )
            )
    }

    public static var properties: TransitionProperties {
        TransitionProperties(hasMotion: true)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
extension Transition where Self == DissolveTransition {

    public static var dissolve: DissolveTransition { .init() }

    public static func dissolve(
        startPoint: UnitPoint = .center,
        endPoint: UnitPoint = .center,
        scale: CGFloat = 1
    ) -> DissolveTransition {
        DissolveTransition(
            startPoint: startPoint,
            endPoint: endPoint,
            scale: scale
        )
    }
}

/// A modifier that dissolves the view
@frozen
@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
public struct DissolveModifier: ViewModifier, Animatable {

    public var progress: CGFloat
    public var startPoint: UnitPoint
    public var endPoint: UnitPoint
    public var scale: CGFloat

    public nonisolated var animatableData: AnimatablePair<AnimatablePair<UnitPoint.AnimatableData, UnitPoint.AnimatableData>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(
                    startPoint.animatableData,
                    endPoint.animatableData
                ),
                AnimatablePair(
                    progress,
                    scale
                )
            )
        }
        set {
            progress = newValue.second.first
            startPoint.animatableData = newValue.first.first
            endPoint.animatableData = newValue.first.second
            scale = newValue.second.second
        }
    }

    @inlinable
    public init(
        progress: CGFloat,
        startPoint: UnitPoint = .center,
        endPoint: UnitPoint = .center,
        scale: CGFloat = 1
    ) {
        self.progress = progress
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.scale = scale
    }

    public func body(content: Content) -> some View {
        content
            .compositingGroup()
            .visualEffect { content, proxy in
                content
                    .layerEffect(
                        Shader(
                            function: ShaderFunction(
                                library: ShaderLibrary.bundle(.module),
                                name: "dissolve"
                            ),
                            arguments: [
                                .float2(proxy.size),
                                .float(progress),
                                .float2(
                                    startPoint.x * proxy.size.width,
                                    startPoint.y * proxy.size.height
                                ),
                                .float2(
                                    endPoint.x - startPoint.x,
                                    endPoint.y - startPoint.y
                                ),
                                .float(scale),
                            ]
                        ),
                        maxSampleOffset: CGSize(
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                    )
            }
    }
}

// MARK: - Previews

@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
@available(watchOS, unavailable)
struct DissolveModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false
        @State var progress: CGFloat = 0.15

        var body: some View {
            VStack {
                Toggle(isOn: $flag.animation(.easeOut(duration: 3))) { EmptyView() }
                    .labelsHidden()

                HStack {
                    HStack {
                        if flag {
                            Color.green
                                .transition(
                                    .dissolve(
                                        scale: 10
                                    )
                                )
                        }
                    }
                    .frame(width: 100, height: 100)

                    HStack {
                        if !flag {
                            Color.red
                                .transition(
                                    .dissolve(
                                        startPoint: .leading,
                                        endPoint: .trailing,
                                        scale: 1
                                    )
                                )
                        }
                    }
                    .frame(width: 100, height: 100)
                }

                Color.blue
                    .frame(width: 100, height: 100)
                    .modifier(
                        DissolveModifier(
                            progress: progress,
                            startPoint: .center,
                            endPoint: .center,
                            scale: 2
                        )
                    )

                #if !os(tvOS)
                Slider(value: $progress, in: 0...1)
                    .padding(.horizontal)
                #endif
            }
        }
    }
}

#endif
