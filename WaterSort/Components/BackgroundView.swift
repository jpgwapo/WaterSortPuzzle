import SwiftUI

/// The animated ambient backdrop shared by the home, level picker, and game surfaces.
struct BackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var intensity: Double
    var showsParticles: Bool

    init(intensity: Double = 1, showsParticles: Bool = true) {
        self.intensity = intensity
        self.showsParticles = showsParticles
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
                let seconds = reduceMotion
                    ? 0
                    : timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    ChromaticTheme.backgroundGradient

                    ambientGlow(
                        color: ChromaticTheme.violet,
                        diameter: max(proxy.size.width * 1.05, 330),
                        x: -proxy.size.width * 0.30 + sin(seconds * 0.12) * 34,
                        y: -proxy.size.height * 0.31 + cos(seconds * 0.10) * 28
                    )

                    ambientGlow(
                        color: ChromaticTheme.azure,
                        diameter: max(proxy.size.width * 0.90, 290),
                        x: proxy.size.width * 0.35 + cos(seconds * 0.09) * 42,
                        y: proxy.size.height * 0.13 + sin(seconds * 0.11) * 38
                    )

                    ambientGlow(
                        color: ChromaticTheme.aqua,
                        diameter: max(proxy.size.width * 0.72, 250),
                        x: -proxy.size.width * 0.20 + cos(seconds * 0.08) * 30,
                        y: proxy.size.height * 0.46 + sin(seconds * 0.09) * 32
                    )

                    if showsParticles {
                        particleField(size: proxy.size, phase: seconds)
                    }

                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func ambientGlow(
        color: Color,
        diameter: CGFloat,
        x: CGFloat,
        y: CGFloat
    ) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.31 * intensity),
                        color.opacity(0.08 * intensity),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .blur(radius: 2)
            .offset(x: x, y: y)
            .blendMode(.screen)
    }

    private func particleField(size: CGSize, phase: TimeInterval) -> some View {
        Canvas { context, canvasSize in
            for index in 0..<18 {
                let seed = Double(index + 1)
                let baseX = pseudoRandom(seed * 1.71)
                let baseY = pseudoRandom(seed * 3.93)
                let driftX = sin(phase * (0.07 + seed * 0.001) + seed) * 13
                let driftY = cos(phase * (0.05 + seed * 0.001) + seed * 0.7) * 11
                let diameter = 1.5 + pseudoRandom(seed * 5.17) * 3.2

                let rect = CGRect(
                    x: baseX * canvasSize.width + driftX,
                    y: baseY * canvasSize.height + driftY,
                    width: diameter,
                    height: diameter
                )

                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.white.opacity((0.12 + diameter * 0.025) * intensity))
                )
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func pseudoRandom(_ value: Double) -> Double {
        let raw = sin(value * 12.9898) * 43_758.5453
        return raw - floor(raw)
    }
}
