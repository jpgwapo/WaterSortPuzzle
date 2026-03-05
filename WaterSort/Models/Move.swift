import Foundation

/// A fully resolved pour. The count records the maximal run that was transferred.
struct PuzzleMove: Codable, Hashable, Sendable {
    let sourceIndex: Int
    let destinationIndex: Int
    let color: LiquidColor
    let layerCount: Int

    init(
        sourceIndex: Int,
        destinationIndex: Int,
        color: LiquidColor,
        layerCount: Int
    ) {
        self.sourceIndex = sourceIndex
        self.destinationIndex = destinationIndex
        self.color = color
        self.layerCount = layerCount
    }

    init(from sourceIndex: Int, to destinationIndex: Int, color: LiquidColor, layerCount: Int) {
        self.init(
            sourceIndex: sourceIndex,
            destinationIndex: destinationIndex,
            color: color,
            layerCount: layerCount
        )
    }

    var source: Int { sourceIndex }
    var destination: Int { destinationIndex }
}

/// Compatibility with the concise domain name used in architecture diagrams.
typealias Move = PuzzleMove

/// One valid state transition, suitable for animation and history recording.
struct PourResult: Hashable, Sendable {
    let board: PuzzleBoard
    let move: PuzzleMove
}

/// A persisted undo entry. Retaining the previous board makes restoration exact
/// even if undo behavior evolves independently of normal pour rules.
struct MoveRecord: Codable, Hashable, Sendable {
    let previousBoard: PuzzleBoard
    let move: PuzzleMove

    init(previousBoard: PuzzleBoard, move: PuzzleMove) {
        self.previousBoard = previousBoard
        self.move = move
    }
}

enum PuzzleRuleError: Error, Equatable, LocalizedError, Sendable {
    case tubeIndexOutOfBounds
    case sameTube
    case sourceEmpty
    case destinationFull
    case colorsDoNotMatch
    case staleMove
    case invalidUndo

    var errorDescription: String? {
        switch self {
        case .tubeIndexOutOfBounds: "That tube is not on this board."
        case .sameTube: "Choose a different destination tube."
        case .sourceEmpty: "The source tube is empty."
        case .destinationFull: "The destination tube is full."
        case .colorsDoNotMatch: "The top liquid colors do not match."
        case .staleMove: "The move no longer matches the board."
        case .invalidUndo: "That move cannot be undone from the current board."
        }
    }
}
