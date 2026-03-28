import XCTest
@testable import WaterSort

final class LevelValidationTests: XCTestCase {
    func testCampaignContainsExactlyTwentyFiveSequentialLevels() {
        XCTAssertEqual(LevelProvider.levels.count, 25)
        XCTAssertEqual(LevelProvider.levels.map(\.id), Array(1...25))
        XCTAssertEqual(LevelProvider.levels.first?.difficulty, .beginner)
        XCTAssertEqual(LevelProvider.levels.last?.difficulty, .master)
        XCTAssertEqual(LevelProvider.levels.last?.colorCount, 17)
        XCTAssertEqual(LevelProvider.levels.suffix(5).map(\.tubes.count), Array(15...19))
    }

    func testEveryLevelHasStandardColorCountsAndTwoEmptyTubes() {
        for level in LevelProvider.levels {
            let board = level.initialBoard
            let counts = Dictionary(grouping: board.tubes.flatMap(\.layers), by: { $0 })
                .mapValues(\.count)

            XCTAssertEqual(counts.count, level.colorCount, "Level \(level.id)")
            XCTAssertTrue(counts.values.allSatisfy { $0 == Tube.standardCapacity }, "Level \(level.id)")
            XCTAssertTrue(board.tubes.allSatisfy { $0.capacity == Tube.standardCapacity }, "Level \(level.id)")
            XCTAssertEqual(board.tubes.filter(\.isEmpty).count, 2, "Level \(level.id)")
            XCTAssertFalse(board.isSolved, "Level \(level.id) should require play")
        }
    }

    /// This is the campaign's release gate: no predefined puzzle ships unless the
    /// same solver used for hints can produce and replay a complete legal solution.
    func testPuzzleSolverSolvesAllTwentyFivePredefinedLevels() throws {
        let solver = PuzzleSolver(maxVisitedStates: 250_000)

        for level in LevelProvider.levels {
            let detailed = try XCTUnwrap(
                solver.detailedSolution(for: level.initialBoard),
                "Level \(level.id) must be solvable"
            )
            let finalBoard = detailed.moves.reduce(level.initialBoard) { board, move in
                board.applying(move)
            }

            XCTAssertTrue(finalBoard.isSolved, "Level \(level.id) solution must reach the goal")
            XCTAssertLessThan(detailed.visitedStateCount, 250_000, "Level \(level.id) search regressed")
        }
    }

    func testEveryLiquidHasAUniqueSolverIdentity() {
        XCTAssertEqual(LiquidColor.allCases.count, 17)
        XCTAssertEqual(Set(LiquidColor.allCases.map(\.solverID)).count, LiquidColor.allCases.count)
    }

    func testLevelTwentyTwoHasAProperMasterMix() throws {
        let level = try XCTUnwrap(LevelProvider.level(22))
        let filledTubes = level.tubes.filter { !$0.isEmpty }
        let solution = try XCTUnwrap(
            PuzzleSolver(maxVisitedStates: 250_000).detailedSolution(for: level.initialBoard)
        )

        XCTAssertTrue(filledTubes.allSatisfy { !$0.isUniform })
        XCTAssertTrue(filledTubes.allSatisfy { $0.topRunLength <= 2 })
        XCTAssertGreaterThanOrEqual(solution.moves.count, 28)
    }
}
