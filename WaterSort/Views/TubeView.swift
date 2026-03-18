import SwiftUI

struct TubeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var shakeProgress: CGFloat = 0

    let tube: Tube
    var isSelected: Bool = false
    var isHintSource: Bool = false
    var isHintDestination: Bool = false
    var isPouring: Bool = false
    var invalidFeedbackID: Int = 0

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let lineWidth = max(1.8, size.width * 0.055)

            ZStack {
                if isSelected {
                    GameTubeSelectionHalo(
                        color: ChromaticTheme.aqua,
                        isAnimated: !reduceMotion
                    )
                    .frame(width: size.width * 1.30, height: size.height * 1.10)
                }

                if isHintSource || isHintDestination || isInvalid {
                    GameTubeHighlight(
                        color: highlightColor,
                        isAnimated: (isHintSource || isHintDestination) && !reduceMotion
                    )
                    .frame(width: size.width * 1.55, height: size.height * 1.15)
                }

                GameTubeInteriorShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(reduceTransparency ? 0.14 : 0.075),
                                Color.white.opacity(reduceTransparency ? 0.08 : 0.018),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.horizontal, lineWidth * 0.9)
                    .padding(.top, lineWidth * 1.2)
                    .padding(.bottom, lineWidth * 0.7)

                liquid(in: size, lineWidth: lineWidth)

                GameOpenTubeShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(reduceTransparency ? 0.95 : 0.82),
                                Color.white.opacity(0.27),
                                Color.white.opacity(0.62),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .padding(.horizontal, lineWidth / 2)
                    .padding(.top, lineWidth)
                    .padding(.bottom, lineWidth / 2)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.86), Color.white.opacity(0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: lineWidth * 1.15)
                    .padding(.horizontal, lineWidth * 0.08)
                    .frame(maxHeight: .infinity, alignment: .top)

                Capsule()
                    .fill(Color.white.opacity(reduceTransparency ? 0.74 : 0.48))
                    .frame(width: max(1.5, lineWidth * 0.68), height: size.height * 0.46)
                    .blur(radius: 0.25)
                    .offset(x: -size.width * 0.30, y: -size.height * 0.10)
            }
            .shadow(
                color: glowColor.opacity(tube.isComplete ? 0.36 : 0.12),
                radius: 10,
                y: 7
            )
        }
        .aspectRatio(0.34, contentMode: .fit)
        .opacity(isPouring ? 0 : 1)
        .modifier(GameTubeShakeEffect(progress: shakeProgress))
        .animation(.easeOut(duration: 0.14), value: isPouring)
        .onChange(of: invalidFeedbackID) { _, newValue in
            guard newValue > 0 else { return }
            if reduceMotion {
                shakeProgress.round(.up)
                shakeProgress += 1
            } else {
                withAnimation(.linear(duration: 0.38)) {
                    shakeProgress += 1
                }
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func liquid(in size: CGSize, lineWidth: CGFloat) -> some View {
        let horizontalInset = lineWidth * 1.48
        let topInset = lineWidth * 2.15
        let bottomInset = lineWidth * 1.1
        let innerWidth = max(1, size.width - horizontalInset * 2)
        let innerHeight = max(1, size.height - topInset - bottomInset)
        let slotHeight = innerHeight / CGFloat(max(tube.capacity, 1))
        let bottomY = size.height - bottomInset

        ZStack {
            ForEach(Array(tube.layers.enumerated()), id: \.offset) { index, liquidColor in
                GameLiquidLayer(color: liquidColor.gameColor)
                    .frame(width: innerWidth, height: slotHeight + 1.2)
                    .position(
                        x: size.width / 2,
                        y: bottomY - slotHeight * (CGFloat(index) + 0.5)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
            }

            if let topColor = tube.topColor, !tube.layers.isEmpty {
                Ellipse()
                    .fill(topColor.gameColor.highlightGradient)
                    .frame(width: innerWidth, height: max(3.2, lineWidth * 1.15))
                    .position(
                        x: size.width / 2,
                        y: bottomY - slotHeight * CGFloat(tube.layers.count)
                    )
                    .shadow(color: Color.white.opacity(0.16), radius: 1, y: -1)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(
            GameTubeLiquidMaskShape(
                horizontalInset: horizontalInset,
                topInset: topInset,
                bottomInset: bottomInset
            )
        )
        .animation(
            reduceMotion ? .linear(duration: 0.12) : .spring(response: 0.42, dampingFraction: 0.82),
            value: tube.layers.count
        )
    }

    private var highlightColor: Color {
        if isInvalid { return ChromaticTheme.coral }
        if isHintDestination { return ChromaticTheme.aqua }
        if isHintSource { return ChromaticTheme.sunshine }
        return glowColor
    }

    private var glowColor: Color {
        tube.topColor?.gameColor ?? ChromaticTheme.azure
    }

    private var isInvalid: Bool {
        invalidFeedbackID > 0
    }
}

private struct GameLiquidLayer: View {
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color.liquidGradient)
            .overlay(alignment: .leading) {
                LinearGradient(
                    colors: [Color.white.opacity(0.28), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 10)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
            }
            .saturation(1.08)
    }
}

private struct GameTubeLiquidMaskShape: Shape {
    let horizontalInset: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat

    func path(in rect: CGRect) -> Path {
        let interior = CGRect(
            x: rect.minX + horizontalInset,
            y: rect.minY + topInset,
            width: max(0, rect.width - horizontalInset * 2),
            height: max(0, rect.height - topInset - bottomInset)
        )
        let radius = min(interior.width * 0.43, interior.height * 0.11)
        return Path(
            roundedRect: interior,
            cornerRadii: RectangleCornerRadii(
                topLeading: 2,
                bottomLeading: radius,
                bottomTrailing: radius,
                topTrailing: 2
            )
        )
    }
}

private struct GameTubeHighlight: View {
    let color: Color
    let isAnimated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isAnimated)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = isAnimated ? (sin(time * 4.2) + 1) / 2 : 0.35

            Capsule()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.32 + pulse * 0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 64
                    )
                )
                .scaleEffect(0.94 + pulse * 0.08)
        }
        .accessibilityHidden(true)
    }
}

private struct GameTubeSelectionHalo: View {
    let color: Color
    let isAnimated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isAnimated)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = isAnimated ? (sin(time * 3.6) + 1) / 2 : 0.45
            let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

            shape
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.30 + pulse * 0.08),
                            ChromaticTheme.azure.opacity(0.16 + pulse * 0.04),
                            ChromaticTheme.deepIndigo.opacity(0.48),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape
                        .inset(by: 4)
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.16), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 54
                            )
                        )
                }
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.96), color, color.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3.2
                    )
                }
                .shadow(color: color.opacity(0.82), radius: 10 + pulse * 4)
                .shadow(color: Color.white.opacity(0.30), radius: 2)
                .scaleEffect(1 + pulse * 0.018)
        }
        .accessibilityHidden(true)
    }
}

private struct GameTubeShakeEffect: GeometryEffect {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(progress * .pi * 8) * 5.5
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

private struct GameTubeInteriorShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width * 0.43, rect.height * 0.11)
        return Path(
            roundedRect: rect,
            cornerRadii: RectangleCornerRadii(
                topLeading: 2,
                bottomLeading: radius,
                bottomTrailing: radius,
                topTrailing: 2
            )
        )
    }
}

private struct GameOpenTubeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width * 0.42, rect.height * 0.11)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

extension LiquidColor {
    var gameColor: Color {
        switch self {
        case .coral:
            return Color(red: 0.96, green: 0.16, blue: 0.27)
        case .tangerine:
            return Color(red: 1.00, green: 0.38, blue: 0.02)
        case .sunshine:
            return Color(red: 1.00, green: 0.82, blue: 0.04)
        case .lime:
            return Color(red: 0.64, green: 0.90, blue: 0.10)
        case .mint:
            return Color(red: 0.10, green: 0.73, blue: 0.31)
        case .teal:
            return Color(red: 0.00, green: 0.50, blue: 0.49)
        case .sky:
            return Color(red: 0.05, green: 0.78, blue: 0.93)
        case .blue:
            return Color(red: 0.08, green: 0.32, blue: 0.96)
        case .indigo:
            return Color(red: 0.12, green: 0.10, blue: 0.48)
        case .violet:
            return Color(red: 0.48, green: 0.16, blue: 0.91)
        case .magenta:
            return Color(red: 0.85, green: 0.10, blue: 0.88)
        case .rose:
            return Color(red: 1.00, green: 0.40, blue: 0.66)
        case .crimson:
            return Color(red: 0.47, green: 0.04, blue: 0.16)
        case .amber:
            return Color(red: 0.66, green: 0.32, blue: 0.08)
        case .forest:
            return Color(red: 0.02, green: 0.31, blue: 0.18)
        case .lavender:
            return Color(red: 0.76, green: 0.62, blue: 1.00)
        case .silver:
            return Color(red: 0.76, green: 0.82, blue: 0.89)
        }
    }

}

private extension Color {
    var liquidGradient: LinearGradient {
        LinearGradient(
            colors: [self.opacity(0.87), self, self.opacity(0.78)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [self.opacity(0.82), self, Color.white.opacity(0.38)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
