import Foundation

struct PuzzleLevel: Codable, Hashable, Identifiable, Sendable {
    enum Difficulty: String, Codable, CaseIterable, Sendable {
        case beginner
        case easy
        case medium
        case hard
        case expert
        case master

        var displayName: String { rawValue.capitalized }
    }

    let id: Int
    let title: String
    let difficulty: Difficulty
    let tubes: [Tube]

    init(id: Int, title: String, difficulty: Difficulty, tubes: [Tube]) {
        self.id = id
        self.title = title
        self.difficulty = difficulty
        self.tubes = tubes
    }

    var number: Int { id }
    var initialBoard: PuzzleBoard { PuzzleBoard(tubes: tubes) }
    var board: PuzzleBoard { initialBoard }
    var colorCount: Int { Set(tubes.flatMap(\.layers)).count }
}
