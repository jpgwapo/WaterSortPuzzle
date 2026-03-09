import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    enum Effect {
        case select
        case pour
        case invalid
        case success

        fileprivate var systemSoundID: SystemSoundID {
            switch self {
            case .select: 1104
            case .pour: 1105
            case .invalid: 1053
            case .success: 1025
            }
        }
    }

    private init() {}

    func play(_ effect: Effect, enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
