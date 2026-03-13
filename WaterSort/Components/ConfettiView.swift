import SwiftUI

/// A lightweight deterministic celebration layer with a reduced-motion fallback.
struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date.now
    @State private var isFinished = false

    let isActive: Bool
    var particleCount: Int

    init(isActive: Bool, particleCount: Int = 58) {
        self.isActive = isActive
        self.particleCount = particleCount
    }

    var body: some View {
        Group {
            if isActive {
                if reduceMotion {
                    confettiCanvas(progress: 0.58)
                        .opacity(0.85)
                } else {
                    TimelineView(
                        .animation(minimumInterval: 1 / 60, paused: isFinished)
                    ) { timeline in
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        confettiCanvas(progress: max(0, elapsed))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: isActive) {
            guard isActive else {
                isFinished = true
                return
            }

            startDate = .now
            isFinished = reduceMotion
            guard !reduceMotion else { return }

            try? await Task.sleep(nanoseconds: 3_200_000_000)
            guard !Task.isCancelled else { return }
            isFinished = true
        }
    }

    private func confettiCanvas(progress elapsed: TimeInterval) -> some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width / 2, y: size.height * 0.34)

            for index in 0..<max(0, particleCount) {
                let seed = Double(index + 1)
                let duration = 1.65 + random(seed * 1.31) * 1.15
                let progress = min(max(elapsed / duration, 0), 1.12)

                guard progress < 1.08 else { continue }

                let angle = Double.pi * (1.08 + random(seed * 2.17) * 0.84)
                let speed = 170 + random(seed * 4.23) * 290
                let horizontalDrift = sin(progress * .pi * 4 + seed) * (8 + random(seed) * 12)
                let x = origin.x + cos(angle) * speed * progress + horizontalDrift
                let y = origin.y + sin(angle) * speed * progress + 620 * progress * progress
                let width = 4 + random(seed * 5.71) * 6
                let height = width * (1.4 + random(seed * 7.19))
                let fade = progress < 0.76 ? 1 : max(0, (1.08 - progress) / 0.32)
                let rotation = Angle.radians(seed + progress * (5 + random(seed * 8.11) * 9))

                var particleContext = context
                particleContext.translateBy(x: x, y: y)
                particleContext.rotate(by: rotation)
                particleContext.opacity = fade

                let rect = CGRect(
                    x: -width / 2,
                    y: -height / 2,
                    width: width,
                    height: height
                )
                let path = Path(roundedRect: rect, cornerRadius: width * 0.35)
                let color = ChromaticTheme.liquidPalette[index % ChromaticTheme.liquidPalette.count]
                particleContext.fill(path, with: .color(color))
            }
        }
        .ignoresSafeArea()
    }

    private func random(_ value: Double) -> Double {
        let raw = sin(value * 12.9898) * 43_758.5453
        return raw - floor(raw)
    }
}
