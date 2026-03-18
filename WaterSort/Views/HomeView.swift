import SwiftUI

struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var heroFontSize: CGFloat = 52

    let progress: ProgressManager
    let onPlay: () -> Void
    let onLevels: () -> Void
    let onSettings: () -> Void

    init(
        progress: ProgressManager,
        onPlay: @escaping () -> Void,
        onLevels: @escaping () -> Void,
        onSettings: @escaping () -> Void
    ) {
        self.progress = progress
        self.onPlay = onPlay
        self.onLevels = onLevels
        self.onSettings = onSettings
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BackgroundView()

                ScrollView {
                    VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 24 : 20) {
                        header
                        titleBlock
                        HomeTubeArtwork(compact: dynamicTypeSize.isAccessibilitySize)
                            .frame(height: dynamicTypeSize.isAccessibilitySize ? 150 : 210)
                        progressCard
                        actions
                        footer
                    }
                    .frame(maxWidth: 560)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(ChromaticTheme.actionGradient)
                    Image(systemName: "drop.fill")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 38, height: 38)

                Text("CHROMATIC CALM")
                    .font(.chromaticCaption)
                    .tracking(1.5)
                    .foregroundStyle(ChromaticTheme.secondaryText)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 16)

            GlassIconButton(
                systemImage: "slider.horizontal.3",
                accessibilityLabel: "Settings",
                action: onSettings
            )
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("WATER SORT")
                .font(.system(size: heroFontSize, weight: .black, design: .rounded))
                .tracking(-1.4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Unwind, pour, and find your flow.")
                .font(.chromaticBody)
                .foregroundStyle(ChromaticTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, dynamicTypeSize.isAccessibilitySize ? 4 : 10)
    }

    private var progressCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(progressHeadline)
                        .font(.chromaticHeadline)
                        .foregroundStyle(ChromaticTheme.primaryText)

                    Text(progressDetail)
                        .font(.chromaticCaption)
                        .foregroundStyle(ChromaticTheme.secondaryText)
                }

                Spacer(minLength: 12)

                Text("\(clampedCompletedCount) / \(totalLevels)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(ChromaticTheme.aqua)
                    .monospacedDigit()
            }

            ProgressView(value: Double(clampedCompletedCount), total: Double(totalLevels))
                .tint(ChromaticTheme.aqua)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
                .accessibilityLabel("Level progress")
                .accessibilityValue("\(clampedCompletedCount) of \(totalLevels) levels completed")
        }
        .padding(20)
        .chromaticGlass(cornerRadius: 24)
        .accessibilityElement(children: .contain)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            GlassButton(
                primaryButtonTitle,
                systemImage: "play.fill",
                emphasis: .primary,
                action: onPlay
            )

            GlassButton(
                "LEVELS",
                systemImage: "square.grid.2x2.fill",
                emphasis: .secondary,
                action: onLevels
            )

            GlassButton(
                "SETTINGS",
                systemImage: "slider.horizontal.3",
                emphasis: .quiet,
                action: onSettings
            )
        }
    }

    private var footer: some View {
        Label("\(totalLevels) handcrafted puzzles", systemImage: "sparkles")
            .font(.chromaticCaption)
            .foregroundStyle(ChromaticTheme.tertiaryText)
            .padding(.top, 2)
    }

    private var clampedCompletedCount: Int {
        min(max(progress.completedCount, 0), totalLevels)
    }

    private var totalLevels: Int {
        LevelProvider.totalLevelCount
    }

    private var primaryButtonTitle: String {
        if clampedCompletedCount == 0 {
            return "PLAY"
        }
        return clampedCompletedCount == totalLevels ? "PLAY AGAIN" : "CONTINUE"
    }

    private var progressHeadline: String {
        clampedCompletedCount == totalLevels ? "Collection complete" : "Your calm collection"
    }

    private var progressDetail: String {
        if clampedCompletedCount == totalLevels {
            return "Every color has found its place."
        }

        let level = min(max(progress.highestUnlockedLevel, 1), totalLevels)
        return clampedCompletedCount == 0
            ? "Your first pour is waiting."
            : "Level \(level) is ready when you are."
    }
}

private struct HomeTubeArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let compact: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                Ellipse()
                    .fill(ChromaticTheme.azure.opacity(0.18))
                    .frame(width: compact ? 245 : 310, height: compact ? 65 : 86)
                    .blur(radius: 22)
                    .offset(y: compact ? 50 : 68)

                HStack(alignment: .bottom, spacing: compact ? 16 : 22) {
                    MiniTube(
                        colors: [ChromaticTheme.coral, ChromaticTheme.sunshine, ChromaticTheme.violet],
                        height: compact ? 112 : 150
                    )
                    .rotationEffect(.degrees(sin(phase * 0.72) * 2.2), anchor: .bottom)
                    .offset(y: sin(phase * 0.58) * 4)

                    MiniTube(
                        colors: [ChromaticTheme.aqua, ChromaticTheme.azure, ChromaticTheme.violet, ChromaticTheme.coral],
                        height: compact ? 132 : 178
                    )
                    .offset(y: cos(phase * 0.52) * 5 - 4)

                    MiniTube(
                        colors: [ChromaticTheme.sunshine, ChromaticTheme.aqua],
                        height: compact ? 104 : 140
                    )
                    .rotationEffect(.degrees(cos(phase * 0.66) * 2.4), anchor: .bottom)
                    .offset(y: sin(phase * 0.49 + 1.4) * 4)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct MiniTube: View {
    let colors: [Color]
    let height: CGFloat

    private var width: CGFloat { height * 0.35 }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: width * 0.33, style: .continuous)
                .fill(Color.white.opacity(0.035))

            VStack(spacing: 1) {
                ForEach(colors.indices.reversed(), id: \.self) { index in
                    LinearGradient(
                        colors: [colors[index].opacity(0.86), colors[index]],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.white.opacity(0.20))
                            .frame(height: 1)
                    }
                }
            }
            .frame(height: height * CGFloat(colors.count) / 4.35)
            .clipShape(
                RoundedRectangle(cornerRadius: width * 0.28, style: .continuous)
            )
            .padding(.horizontal, width * 0.10)
            .padding(.bottom, width * 0.10)

            OpenTubeShape()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.78), Color.white.opacity(0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                )

            Capsule()
                .fill(Color.white.opacity(0.54))
                .frame(width: 2, height: height * 0.58)
                .blur(radius: 0.3)
                .offset(x: -width * 0.30, y: -height * 0.12)
        }
        .frame(width: width, height: height)
        .shadow(color: colors.last?.opacity(0.24) ?? .clear, radius: 13, y: 8)
    }
}

private struct OpenTubeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width * 0.34, rect.height * 0.12)
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
