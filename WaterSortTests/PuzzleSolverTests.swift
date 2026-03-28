import XCTest
@testable import WaterSort

final class PuzzleSolverTests: XCTestCase {
    func testSolverReturnsACompleteLegalSolution() throws {
        let board = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .coral, .tangerine, .tangerine]),
            Tube(layers: [.tangerine, .tangerine, .coral, .coral]),
            Tube(),
            Tube(),
        ])

        let moves = try XCTUnwrap(PuzzleSolver().solve(board))
        XCTAssertFalse(moves.isEmpty)

        let solved = moves.reduce(board) { partialBoard, move in
            XCTAssertTrue(partialBoard.legalMoves.contains(move))
            return partialBoard.applying(move)
        }
        XCTAssertTrue(solved.isSolved)
    }

    func testHintIsTheFirstMoveOfASolverBackedSolution() throws {
        let level = try XCTUnwrap(LevelProvider.level(5))
        let solution = try XCTUnwrap(PuzzleSolver.solution(for: level.initialBoard))
        XCTAssertEqual(PuzzleSolver.hint(for: level.initialBoard), solution.first)
        XCTAssertTrue(level.initialBoard.legalMoves.contains(try XCTUnwrap(solution.first)))
    }

    func testSolvedBoardHasAnEmptySolutionAndNoHint() {
        let board = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .coral, .coral, .coral]),
            Tube(),
        ])

        XCTAssertEqual(PuzzleSolver.solve(board), [])
        XCTAssertNil(PuzzleSolver.hint(for: board))
    }
}
