import XCTest
@testable import WaterSort

final class GameViewModelTests: XCTestCase {
    @MainActor
    func testTappingSelectedTubeAgainClearsSelection() throws {
        let context = try makeContext()
        defer { context.cleanUp() }

        let level = PuzzleLevel(
            id: 1,
            title: "Selection Test",
            difficulty: .beginner,
            tubes: [Tube(layers: [.coral]), Tube()]
        )
        let viewModel = GameViewModel(
            level: level,
            progress: context.progress,
            settings: context.settings
        )

        viewModel.tapTube(at: 0, reduceMotion: true)
        XCTAssertEqual(viewModel.selectedTubeIndex, 0)

        viewModel.tapTube(at: 0, reduceMotion: true)
        XCTAssertNil(viewModel.selectedTubeIndex)
    }

    @MainActor
    func testAnimatedMoveCanBeUndoneAndRestarted() async throws {
        let context = try makeContext()
        defer { context.cleanUp() }

        let level = PuzzleLevel(
            id: 1,
            title: "Interaction Test",
            difficulty: .beginner,
            tubes: [
                Tube(layers: [.coral, .tangerine]),
                Tube(layers: [.tangerine]),
                Tube(),
            ]
        )
        let viewModel = GameViewModel(
            level: level,
            progress: context.progress,
            settings: context.settings
        )
        let initialBoard = viewModel.board

        viewModel.tapTube(at: 0, reduceMotion: true)
        viewModel.tapTube(at: 1, reduceMotion: true)
        try await Task.sleep(nanoseconds: 250_000_000)

        XCTAssertEqual(viewModel.moveCount, 1)
        XCTAssertNotEqual(viewModel.board, initialBoard)
        XCTAssertTrue(viewModel.canUndo)

        viewModel.undo()
        XCTAssertEqual(viewModel.board, initialBoard)
        XCTAssertEqual(viewModel.moveCount, 0)

        viewModel.tapTube(at: 0, reduceMotion: true)
        viewModel.tapTube(at: 1, reduceMotion: true)
        try await Task.sleep(nanoseconds: 250_000_000)
        viewModel.restart()

        XCTAssertEqual(viewModel.board, initialBoard)
        XCTAssertEqual(viewModel.moveCount, 0)
        XCTAssertNil(context.progress.session(for: 1))
    }

    @MainActor
    func testWinningMoveCompletesLevelAndUnlocksNext() async throws {
        let context = try makeContext()
        defer { context.cleanUp() }

        let level = PuzzleLevel(
            id: 1,
            title: "Completion Test",
            difficulty: .beginner,
            tubes: [
                Tube(layers: [.coral, .coral, .coral]),
                Tube(layers: [.coral]),
                Tube(),
            ]
        )
        let viewModel = GameViewModel(
            level: level,
            progress: context.progress,
            settings: context.settings
        )

        viewModel.tapTube(at: 1, reduceMotion: true)
        viewModel.tapTube(at: 0, reduceMotion: true)
        try await Task.sleep(nanoseconds: 250_000_000)

        XCTAssertTrue(viewModel.board.isSolved)
        XCTAssertTrue(viewModel.isLevelComplete)
        XCTAssertTrue(context.progress.isCompleted(1))
        XCTAssertTrue(context.progress.isUnlocked(2))
        XCTAssertEqual(context.progress.bestMoves(for: 1), 1)
        XCTAssertNil(context.progress.session(for: 1))
    }

    @MainActor
    func testUnsolvableHintExplainsHowToRecover() async throws {
        let context = try makeContext()
        defer { context.cleanUp() }

        let level = PuzzleLevel(
            id: 1,
            title: "Dead Board Test",
            difficulty: .beginner,
            tubes: [Tube(layers: [.coral]), Tube()]
        )
        let viewModel = GameViewModel(
            level: level,
            progress: context.progress,
            settings: context.settings
        )

        viewModel.showHint()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(
            viewModel.hintStatusMessage,
            "No solution from here. Undo or restart."
        )
        XCTAssertNil(viewModel.hintedMove)
    }

    @MainActor
    private func makeContext() throws -> TestContext {
        let suiteName = "WaterSortTests.GameViewModel.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let progress = ProgressManager(defaults: defaults)
        let settings = SettingsStore(defaults: defaults)
        settings.hapticsEnabled = false
        settings.soundEffectsEnabled = false
        return TestContext(
            suiteName: suiteName,
            defaults: defaults,
            progress: progress,
            settings: settings
        )
    }
}

@MainActor
private struct TestContext {
    let suiteName: String
    let defaults: UserDefaults
    let progress: ProgressManager
    let settings: SettingsStore

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
