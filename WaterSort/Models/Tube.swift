import Foundation

/// A value-type tube. Layers are stored from bottom to top.
struct Tube: Codable, Hashable, Sendable {
    static let standardCapacity = 4

    let capacity: Int
    private(set) var layers: [LiquidColor]

    init(layers: [LiquidColor] = [], capacity: Int = Tube.standardCapacity) {
        precondition(capacity > 0, "A tube must have positive capacity")
        precondition(layers.count <= capacity, "A tube cannot start over capacity")
        self.capacity = capacity
        self.layers = layers
    }

    var topColor: LiquidColor? { layers.last }
    var isEmpty: Bool { layers.isEmpty }
    var isFull: Bool { layers.count == capacity }
    var freeSpace: Int { capacity - layers.count }

    var topRunLength: Int {
        guard let topColor else { return 0 }
        return layers.reversed().prefix { $0 == topColor }.count
    }

    var isUniform: Bool {
        guard let first = layers.first else { return true }
        return layers.allSatisfy { $0 == first }
    }

    /// A solved tube must be full as well as monochromatic.
    var isComplete: Bool { isFull && isUniform }

    func canAccept(_ color: LiquidColor) -> Bool {
        freeSpace > 0 && (topColor == nil || topColor == color)
    }

    mutating func removeTopLayers(_ count: Int) -> [LiquidColor] {
        precondition(count >= 0 && count <= layers.count)
        guard count > 0 else { return [] }
        let removed = Array(layers.suffix(count))
        layers.removeLast(count)
        return removed
    }

    mutating func appendLayers(_ newLayers: [LiquidColor]) {
        precondition(newLayers.count <= freeSpace)
        layers.append(contentsOf: newLayers)
    }

    private enum CodingKeys: String, CodingKey {
        case capacity
        case layers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedCapacity = try container.decode(Int.self, forKey: .capacity)
        let decodedLayers = try container.decode([LiquidColor].self, forKey: .layers)

        guard decodedCapacity > 0, decodedLayers.count <= decodedCapacity else {
            throw DecodingError.dataCorruptedError(
                forKey: .layers,
                in: container,
                debugDescription: "The persisted tube has an invalid capacity or too many layers."
            )
        }

        capacity = decodedCapacity
        layers = decodedLayers
    }
}
