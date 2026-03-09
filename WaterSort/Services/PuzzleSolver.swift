import Foundation

/// A deterministic depth-first solver with symmetry reduction and move ordering.
/// It is intentionally a value type so callers can use it safely from a detached task.
struct PuzzleSolver: Sendable {
    struct DetailedSolution: Equatable, Sendable {
        let moves: [PuzzleMove]
        let visitedStateCount: Int
    }

    let maxVisitedStates: Int
    let maxDepth: Int

    init(maxVisitedStates: Int = 750_000, maxDepth: Int = 256) {
        self.maxVisitedStates = max(1, maxVisitedStates)
        self.maxDepth = max(1, maxDepth)
    }

    func solve(_ board: PuzzleBoard) -> [PuzzleMove]? {
        detailedSolution(for: board)?.moves
    }

    func solve(_ tubes: [Tube]) -> [PuzzleMove]? {
        solve(PuzzleBoard(tubes: tubes))
    }

    func solution(for board: PuzzleBoard) -> [PuzzleMove]? {
        solve(board)
    }

    func solution(for tubes: [Tube]) -> [PuzzleMove]? {
        solve(tubes)
    }

    func hint(for board: PuzzleBoard) -> PuzzleMove? {
        solve(board)?.first
    }

    func hint(for tubes: [Tube]) -> PuzzleMove? {
        solve(tubes)?.first
    }

    func canSolve(_ board: PuzzleBoard) -> Bool {
        solve(board) != nil
    }

    func detailedSolution(for board: PuzzleBoard) -> DetailedSolution? {
        guard boardHasValidColorCounts(board) else { return nil }
        var search = Search(
            stateLimit: maxVisitedStates,
            depthLimit: maxDepth
        )
        guard search.visit(board, depth: 0) else { return nil }
        return DetailedSolution(
            moves: search.path,
            visitedStateCount: search.visitedStateCount
        )
    }

    // MARK: Static conveniences used by view models

    static func solve(_ board: PuzzleBoard) -> [PuzzleMove]? {
        PuzzleSolver().solve(board)
    }

    static func solution(for board: PuzzleBoard) -> [PuzzleMove]? {
        PuzzleSolver().solution(for: board)
    }

    static func hint(for board: PuzzleBoard) -> PuzzleMove? {
        PuzzleSolver().hint(for: board)
    }

    static func canSolve(_ board: PuzzleBoard) -> Bool {
        PuzzleSolver().canSolve(board)
    }

    /// Solved boards and standard puzzles contain complete groups of each color.
    /// Rejecting malformed boards prevents an expensive search with no possible goal.
    private func boardHasValidColorCounts(_ board: PuzzleBoard) -> Bool {
        let counts = Dictionary(grouping: board.tubes.flatMap(\.layers), by: { $0 })
            .mapValues(\.count)
        guard !counts.isEmpty else { return board.isSolved }
        return counts.values.allSatisfy { $0.isMultiple(of: Tube.standardCapacity) }
    }
}

private extension PuzzleSolver {
    struct StateKey: Hashable {
        let encodedTubes: [UInt64]

        init(_ board: PuzzleBoard) {
            // Tube positions have no semantic identity. Sorting their compact encodings
            // collapses equivalent permutations, especially swaps between empty tubes.
            encodedTubes = board.tubes.map(Self.encode).sorted()
        }

        private static func encode(_ tube: Tube) -> UInt64 {
            var value = UInt64(tube.capacity & 0xFF) << 56
            value |= UInt64(tube.layers.count & 0xFF) << 48
            for (index, color) in tube.layers.enumerated() {
                value |= UInt64(color.solverID) << UInt64(index * 8)
            }
            return value
        }
    }

    struct Search {
        let stateLimit: Int
        let depthLimit: Int

        var shallowestVisit: [StateKey: Int] = [:]
        var path: [PuzzleMove] = []
        var visitedStateCount = 0

        mutating func visit(_ board: PuzzleBoard, depth: Int) -> Bool {
            if board.isSolved { return true }
            guard depth < depthLimit, visitedStateCount < stateLimit else { return false }

            let key = StateKey(board)
            if let earlierDepth = shallowestVisit[key], earlierDepth <= depth {
                return false
            }
            shallowestVisit[key] = depth
            visitedStateCount += 1

            for move in orderedMoves(for: board) {
                let nextBoard = board.applying(move)
                guard nextBoard != board else { continue }

                path.append(move)
                if visit(nextBoard, depth: depth + 1) { return true }
                path.removeLast()
            }
            return false
        }

        private func orderedMoves(for board: PuzzleBoard) -> [PuzzleMove] {
            var firstEmptyDestination: Int?
            var scoredMoves: [(move: PuzzleMove, score: Int)] = []

            for move in board.legalMoves {
                let source = board.tubes[move.sourceIndex]
                let destination = board.tubes[move.destinationIndex]

                // A completed group never needs to be dismantled in a standard puzzle.
                guard !source.isComplete else { continue }

                if destination.isEmpty {
                    // Moving a uniform stack into an empty tube only renames two tubes.
                    guard !source.isUniform else { continue }

                    if let firstEmptyDestination {
                        guard move.destinationIndex == firstEmptyDestination else { continue }
                    } else {
                        firstEmptyDestination = move.destinationIndex
                    }
                }

                let remainingLayers = source.layers.count - move.layerCount
                let completesDestination = destination.layers.count + move.layerCount == destination.capacity
                let exposesCompleteSource = remainingLayers == source.capacity && source.isUniform

                var score = move.layerCount * 4
                score += destination.isEmpty ? -20 : 45
                score += completesDestination ? 120 : 0
                score += remainingLayers == 0 ? 14 : 0
                score += exposesCompleteSource ? 80 : 0
                scoredMoves.append((move, score))
            }

            return scoredMoves
                .sorted {
                    if $0.score != $1.score { return $0.score > $1.score }
                    if $0.move.sourceIndex != $1.move.sourceIndex {
                        return $0.move.sourceIndex < $1.move.sourceIndex
                    }
                    return $0.move.destinationIndex < $1.move.destinationIndex
                }
                .map(\.move)
        }
    }
}
