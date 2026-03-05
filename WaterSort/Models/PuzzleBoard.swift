import Foundation

/// The complete puzzle state. All mutations return a new board value.
struct PuzzleBoard: Codable, Hashable, Sendable {
    private(set) var tubes: [Tube]

    init(tubes: [Tube]) {
        self.tubes = tubes
    }

    /// Empty tubes are allowed; every non-empty tube must be full and uniform.
    var isSolved: Bool {
        tubes.allSatisfy { $0.isEmpty || $0.isComplete }
    }

    var legalMoves: [PuzzleMove] {
        tubes.indices.flatMap { sourceIndex in
            tubes.indices.compactMap { destinationIndex in
                resolvedMove(from: sourceIndex, to: destinationIndex)
            }
        }
    }

    func canPour(from sourceIndex: Int, to destinationIndex: Int) -> Bool {
        resolvedMove(from: sourceIndex, to: destinationIndex) != nil
    }

    /// Resolves a player selection into the exact maximal pour required by the rules.
    func move(from sourceIndex: Int, to destinationIndex: Int) -> PuzzleMove? {
        resolvedMove(from: sourceIndex, to: destinationIndex)
    }

    func pouring(from sourceIndex: Int, to destinationIndex: Int) throws -> PourResult {
        let move = try checkedMove(from: sourceIndex, to: destinationIndex)
        return PourResult(board: try applyingChecked(move), move: move)
    }

    /// Applies a solver-generated or otherwise known legal move. A stale/invalid move
    /// leaves the board unchanged, keeping animation completion code safe and simple.
    func applying(_ move: PuzzleMove) -> PuzzleBoard {
        (try? applyingChecked(move)) ?? self
    }

    /// Strict variant for tests, persistence restoration, and other trust boundaries.
    func applyingChecked(_ move: PuzzleMove) throws -> PuzzleBoard {
        guard let currentMove = resolvedMove(
            from: move.sourceIndex,
            to: move.destinationIndex
        ), currentMove == move else {
            throw PuzzleRuleError.staleMove
        }

        var nextTubes = tubes
        let transferred = nextTubes[move.sourceIndex].removeTopLayers(move.layerCount)
        nextTubes[move.destinationIndex].appendLayers(transferred)
        return PuzzleBoard(tubes: nextTubes)
    }

    /// Reverses the recorded number of layers without applying normal forward-pour
    /// matching rules. Calling this in LIFO order supports any number of undos.
    func undoing(_ move: PuzzleMove) throws -> PuzzleBoard {
        guard tubes.indices.contains(move.sourceIndex),
              tubes.indices.contains(move.destinationIndex),
              move.sourceIndex != move.destinationIndex,
              move.layerCount > 0 else {
            throw PuzzleRuleError.invalidUndo
        }

        let destination = tubes[move.destinationIndex]
        let source = tubes[move.sourceIndex]
        guard destination.layers.count >= move.layerCount,
              destination.layers.suffix(move.layerCount).allSatisfy({ $0 == move.color }),
              source.freeSpace >= move.layerCount else {
            throw PuzzleRuleError.invalidUndo
        }

        var previousTubes = tubes
        let returned = previousTubes[move.destinationIndex].removeTopLayers(move.layerCount)
        previousTubes[move.sourceIndex].appendLayers(returned)
        return PuzzleBoard(tubes: previousTubes)
    }

    private func resolvedMove(from sourceIndex: Int, to destinationIndex: Int) -> PuzzleMove? {
        guard tubes.indices.contains(sourceIndex),
              tubes.indices.contains(destinationIndex),
              sourceIndex != destinationIndex else {
            return nil
        }

        let source = tubes[sourceIndex]
        let destination = tubes[destinationIndex]
        guard let color = source.topColor, destination.canAccept(color) else { return nil }

        return PuzzleMove(
            sourceIndex: sourceIndex,
            destinationIndex: destinationIndex,
            color: color,
            layerCount: min(source.topRunLength, destination.freeSpace)
        )
    }

    private func checkedMove(from sourceIndex: Int, to destinationIndex: Int) throws -> PuzzleMove {
        guard tubes.indices.contains(sourceIndex), tubes.indices.contains(destinationIndex) else {
            throw PuzzleRuleError.tubeIndexOutOfBounds
        }
        guard sourceIndex != destinationIndex else { throw PuzzleRuleError.sameTube }

        let source = tubes[sourceIndex]
        let destination = tubes[destinationIndex]
        guard let color = source.topColor else { throw PuzzleRuleError.sourceEmpty }
        guard !destination.isFull else { throw PuzzleRuleError.destinationFull }
        guard destination.topColor == nil || destination.topColor == color else {
            throw PuzzleRuleError.colorsDoNotMatch
        }

        return PuzzleMove(
            sourceIndex: sourceIndex,
            destinationIndex: destinationIndex,
            color: color,
            layerCount: min(source.topRunLength, destination.freeSpace)
        )
    }
}
