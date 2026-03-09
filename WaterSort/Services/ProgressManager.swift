import Foundation
import Observation

struct SavedGameSession: Codable {
    let board: PuzzleBoard
    let moveHistory: [MoveRecord]
}

@MainActor
@Observable
final class ProgressManager {
    private enum Key {
        static let highestUnlocked = "progress.highestUnlocked"
        static let completed = "progress.completed"
        static let bestMoves = "progress.bestMoves"
        static let sessionPrefix = "progress.session."
    }

    @ObservationIgnored private let defaults: UserDefaults

    private static var validLevels: ClosedRange<Int> {
        1...LevelProvider.totalLevelCount
    }

    private(set) var highestUnlockedLevel: Int
    private(set) var completedLevels: Set<Int>
    private(set) var bestMoves: [Int: Int]
    private(set) var resetGeneration: Int

    var completedCount: Int { completedLevels.count }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        resetGeneration = 0
        highestUnlockedLevel = min(
            LevelProvider.totalLevelCount,
            max(1, defaults.integer(forKey: Key.highestUnlocked))
        )
        completedLevels = Set(
            (defaults.array(forKey: Key.completed) as? [Int] ?? [])
                .filter(Self.validLevels.contains)
        )

        if let data = defaults.data(forKey: Key.bestMoves),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            bestMoves = decoded.filter { Self.validLevels.contains($0.key) }
        } else {
            bestMoves = [:]
        }

        // A player who completed the former final level should receive the newly
        // added continuation automatically instead of having to replay level 20.
        if let latestCompletedLevel = completedLevels.max() {
            highestUnlockedLevel = min(
                LevelProvider.totalLevelCount,
                max(highestUnlockedLevel, latestCompletedLevel + 1)
            )
        }
    }

    func isUnlocked(_ level: Int) -> Bool {
        Self.validLevels.contains(level) && level <= highestUnlockedLevel
    }

    func isCompleted(_ level: Int) -> Bool {
        completedLevels.contains(level)
    }

    func bestMoves(for level: Int) -> Int? {
        bestMoves[level]
    }

    func complete(level: Int, moves: Int) {
        guard Self.validLevels.contains(level), moves >= 0, isUnlocked(level) else { return }
        completedLevels.insert(level)
        bestMoves[level] = min(bestMoves[level] ?? .max, moves)
        highestUnlockedLevel = min(
            LevelProvider.totalLevelCount,
            max(highestUnlockedLevel, level + 1)
        )
        clearSession(for: level)
        persist()
    }

    func session(for level: Int) -> SavedGameSession? {
        guard Self.validLevels.contains(level),
              let data = defaults.data(forKey: sessionKey(for: level)) else {
            return nil
        }
        return try? JSONDecoder().decode(SavedGameSession.self, from: data)
    }

    func saveSession(
        level: Int,
        board: PuzzleBoard,
        moveHistory: [MoveRecord]
    ) {
        guard Self.validLevels.contains(level),
              let data = try? JSONEncoder().encode(
                SavedGameSession(board: board, moveHistory: moveHistory)
              ) else {
            return
        }
        defaults.set(data, forKey: sessionKey(for: level))
    }

    func clearSession(for level: Int) {
        guard Self.validLevels.contains(level) else { return }
        defaults.removeObject(forKey: sessionKey(for: level))
    }

    func resetProgress() {
        highestUnlockedLevel = 1
        completedLevels = []
        bestMoves = [:]
        resetGeneration &+= 1
        for level in Self.validLevels {
            clearSession(for: level)
        }
        persist()
    }

    private func persist() {
        defaults.set(highestUnlockedLevel, forKey: Key.highestUnlocked)
        defaults.set(completedLevels.sorted(), forKey: Key.completed)
        defaults.set(try? JSONEncoder().encode(bestMoves), forKey: Key.bestMoves)
    }

    private func sessionKey(for level: Int) -> String {
        Key.sessionPrefix + String(level)
    }
}
