import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    private enum Key {
        static let sound = "settings.soundEffects"
        static let haptics = "settings.haptics"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var soundEffectsEnabled: Bool { didSet { defaults.set(soundEffectsEnabled, forKey: Key.sound) } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        soundEffectsEnabled = defaults.object(forKey: Key.sound) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Key.haptics) as? Bool ?? true
    }
}
