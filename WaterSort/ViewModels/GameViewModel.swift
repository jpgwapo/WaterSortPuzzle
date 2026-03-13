import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var board: PuzzleBoard
    @Published private(set) var moveHistory: [MoveRecord] = []
    @Published private(set) var selectedTubeIndex: Int?
    @Published private(set) var activePour: PourAnimationState?
    @Published private(set) var hintedMove: PuzzleMove?
    @Published private(set) var hintStatusMessage: String?
    @Published private(set) var invalidTubeIndex: Int?
    @Published private(set) var invalidFeedbackID = 0
    @Published private(set) var isFindingHint = false
    @Published private(set) var didSetNewBest = false
    @Published private(set) var isLevelComplete = false
    @Published var isShowingRestartConfirmation = false

    let level: PuzzleLevel

    private let initialBoard: PuzzleBoard
    private let progress: ProgressManager
    private let settings: SettingsStore

    private var pourTask: Task<Void, Never>?
    private var hintTask: Task<Void, Never>?
    private var invalidFeedbackTask: Task<Void, Never>?

    init(
        level: PuzzleLevel,
        progress: ProgressManager,
        settings: SettingsStore
    ) {
        self.level = level
        self.progress = progress
        self.settings = settings

        let board = PuzzleBoard(tubes: level.tubes)
        initialBoard = board

        if let session = progress.session(for: level.id),
           !session.board.isSolved,
           Self.isRestorable(session, from: board) {
            self.board = session.board
            moveHistory = session.moveHistory
        } else {
            self.board = board
            progress.clearSession(for: level.id)
        }
    }

    deinit {
        pourTask?.cancel()
        hintTask?.cancel()
        invalidFeedbackTask?.cancel()
    }

    var tubes: [Tube] { board.tubes }
    var moveCount: Int { moveHistory.count }
    var bestMoveCount: Int? { progress.bestMoves(for: level.id) }
    var canUndo: Bool {
        !moveHistory.isEmpty && activePour == nil && !board.isSolved && !isLevelComplete
    }
    var isInteractionLocked: Bool { activePour != nil || board.isSolved || isLevelComplete }

    func tapTube(at index: Int, reduceMotion: Bool) {
        guard tubes.indices.contains(index), !isInteractionLocked else { return }

        hintTask?.cancel()
        hintedMove = nil
        hintStatusMessage = nil
        isFindingHint = false

        guard let selectedTubeIndex else {
            selectSource(at: index)
            return
        }

        if selectedTubeIndex == index {
            self.selectedTubeIndex = nil
            feedback(.selection)
            return
        }

        guard let move = board.legalMoves.first(where: {
            $0.sourceIndex == selectedTubeIndex && $0.destinationIndex == index
        }) else {
            showInvalidFeedback(at: index)
            return
        }

        startPour(move, reduceMotion: reduceMotion)
    }

    func undo() {
        guard canUndo, let record = moveHistory.popLast() else { return }

        cancelTransientState()
        board = record.previousBoard
        selectedTubeIndex = nil
        isLevelComplete = false
        progress.saveSession(level: level.id, board: board, moveHistory: moveHistory)
        feedback(.selection)
    }

    func requestRestart() {
        guard activePour == nil else { return }

        if moveCount >= 3 && !isLevelComplete {
            isShowingRestartConfirmation = true
        } else {
            restart()
        }
    }

    func restart() {
        pourTask?.cancel()
        cancelTransientState()
        board = initialBoard
        moveHistory = []
        selectedTubeIndex = nil
        activePour = nil
        pourTask = nil
        isLevelComplete = false
        didSetNewBest = false
        isShowingRestartConfirmation = false
        progress.clearSession(for: level.id)
        feedback(.selection)
    }

    func showHint() {
        guard !isInteractionLocked, !isFindingHint else { return }

        hintTask?.cancel()
        selectedTubeIndex = nil
        hintedMove = nil
        hintStatusMessage = nil
        isFindingHint = true
        feedback(.selection)

        let boardSnapshot = board
        hintTask = Task { [weak self] in
            let move = await Task.detached(priority: .userInitiated) {
                PuzzleSolver.hint(for: boardSnapshot)
            }.value

            guard !Task.isCancelled, let self else { return }
            isFindingHint = false

            guard board == boardSnapshot, activePour == nil else { return }
            guard let move else {
                let message = "No solution from here. Undo or restart."
                hintStatusMessage = message
                feedback(.invalid)
                try? await Task.sleep(nanoseconds: 2_800_000_000)
                guard !Task.isCancelled else { return }
                hintStatusMessage = nil
                hintTask = nil
                return
            }

            hintedMove = move
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            guard !Task.isCancelled else { return }
            hintedMove = nil
            hintTask = nil
        }
    }

    func isTubeSelected(_ index: Int) -> Bool {
        selectedTubeIndex == index
    }

    func isHintSource(_ index: Int) -> Bool {
        hintedMove?.sourceIndex == index
    }

    func isHintDestination(_ index: Int) -> Bool {
        hintedMove?.destinationIndex == index
    }

    func isTubeBeingPoured(_ index: Int) -> Bool {
        activePour?.sourceIndex == index
    }

    func accessibilityValue(forTubeAt index: Int) -> String {
        guard tubes.indices.contains(index) else { return "Unavailable" }

        let tube = tubes[index]
        guard !tube.layers.isEmpty else {
            return "Empty, \(tube.capacity) spaces available"
        }

        let colors = tube.layers.reversed().map(\.displayName).joined(separator: ", ")
        let spaces = tube.capacity - tube.layers.count
        return "Top to bottom: \(colors). \(spaces) \(spaces == 1 ? "space" : "spaces") available"
    }

    func accessibilityHint(forTubeAt index: Int) -> String {
        if isInteractionLocked {
            return "Wait for the current move to finish"
        }
        if selectedTubeIndex == index {
            return "Double tap to cancel selection"
        }
        if selectedTubeIndex != nil {
            return "Double tap to pour into this tube"
        }
        return tubes.indices.contains(index) && tubes[index].layers.isEmpty
            ? "This empty tube cannot be selected as a source"
            : "Double tap to select this tube"
    }

    private func selectSource(at index: Int) {
        guard !tubes[index].layers.isEmpty else {
            showInvalidFeedback(at: index)
            return
        }

        selectedTubeIndex = index
        feedback(.selection)
    }

    private func startPour(_ move: PuzzleMove, reduceMotion: Bool) {
        guard activePour == nil, tubes.indices.contains(move.sourceIndex) else { return }

        selectedTubeIndex = nil
        hintedMove = nil
        activePour = PourAnimationState(
            move: move,
            displayedTube: tubes[move.sourceIndex],
            phase: .lifting
        )

        pourTask = Task { [weak self] in
            guard let self else { return }

            if reduceMotion {
                await pause(milliseconds: 60)
                guard !Task.isCancelled else { return }
                activePour?.phase = .pouring
                feedback(.pour)
                await pause(milliseconds: 80)
                guard !Task.isCancelled else { return }
                guard commit(move) else { return }
                await pause(milliseconds: 80)
            } else {
                await pause(milliseconds: 150)
                guard !Task.isCancelled else { return }
                activePour?.phase = .travelling

                await pause(milliseconds: 235)
                guard !Task.isCancelled else { return }
                activePour?.phase = .tilting

                await pause(milliseconds: 190)
                guard !Task.isCancelled else { return }
                activePour?.phase = .pouring
                feedback(.pour)

                await pause(milliseconds: 120)
                let layerDuration = max(90, 300 / UInt64(max(move.layerCount, 1)))
                for _ in 0..<move.layerCount {
                    await pause(milliseconds: layerDuration)
                    guard !Task.isCancelled else { return }
                    drainDisplayedPourLayer()
                }

                await pause(milliseconds: 60)
                guard !Task.isCancelled else { return }
                guard commit(move) else { return }

                await pause(milliseconds: 160)
                guard !Task.isCancelled else { return }
                activePour?.phase = .returning

                await pause(milliseconds: 300)
            }

            guard !Task.isCancelled else { return }
            activePour = nil
            pourTask = nil

            if board.isSolved {
                completeLevel()
            }
        }
    }

    @discardableResult
    private func commit(_ move: PuzzleMove) -> Bool {
        let previousBoard = board
        guard let updatedBoard = try? board.applyingChecked(move) else {
            activePour = nil
            pourTask = nil
            showInvalidFeedback(at: move.destinationIndex)
            return false
        }

        board = updatedBoard
        moveHistory.append(MoveRecord(previousBoard: previousBoard, move: move))
        progress.saveSession(level: level.id, board: board, moveHistory: moveHistory)

        if tubes.indices.contains(move.sourceIndex), var pour = activePour {
            pour.displayedTube = tubes[move.sourceIndex]
            activePour = pour
        }
        return true
    }

    private func drainDisplayedPourLayer() {
        guard var pour = activePour, !pour.displayedTube.isEmpty else { return }
        _ = pour.displayedTube.removeTopLayers(1)
        activePour = pour
    }

    private func completeLevel() {
        let previousBest = progress.bestMoves(for: level.id)
        didSetNewBest = previousBest.map { moveCount < $0 } ?? true
        progress.clearSession(for: level.id)
        progress.complete(level: level.id, moves: moveCount)
        feedback(.success)
        isLevelComplete = true
    }

    private func showInvalidFeedback(at index: Int) {
        invalidFeedbackTask?.cancel()
        invalidFeedbackID += 1
        invalidTubeIndex = tubes.indices.contains(index) ? index : nil
        feedback(.invalid)

        invalidFeedbackTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 430_000_000)
            guard !Task.isCancelled else { return }
            self?.invalidTubeIndex = nil
        }
    }

    private func cancelTransientState() {
        hintTask?.cancel()
        invalidFeedbackTask?.cancel()
        hintTask = nil
        invalidFeedbackTask = nil
        isFindingHint = false
        hintedMove = nil
        hintStatusMessage = nil
        invalidTubeIndex = nil
    }

    private func feedback(_ feedback: HapticManager.Feedback) {
        HapticManager.shared.play(feedback, enabled: settings.hapticsEnabled)

        let effect: SoundManager.Effect
        switch feedback {
        case .selection: effect = .select
        case .pour: effect = .pour
        case .invalid: effect = .invalid
        case .success: effect = .success
        }
        SoundManager.shared.play(effect, enabled: settings.soundEffectsEnabled)
    }

    private func pause(milliseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }

    private static func isRestorable(
        _ session: SavedGameSession,
        from initial: PuzzleBoard
    ) -> Bool {
        guard isCompatible(session.board, with: initial),
              session.moveHistory.allSatisfy({ isCompatible($0.previousBoard, with: initial) }) else {
            return false
        }

        var replayedBoard = initial
        for record in session.moveHistory {
            guard record.previousBoard == replayedBoard,
                  let nextBoard = try? replayedBoard.applyingChecked(record.move) else {
                return false
            }
            replayedBoard = nextBoard
        }

        return replayedBoard == session.board
    }

    private static func isCompatible(_ candidate: PuzzleBoard, with initial: PuzzleBoard) -> Bool {
        guard candidate.tubes.count == initial.tubes.count,
              candidate.tubes.map(\.capacity) == initial.tubes.map(\.capacity) else {
            return false
        }

        func colorCounts(in board: PuzzleBoard) -> [LiquidColor: Int] {
            board.tubes
                .flatMap(\.layers)
                .reduce(into: [:]) { counts, color in
                    counts[color, default: 0] += 1
                }
        }

        return colorCounts(in: candidate) == colorCounts(in: initial)
    }
}
