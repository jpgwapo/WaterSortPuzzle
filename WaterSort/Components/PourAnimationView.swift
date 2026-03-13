import SwiftUI

/// A lightweight, geometry-driven approximation of a real pour. The travelling
/// tube is a visual snapshot; `GameViewModel` owns the authoritative board update.
struct PourAnimationView: View {
    @State private var streamProgress: CGFloat = 0

    let state: PourAnimationState
    let sourceFrame: CGRect
    let destinationFrame: CGRect
    let reduceMotion: Bool

    init(
        state: PourAnimationState,
        sourceFrame: CGRect,
        destinationFrame: CGRect,
        reduceMotion: Bool
    ) {
        self.state = state
        self.sourceFrame = sourceFrame
        self.destinationFrame = destinationFrame
        self.reduceMotion = reduceMotion
        _streamProgress = State(initialValue: state.phase == .pouring ? 1 : 0)
    }

    var body: some View {
        ZStack {
            if state.phase == .pouring {
                PourLiquidStream(
                    color: state.color.gameColor,
                    start: spoutPoint,
                    end: destinationMouth,
                    layerCount: state.layerCount,
                    progress: reduceMotion ? 1 : streamProgress,
                    reduceMotion: reduceMotion
                )
                .transition(.opacity)
            }

            TubeView(tube: state.displayedTube)
                .frame(width: sourceFrame.width, height: sourceFrame.height)
                .rotationEffect(rotation)
                .position(position)
                .shadow(
                    color: state.color.gameColor.opacity(state.phase == .pouring ? 0.45 : 0.24),
                    radius: state.phase == .pouring ? 18 : 11,
                    y: 7
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(reduceMotion ? .linear(duration: 0.05) : phaseAnimation, value: state.phase)
        .onAppear { updateStreamProgress(for: state.phase) }
        .onChange(of: state.phase) { _, phase in
            updateStreamProgress(for: phase)
        }
    }

    private var direction: CGFloat {
        let horizontalDifference = destinationFrame.midX - sourceFrame.midX
        if abs(horizontalDifference) > 2 {
            return horizontalDifference > 0 ? 1 : -1
        }
        return state.destinationIndex > state.sourceIndex ? 1 : -1
    }

    private var pourAngle: Angle {
        .degrees(Double(direction * 66))
    }

    private var rotation: Angle {
        guard !reduceMotion else { return .zero }
        switch state.phase {
        case .tilting, .pouring:
            return pourAngle
        case .lifting, .travelling, .returning:
            return .zero
        }
    }

    private var position: CGPoint {
        guard !reduceMotion else {
            return CGPoint(x: sourceFrame.midX, y: sourceFrame.midY - 8)
        }

        switch state.phase {
        case .lifting:
            return CGPoint(x: sourceFrame.midX, y: sourceFrame.midY - 17)

        case .travelling:
            return CGPoint(
                x: tiltedPosition.x,
                y: tiltedPosition.y + 14
            )

        case .tilting, .pouring:
            return tiltedPosition

        case .returning:
            return CGPoint(x: sourceFrame.midX, y: sourceFrame.midY)
        }
    }

    private var spoutPoint: CGPoint {
        guard !reduceMotion else {
            return CGPoint(x: sourceFrame.midX, y: sourceFrame.minY)
        }

        return CGPoint(
            x: tiltedPosition.x + tiltedLipOffset.x,
            y: tiltedPosition.y + tiltedLipOffset.y
        )
    }

    private var destinationMouth: CGPoint {
        CGPoint(
            x: destinationFrame.midX,
            y: destinationFrame.minY + max(6, destinationFrame.height * 0.045)
        )
    }

    private var streamStartTarget: CGPoint {
        let preferredY = destinationFrame.minY - pourGap
        return CGPoint(x: destinationFrame.midX, y: max(6, preferredY))
    }

    private var pourGap: CGFloat {
        min(48, max(38, destinationFrame.height * 0.26))
    }

    private var tiltedPosition: CGPoint {
        CGPoint(
            x: streamStartTarget.x - tiltedLipOffset.x,
            y: streamStartTarget.y - tiltedLipOffset.y
        )
    }

    /// The liquid leaves from the downhill edge of the rotated rim, rather than
    /// from the tube's top-center, so the stream visually connects to the glass.
    private var tiltedLipOffset: CGPoint {
        let radians = pourAngle.radians
        let localX = direction * sourceFrame.width * 0.42
        let localY = -sourceFrame.height * 0.49

        return CGPoint(
            x: localX * cos(radians) - localY * sin(radians),
            y: localX * sin(radians) + localY * cos(radians)
        )
    }

    private var phaseAnimation: Animation {
        switch state.phase {
        case .lifting:
            return .easeOut(duration: 0.15)
        case .travelling:
            return .spring(response: 0.27, dampingFraction: 0.86)
        case .tilting:
            return .easeInOut(duration: 0.21)
        case .pouring:
            return .easeOut(duration: 0.12)
        case .returning:
            return .spring(response: 0.29, dampingFraction: 0.78)
        }
    }

    private func updateStreamProgress(for phase: PourAnimationState.Phase) {
        guard phase == .pouring else {
            streamProgress = 0
            return
        }

        guard !reduceMotion else {
            streamProgress = 1
            return
        }

        streamProgress = 0.08
        withAnimation(.easeOut(duration: 0.2)) {
            streamProgress = 1
        }
    }
}

private struct PourLiquidStream: View {
    let color: Color
    let start: CGPoint
    let end: CGPoint
    let layerCount: Int
    let progress: CGFloat
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 45, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, _ in
                var path = Path()
                path.move(to: start)
                path.addCurve(
                    to: end,
                    control1: CGPoint(
                        x: start.x + sin(time * 8) * 2.4,
                        y: start.y + (end.y - start.y) * 0.34
                    ),
                    control2: CGPoint(
                        x: end.x + cos(time * 7) * 2,
                        y: start.y + (end.y - start.y) * 0.74
                    )
                )

                let visiblePath = path.trimmedPath(
                    from: 0,
                    to: min(max(progress, 0.01), 1)
                )
                let streamWidth = CGFloat(min(max(layerCount, 1), 4)) + 3.8

                context.stroke(
                    visiblePath,
                    with: .color(color.opacity(0.28)),
                    style: StrokeStyle(
                        lineWidth: streamWidth + 5,
                        lineCap: .round
                    )
                )
                context.stroke(
                    visiblePath,
                    with: .color(color.opacity(0.98)),
                    style: StrokeStyle(lineWidth: streamWidth, lineCap: .round)
                )
                context.stroke(
                    visiblePath,
                    with: .color(Color.white.opacity(0.24)),
                    style: StrokeStyle(
                        lineWidth: max(1, streamWidth * 0.18),
                        lineCap: .round
                    )
                )

                guard progress > 0.72 else { return }

                let impact = min(1, (progress - 0.72) / 0.28)
                let ripplePhase = reduceMotion
                    ? CGFloat(0.32)
                    : CGFloat((time * 2.4).truncatingRemainder(dividingBy: 1))
                let rippleRect = CGRect(
                    x: end.x - (10 + ripplePhase * 12) / 2,
                    y: end.y - 2 - ripplePhase,
                    width: 10 + ripplePhase * 12,
                    height: 4 + ripplePhase * 2
                )
                context.stroke(
                    Path(ellipseIn: rippleRect),
                    with: .color(color.opacity(impact * (1 - ripplePhase) * 0.62)),
                    lineWidth: 1.5
                )

                let beadPhase = reduceMotion
                    ? CGFloat(0.65)
                    : CGFloat((time * 3.1).truncatingRemainder(dividingBy: 1))
                let beadCenter = CGPoint(
                    x: start.x + (end.x - start.x) * beadPhase,
                    y: start.y + (end.y - start.y) * beadPhase
                )
                let beadDiameter = max(3.5, streamWidth * 0.68)
                context.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: beadCenter.x - beadDiameter / 2,
                            y: beadCenter.y - beadDiameter / 2,
                            width: beadDiameter,
                            height: beadDiameter
                        )
                    ),
                    with: .color(Color.white.opacity(0.22 * impact))
                )
            }
        }
        .accessibilityHidden(true)
    }
}
