import SwiftUI
import UIKit

struct GameView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var viewModel: GameViewModel
    @State private var tubeFrames: [Int: CGRect] = [:]

    private let onClose: () -> Void
    private let onOpenSettings: () -> Void
    private let onNextLevel: () -> Void

    init(
        level: PuzzleLevel,
        progress: ProgressManager,
        settings: SettingsStore,
        onClose: @escaping () -> Void = {},
        onOpenSettings: @escaping () -> Void = {},
        onNextLevel: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: GameViewModel(
                level: level,
                progress: progress,
                settings: settings
            )
        )
        self.onClose = onClose
        self.onOpenSettings = onOpenSettings
        self.onNextLevel = onNextLevel
    }

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720 || dynamicTypeSize.isAccessibilitySize

            ZStack {
                BackgroundView(intensity: 0.92)

                VStack(spacing: compactHeight ? 10 : 15) {
                    header
                    moveCounter

                    gameBoard
                        .frame(maxHeight: .infinity)
                        .layoutPriority(1)

                    bottomControls(compact: compactHeight)
                }
                .padding(.horizontal, compactHeight ? 14 : 18)
                .padding(.top, 8)
                .padding(.bottom, compactHeight ? 9 : 15)

                if viewModel.isLevelComplete {
                    LevelCompleteView(
                        levelNumber: viewModel.level.id,
                        moves: viewModel.moveCount,
                        bestMoves: viewModel.bestMoveCount,
                        isNewBest: viewModel.didSetNewBest,
                        isFinalLevel: viewModel.level.id == LevelProvider.totalLevelCount,
                        onRestart: viewModel.restart,
                        onNextLevel: onNextLevel
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Restart this level?", isPresented: $viewModel.isShowingRestartConfirmation) {
            Button("Keep Playing", role: .cancel) {}
            Button("Restart", role: .destructive, action: viewModel.restart)
        } message: {
            Text("Your \(viewModel.moveCount) moves on this board will be cleared.")
        }
        .animation(
            reduceMotion ? .linear(duration: 0.12) : .spring(response: 0.4, dampingFraction: 0.84),
            value: viewModel.isLevelComplete
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            GlassIconButton(
                systemImage: "xmark",
                accessibilityLabel: "Close level",
                action: onClose
            )
            .disabled(viewModel.activePour != nil)

            Spacer(minLength: 4)

            VStack(spacing: 2) {
                Text("LEVEL \(viewModel.level.id)")
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(ChromaticTheme.primaryText)

                Text(viewModel.level.title)
                    .font(.chromaticCaption)
                    .foregroundStyle(ChromaticTheme.secondaryText)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("game.level.heading")

            Spacer(minLength: 4)

            GlassIconButton(
                systemImage: "gearshape.fill",
                accessibilityLabel: "Settings",
                action: onOpenSettings
            )
            .disabled(viewModel.activePour != nil)
        }
    }

    private var moveCounter: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(ChromaticTheme.aqua)
                .accessibilityHidden(true)

            Text("\(viewModel.moveCount)")
                .contentTransition(.numericText(value: Double(viewModel.moveCount)))
                .monospacedDigit()

            Text(viewModel.moveCount == 1 ? "MOVE" : "MOVES")
                .foregroundStyle(ChromaticTheme.secondaryText)
        }
        .font(.chromaticCaption)
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.055), in: Capsule())
        .overlay { Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.moveCount) \(viewModel.moveCount == 1 ? "move" : "moves")")
    }

    private var gameBoard: some View {
        ZStack(alignment: .top) {
            GameTubeBoard(
                tubes: viewModel.tubes,
                selectedTubeIndex: viewModel.selectedTubeIndex,
                hintSourceIndex: viewModel.hintedMove?.sourceIndex,
                hintDestinationIndex: viewModel.hintedMove?.destinationIndex,
                pouringSourceIndex: viewModel.activePour?.sourceIndex,
                invalidTubeIndex: viewModel.invalidTubeIndex,
                invalidFeedbackID: viewModel.invalidFeedbackID,
                isInteractionLocked: viewModel.isInteractionLocked,
                accessibilityValue: viewModel.accessibilityValue,
                accessibilityHint: viewModel.accessibilityHint,
                onTap: { index in
                    viewModel.tapTube(at: index, reduceMotion: reduceMotion)
                }
            )

            if let hint = viewModel.hintedMove {
                GameHintBanner(
                    sourceNumber: hint.sourceIndex + 1,
                    destinationNumber: hint.destinationIndex + 1
                )
                .padding(.top, 2)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(6)
            } else if let message = viewModel.hintStatusMessage {
                GameHintStatusBanner(message: message)
                    .padding(.top, 2)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(6)
            }

            if let pour = viewModel.activePour,
               let sourceFrame = tubeFrames[pour.sourceIndex],
               let destinationFrame = tubeFrames[pour.destinationIndex] {
                PourAnimationView(
                    state: pour,
                    sourceFrame: sourceFrame,
                    destinationFrame: destinationFrame,
                    reduceMotion: reduceMotion
                )
                .zIndex(10)
            }
        }
        .coordinateSpace(name: GameTubeBoard.coordinateSpaceName)
        .onPreferenceChange(GameTubeFramePreferenceKey.self) { tubeFrames = $0 }
        .animation(.easeInOut(duration: 0.18), value: viewModel.hintedMove?.sourceIndex)
        .onChange(of: viewModel.hintStatusMessage) { _, message in
            guard let message else { return }
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    private func bottomControls(compact: Bool) -> some View {
        HStack(spacing: compact ? 9 : 12) {
            GameControlButton(
                title: "UNDO",
                systemImage: "arrow.uturn.backward",
                tint: ChromaticTheme.azure,
                compact: compact,
                action: viewModel.undo
            )
            .disabled(!viewModel.canUndo)

            GameControlButton(
                title: "RESTART",
                systemImage: "arrow.counterclockwise",
                tint: ChromaticTheme.coral,
                compact: compact,
                action: viewModel.requestRestart
            )
            .disabled(viewModel.activePour != nil)

            GameControlButton(
                title: "HINT",
                systemImage: viewModel.isFindingHint ? "hourglass" : "sparkles",
                tint: ChromaticTheme.sunshine,
                compact: compact,
                action: viewModel.showHint
            )
            .disabled(viewModel.isInteractionLocked || viewModel.isFindingHint)
        }
        .frame(maxWidth: 470)
    }
}

private struct GameTubeBoard: View {
    static let coordinateSpaceName = "game-tube-board"

    let tubes: [Tube]
    let selectedTubeIndex: Int?
    let hintSourceIndex: Int?
    let hintDestinationIndex: Int?
    let pouringSourceIndex: Int?
    let invalidTubeIndex: Int?
    let invalidFeedbackID: Int
    let isInteractionLocked: Bool
    let accessibilityValue: (Int) -> String
    let accessibilityHint: (Int) -> String
    let onTap: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let metrics = metrics(for: proxy.size)

            VStack(spacing: metrics.rowSpacing) {
                ForEach(0..<metrics.rowCount, id: \.self) { row in
                    HStack(alignment: .bottom, spacing: metrics.columnSpacing) {
                        ForEach(indices(in: row, columns: metrics.columnCount), id: \.self) { index in
                            Button {
                                onTap(index)
                            } label: {
                                TubeView(
                                    tube: tubes[index],
                                    isSelected: selectedTubeIndex == index,
                                    isHintSource: hintSourceIndex == index,
                                    isHintDestination: hintDestinationIndex == index,
                                    isPouring: pouringSourceIndex == index,
                                    invalidFeedbackID: invalidTubeIndex == index ? invalidFeedbackID : 0
                                )
                                .frame(width: metrics.tubeWidth, height: metrics.tubeHeight)
                                .background {
                                    GeometryReader { tubeProxy in
                                        Color.clear.preference(
                                            key: GameTubeFramePreferenceKey.self,
                                            value: [
                                                index: tubeProxy.frame(in: .named(Self.coordinateSpaceName)),
                                            ]
                                        )
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .disabled(isInteractionLocked)
                            .zIndex(selectedTubeIndex == index ? 2 : 0)
                            .accessibilityLabel("Tube \(index + 1)")
                            .accessibilityIdentifier("game.tube.\(index + 1)")
                            .accessibilityValue(accessibilityValue(index))
                            .accessibilityHint(accessibilityHint(index))
                            .accessibilityAddTraits(selectedTubeIndex == index ? .isSelected : [])
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func metrics(for size: CGSize) -> Metrics {
        let count = max(tubes.count, 1)
        let columns = min(7, max(3, Int(ceil(Double(count) / 2))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        let columnSpacing: CGFloat = size.width < 350 ? 6 : 9
        let rowSpacing: CGFloat = size.height < 330 ? 13 : 24
        let cellWidth = (size.width - CGFloat(columns - 1) * columnSpacing) / CGFloat(columns)
        let maximumHeight = (size.height - CGFloat(rows - 1) * rowSpacing) / CGFloat(rows)
        let tubeWidth = min(cellWidth, maximumHeight * 0.34, 57)
        let tubeHeight = tubeWidth / 0.34

        return Metrics(
            columnCount: columns,
            rowCount: rows,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            tubeWidth: max(31, tubeWidth),
            tubeHeight: max(91, tubeHeight)
        )
    }

    private func indices(in row: Int, columns: Int) -> Range<Int> {
        let start = row * columns
        let end = min(start + columns, tubes.count)
        return start..<max(start, end)
    }

    private struct Metrics {
        let columnCount: Int
        let rowCount: Int
        let columnSpacing: CGFloat
        let rowSpacing: CGFloat
        let tubeWidth: CGFloat
        let tubeHeight: CGFloat
    }
}

private struct GameHintBanner: View {
    let sourceNumber: Int
    let destinationNumber: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(ChromaticTheme.sunshine)
                .accessibilityHidden(true)

            Text("Tube \(sourceNumber)")
                .foregroundStyle(ChromaticTheme.sunshine)

            Image(systemName: "arrow.right")
                .foregroundStyle(ChromaticTheme.secondaryText)
                .accessibilityHidden(true)

            Text("Tube \(destinationNumber)")
                .foregroundStyle(ChromaticTheme.aqua)
        }
        .font(.chromaticCaption)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1) }
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hint: pour tube \(sourceNumber) into tube \(destinationNumber)")
    }
}

private struct GameHintStatusBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "arrow.uturn.backward.circle.fill")
            .font(.chromaticCaption)
            .foregroundStyle(ChromaticTheme.primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(ChromaticTheme.sunshine.opacity(0.36), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
            .accessibilityLabel(message)
    }
}

private struct GameControlButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let systemImage: String
    let tint: Color
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: compact ? 5 : 7) {
                Image(systemName: systemImage)
                    .font(.system(compact ? .body : .title3, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(ChromaticTheme.primaryText)
            .frame(maxWidth: .infinity)
            .frame(minHeight: compact ? 56 : 68)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(tint.opacity(0.055))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.16), radius: 12, y: 7)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(GameControlButtonStyle(reduceMotion: reduceMotion))
        .opacity(isEnabled ? 1 : 0.38)
        .accessibilityLabel(title.capitalized)
    }
}

private struct GameControlButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

private struct GameTubeFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
