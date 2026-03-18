import SwiftUI

struct LevelSelectionView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let progress: ProgressManager
    let onSelectLevel: (Int) -> Void

    init(
        progress: ProgressManager,
        onSelectLevel: @escaping (Int) -> Void
    ) {
        self.progress = progress
        self.onSelectLevel = onSelectLevel
    }

    var body: some View {
        ZStack {
            BackgroundView(intensity: 0.82)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction
                    progressSummary

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(LevelProvider.levels) { level in
                            LevelCard(
                                level: level.id,
                                difficulty: level.difficulty,
                                isUnlocked: progress.isUnlocked(level.id),
                                isCompleted: progress.isCompleted(level.id),
                                bestMoves: progress.bestMoves(for: level.id)
                            ) {
                                onSelectLevel(level.id)
                            }
                        }
                    }
                }
                .frame(maxWidth: 760, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 14)]
        }

        return [
            GridItem(.adaptive(minimum: 136, maximum: 210), spacing: 14),
        ]
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose your flow")
                .font(.chromaticHero)
                .foregroundStyle(ChromaticTheme.primaryText)

            Text("Each palette gets a little more intricate. Take your time—there is always a way through.")
                .font(.chromaticBody)
                .foregroundStyle(ChromaticTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Collection progress", systemImage: "sparkles")
                    .font(.chromaticHeadline)
                    .foregroundStyle(ChromaticTheme.primaryText)

                Spacer(minLength: 12)

                Text("\(completedCount) / \(totalLevels)")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(ChromaticTheme.aqua)
            }

            ProgressView(value: Double(completedCount), total: Double(totalLevels))
                .tint(ChromaticTheme.aqua)
                .accessibilityLabel("Collection progress")
                .accessibilityValue("\(completedCount) of \(totalLevels) levels completed")
        }
        .padding(18)
        .chromaticGlass(cornerRadius: 22)
    }

    private var completedCount: Int {
        min(max(progress.completedCount, 0), totalLevels)
    }

    private var totalLevels: Int {
        LevelProvider.totalLevelCount
    }
}

private struct LevelCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var minimumHeight: CGFloat = 132

    let level: Int
    let difficulty: PuzzleLevel.Difficulty
    let isUnlocked: Bool
    let isCompleted: Bool
    let bestMoves: Int?
    let action: () -> Void

    private var accent: Color {
        ChromaticTheme.accent(forLevel: level)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(isUnlocked ? 0.20 : 0.07))

                        Image(systemName: statusSymbol)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(statusColor)
                    }
                    .frame(width: 37, height: 37)

                    Spacer(minLength: 8)

                    Text(difficulty.displayName.uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(isUnlocked ? accent.opacity(0.95) : ChromaticTheme.tertiaryText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(accent.opacity(isUnlocked ? 0.10 : 0.035), in: Capsule())
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Level \(level)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(isUnlocked ? ChromaticTheme.primaryText : ChromaticTheme.tertiaryText)

                    Text(statusText)
                        .font(.chromaticCaption)
                        .foregroundStyle(isUnlocked ? ChromaticTheme.secondaryText : ChromaticTheme.tertiaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .topLeading)
            .padding(16)
            .background { cardBackground }
            .contentShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        }
        .buttonStyle(LevelCardButtonStyle(reduceMotion: reduceMotion))
        .disabled(!isUnlocked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(level), \(difficulty.displayName)")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(isUnlocked ? "Opens level \(level)" : "Complete the previous level to unlock")
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        shape
            .fill(.ultraThinMaterial)
            .overlay {
                shape.fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(isUnlocked ? 0.12 : 0.025),
                            Color.white.opacity(isUnlocked ? 0.035 : 0.018),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                shape.strokeBorder(
                    isCompleted ? accent.opacity(0.54) : Color.white.opacity(isUnlocked ? 0.14 : 0.07),
                    lineWidth: isCompleted ? 1.5 : 1
                )
            }
            .shadow(color: isUnlocked ? accent.opacity(0.10) : .clear, radius: 16, y: 9)
    }

    private var statusSymbol: String {
        if !isUnlocked { return "lock.fill" }
        if isCompleted { return "checkmark" }
        return "drop.fill"
    }

    private var statusColor: Color {
        guard isUnlocked else { return ChromaticTheme.tertiaryText }
        return isCompleted ? accent : ChromaticTheme.primaryText
    }

    private var statusText: String {
        guard isUnlocked else { return "Locked" }
        if let bestMoves {
            return "Best: \(bestMoves) moves"
        }
        return isCompleted ? "Completed" : "Ready to pour"
    }

    private var accessibilityValue: String {
        guard isUnlocked else { return "Locked" }
        if let bestMoves {
            return "Completed, best score \(bestMoves) moves"
        }
        return isCompleted ? "Completed" : "Not yet completed"
    }
}

private struct LevelCardButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.025 : 0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.76),
                value: configuration.isPressed
            )
    }
}
