import Foundation

/// The visual state for one staged pour. The board remains the source of truth;
/// this value only carries the snapshot needed by the travelling tube overlay.
struct PourAnimationState: Identifiable {
    enum Phase: Equatable {
        case lifting
        case travelling
        case tilting
        case pouring
        case returning
    }

    let id = UUID()
    let move: PuzzleMove
    var displayedTube: Tube
    var phase: Phase

    var sourceIndex: Int { move.sourceIndex }
    var destinationIndex: Int { move.destinationIndex }
    var color: LiquidColor { move.color }
    var layerCount: Int { move.layerCount }
}
