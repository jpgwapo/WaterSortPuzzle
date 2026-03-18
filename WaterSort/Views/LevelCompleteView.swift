import SwiftUI

struct LevelCompleteView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPresented = false

    let levelNumber: Int
    let moves: Int
    let bestMoves: Int?
    let isNewBest: Bool
    let isFinalLevel: Bool
    let onRestart: () -> Void
    let onNextLevel: () -> Void

    init(
        levelNumber: Int,
        moves: Int,
        bestMoves: Int?,
        isNewBest: Bool = false,
        isFinalLevel: Bool = false,
        onRestart: @escaping () -> Void,
        onNextLevel: @escaping () -> Void
    ) {
        self.levelNumber = levelNumber
        self.moves = moves
        self.bestMoves = bestMoves
        self.isNewBest = isNewBest
        self.isFinalLevel = isFinalLevel
        self.onRestart = onRestart
        self.onNextLevel = onNextLevel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isPresented ? 0.42 : 0)
                .ignoresSafeArea()

            ConfettiView(isActive: isPresented)

            ScrollView {
                VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 18 : 22) {
                    celebrationIcon
                    titleBlock
                    stats
                    actions
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: 430)
                .chromaticGlass(
                    cornerRadius: 32,
                    tint: ChromaticTheme.deepIndigo.opacity(0.34),
                    borderOpacity: 0.22,
                    shadowOpacity: 0.35
                )
                .padding(.horizontal, 22)
                .padding(.vertical, 36)
                .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : 620)
            }
            .scrollIndicators(.hidden)
            .scaleEffect(isPresented || reduceMotion ? 1 : 0.88)
            .opacity(isPresented ? 1 : 0)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("level-complete.overlay")
        .onAppear {
            withAnimation(reduceMotion ? .linear(duration: 0.12) : .spring(response: 0.55, dampingFraction: 0.76)) {
                isPresented = true
            }
        }
    }

    private var celebrationIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ChromaticTheme.sunshine.opacity(0.32), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 68
                    )
                )
                .frame(width: 138, height: 138)

            Circle()
                .fill(ChromaticTheme.actionGradient)
                .frame(width: 82, height: 82)
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                }
                .shadow(color: ChromaticTheme.violet.opacity(0.48), radius: 22, y: 10)

            Image(systemName: "checkmark")
                .font(.system(size: 35, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(spacing: 7) {
            Text(isFinalLevel ? "Collection Complete!" : "Level Complete!")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(ChromaticTheme.primaryText)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            Text(isFinalLevel ? "Every color found its flow." : "Level \(levelNumber) is beautifully sorted.")
                .font(.chromaticBody)
                .foregroundStyle(ChromaticTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            GameCompletionStat(
                title: "MOVES",
                value: "\(moves)",
                systemImage: "arrow.triangle.2.circlepath",
                tint: ChromaticTheme.aqua
            )

            GameCompletionStat(
                title: isNewBest ? "NEW BEST" : "BEST",
                value: bestMoves.map(String.init) ?? "—",
                systemImage: "crown.fill",
                tint: ChromaticTheme.sunshine
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            GlassButton(
                isFinalLevel ? "BACK TO LEVELS" : "NEXT LEVEL",
                systemImage: isFinalLevel ? "square.grid.2x2.fill" : "arrow.right",
                emphasis: .primary,
                action: onNextLevel
            )
            .accessibilityIdentifier(
                isFinalLevel ? "level-complete.back-to-levels" : "level-complete.next-level"
            )

            GlassButton(
                "RESTART",
                systemImage: "arrow.counterclockwise",
                emphasis: .quiet,
                action: onRestart
            )
        }
    }
}

private struct GameCompletionStat: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(ChromaticTheme.primaryText)
                .monospacedDigit()

            Text(title)
                .font(.chromaticCaption)
                .tracking(1.2)
                .foregroundStyle(ChromaticTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}
