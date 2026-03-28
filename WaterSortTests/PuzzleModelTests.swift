import XCTest
@testable import WaterSort

final class PuzzleModelTests: XCTestCase {
    func testValidMoveDetection() throws {
        let board = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .tangerine]),
            Tube(layers: [.tangerine]),
        ])

        XCTAssertTrue(board.canPour(from: 0, to: 1))
        let result = try board.pouring(from: 0, to: 1)
        XCTAssertEqual(result.move.layerCount, 1)
        XCTAssertEqual(result.move.color, .tangerine)
        XCTAssertEqual(result.board.tubes[0].layers, [.coral])
        XCTAssertEqual(result.board.tubes[1].layers, [.tangerine, .tangerine])
    }

    func testInvalidMovesAreRejected() {
        let board = PuzzleBoard(tubes: [
            Tube(),
            Tube(layers: [.coral]),
            Tube(layers: [.tangerine]),
        ])

        XCTAssertFalse(board.canPour(from: 0, to: 1), "An empty source cannot pour")
        XCTAssertFalse(board.canPour(from: 1, to: 1), "A tube cannot pour into itself")
        XCTAssertFalse(board.canPour(from: 1, to: 2), "Different top colors cannot mix")
        XCTAssertThrowsError(try board.pouring(from: 1, to: 2)) { error in
            XCTAssertEqual(error as? PuzzleRuleError, .colorsDoNotMatch)
        }
    }

    func testPourMovesTheMaximalMatchingTopRun() throws {
        let board = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .blue, .blue]),
            Tube(layers: [.blue]),
        ])

        let result = try board.pouring(from: 0, to: 1)
        XCTAssertEqual(result.move.layerCount, 2)
        XCTAssertEqual(result.board.tubes[0].layers, [.coral])
        XCTAssertEqual(result.board.tubes[1].layers, [.blue, .blue, .blue])
    }

    func testDestinationCapacityLimitsTheMaximalRun() throws {
        let board = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .blue, .blue]),
            Tube(layers: [.blue, .blue, .blue]),
        ])

        let result = try board.pouring(from: 0, to: 1)
        XCTAssertEqual(result.move.layerCount, 1)
        XCTAssertEqual(result.board.tubes[0].layers, [.coral, .blue])
        XCTAssertEqual(result.board.tubes[1].layers.count, Tube.standardCapacity)
        XCTAssertTrue(result.board.tubes[1].isComplete)
        XCTAssertFalse(result.board.canPour(from: 0, to: 1))
    }

    func testUndoRestoresTheExactPreviousBoard() throws {
        let original = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .teal, .teal]),
            Tube(layers: [.teal]),
            Tube(),
        ])

        let result = try original.pouring(from: 0, to: 1)
        let restored = try result.board.undoing(result.move)
        XCTAssertEqual(restored, original)
    }

    func testMultipleConsecutiveUndos() throws {
        let initial = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .tangerine]),
            Tube(layers: [.tangerine]),
            Tube(),
        ])
        let first = try initial.pouring(from: 0, to: 1)
        let second = try first.board.pouring(from: 0, to: 2)

        let afterFirstUndo = try second.board.undoing(second.move)
        let afterSecondUndo = try afterFirstUndo.undoing(first.move)
        XCTAssertEqual(afterFirstUndo, first.board)
        XCTAssertEqual(afterSecondUndo, initial)
    }

    func testWinDetectionRequiresFullUniformNonEmptyTubes() {
        XCTAssertTrue(PuzzleBoard(tubes: [
            Tube(layers: [.coral, .coral, .coral, .coral]),
            Tube(),
        ]).isSolved)

        XCTAssertFalse(PuzzleBoard(tubes: [
            Tube(layers: [.coral, .coral, .coral]),
            Tube(),
        ]).isSolved)

        XCTAssertFalse(PuzzleBoard(tubes: [
            Tube(layers: [.coral, .coral, .coral, .tangerine]),
            Tube(),
        ]).isSolved)
    }

    func testMoveRecordRoundTripsThroughCodable() throws {
        let board = PuzzleBoard(tubes: [
            Tube(layers: [.coral, .blue]),
            Tube(),
        ])
        let result = try board.pouring(from: 0, to: 1)
        let record = MoveRecord(previousBoard: board, move: result.move)

        let encoded = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(MoveRecord.self, from: encoded)
        XCTAssertEqual(decoded, record)
    }
}
