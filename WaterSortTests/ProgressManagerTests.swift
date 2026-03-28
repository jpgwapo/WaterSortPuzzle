import XCTest
@testable import WaterSort

final class ProgressManagerTests: XCTestCase {
    @MainActor
    func testCompletionUnlocksNextLevelAndPersistsBestMoves() throws {
        let suiteName = "WaterSortTests.Progress.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var progress: ProgressManager? = ProgressManager(defaults: defaults)
        XCTAssertTrue(try XCTUnwrap(progress).isUnlocked(1))
        XCTAssertFalse(try XCTUnwrap(progress).isUnlocked(2))

        try XCTUnwrap(progress).complete(level: 1, moves: 14)
        try XCTUnwrap(progress).complete(level: 1, moves: 19)
        XCTAssertTrue(try XCTUnwrap(progress).isUnlocked(2))
        XCTAssertEqual(try XCTUnwrap(progress).bestMoves(for: 1), 14)

        progress = nil
        let restored = ProgressManager(defaults: defaults)
        XCTAssertTrue(restored.isCompleted(1))
        XCTAssertTrue(restored.isUnlocked(2))
        XCTAssertEqual(restored.bestMoves(for: 1), 14)

        restored.resetProgress()
        XCTAssertEqual(restored.highestUnlockedLevel, 1)
        XCTAssertEqual(restored.completedCount, 0)
        XCTAssertNil(restored.bestMoves(for: 1))
    }

    @MainActor
    func testInProgressSessionRoundTripsAndResetClearsIt() throws {
        let suiteName = "WaterSortTests.Session.(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let progress = ProgressManager(defaults: defaults)
        let level = try XCTUnwrap(LevelProvider.level(1))
        let result = try level.initialBoard.pouring(from: 0, to: 1)
        let history = [MoveRecord(previousBoard: level.initialBoard, move: result.move)]

        progress.saveSession(level: level.id, board: result.board, moveHistory: history)

        let restoredProgress = ProgressManager(defaults: defaults)
        let restoredSession = try XCTUnwrap(restoredProgress.session(for: level.id))
        XCTAssertEqual(restoredSession.board, result.board)
        XCTAssertEqual(restoredSession.moveHistory, history)

        restoredProgress.resetProgress()
        XCTAssertNil(restoredProgress.session(for: level.id))
    }

    @MainActor
    func testLockedLevelCannotLeapfrogProgression() throws {
        let suiteName = "WaterSortTests.LockedCompletion.(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let progress = ProgressManager(defaults: defaults)
        progress.complete(level: 10, moves: 1)

        XCTAssertEqual(progress.highestUnlockedLevel, 1)
        XCTAssertFalse(progress.isCompleted(10))
        XCTAssertNil(progress.bestMoves(for: 10))
    }

    @MainActor
    func testLevelTwentyFourUnlocksFinalLevelAndCampaignCapsAtTwentyFive() throws {
        let suiteName = "WaterSortTests.FinalUnlock.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(24, forKey: "progress.highestUnlocked")

        let progress = ProgressManager(defaults: defaults)
        progress.complete(level: 24, moves: 42)

        XCTAssertTrue(progress.isUnlocked(25))
        XCTAssertFalse(progress.isUnlocked(26))

        progress.complete(level: 25, moves: 48)
        XCTAssertTrue(progress.isCompleted(25))
        XCTAssertEqual(progress.highestUnlockedLevel, 25)
    }

    @MainActor
    func testCompletedFormerFinalLevelAutomaticallyUnlocksLevelTwentyOne() throws {
        let suiteName = "WaterSortTests.CampaignMigration.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(20, forKey: "progress.highestUnlocked")
        defaults.set(Array(1...20), forKey: "progress.completed")

        let progress = ProgressManager(defaults: defaults)

        XCTAssertEqual(progress.highestUnlockedLevel, 21)
        XCTAssertTrue(progress.isUnlocked(21))
    }
}
