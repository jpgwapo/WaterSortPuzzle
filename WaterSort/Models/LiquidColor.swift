import Foundation

/// The liquid identities used by the predefined puzzles.
///
/// Visual styling intentionally lives in the view layer. Keeping this type free of
/// SwiftUI makes puzzle states lightweight, deterministic, and easy to test.
enum LiquidColor: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case coral
    case tangerine
    case sunshine
    case lime
    case mint
    case teal
    case sky
    case blue
    case indigo
    case violet
    case magenta
    case rose
    case crimson
    case amber
    case forest
    case lavender
    case silver

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coral: "Coral"
        case .tangerine: "Tangerine"
        case .sunshine: "Sunshine"
        case .lime: "Lime"
        case .mint: "Mint"
        case .teal: "Teal"
        case .sky: "Sky"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .violet: "Violet"
        case .magenta: "Magenta"
        case .rose: "Rose"
        case .crimson: "Crimson"
        case .amber: "Amber"
        case .forest: "Forest"
        case .lavender: "Lavender"
        case .silver: "Silver"
        }
    }

    /// A compact, stable value used by the solver's state encoding.
    var solverID: UInt8 {
        switch self {
        case .coral: 1
        case .tangerine: 2
        case .sunshine: 3
        case .lime: 4
        case .mint: 5
        case .teal: 6
        case .sky: 7
        case .blue: 8
        case .indigo: 9
        case .violet: 10
        case .magenta: 11
        case .rose: 12
        case .crimson: 13
        case .amber: 14
        case .forest: 15
        case .lavender: 16
        case .silver: 17
        }
    }
}
