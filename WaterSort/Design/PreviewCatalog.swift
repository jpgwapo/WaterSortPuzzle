#if DEBUG
import SwiftUI

@MainActor
private struct HomeScreenPreview: View {
    @State private var progress: ProgressManager

    init() {
        let defaults = UserDefaults(suiteName: "WaterSort.Preview.Home") ?? .standard
        defaults.removePersistentDomain(forName: "WaterSort.Preview.Home")
        let progress = ProgressManager(defaults: defaults)
        progress.complete(level: 1, moves: 8)
        progress.complete(level: 2, moves: 10)
        _progress = State(initialValue: progress)
    }

    var body: some View {
        HomeView(
            progress: progress,
            onPlay: {},
            onLevels: {},
            onSettings: {}
        )
    }
}

@MainActor
private struct LevelGridPreview: View {
    @State private var progress: ProgressManager

    init() {
        let defaults = UserDefaults(suiteName: "WaterSort.Preview.Levels") ?? .standard
        defaults.removePersistentDomain(forName: "WaterSort.Preview.Levels")
        let progress = ProgressManager(defaults: defaults)
        for level in 1...5 {
            progress.complete(level: level, moves: level * 4 + 3)
        }
        _progress = State(initialValue: progress)
    }

    var body: some View {
        NavigationStack {
            LevelSelectionView(progress: progress, onSelectLevel: { _ in })
        }
    }
}

@MainActor
private struct GameScreenPreview: View {
    @State private var progress: ProgressManager
    @State private var settings: SettingsStore

    init() {
        let suite = "WaterSort.Preview.Game"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        _progress = State(initialValue: ProgressManager(defaults: defaults))
        _settings = State(initialValue: SettingsStore(defaults: defaults))
    }

    var body: some View {
        GameView(
            level: LevelProvider.level(8) ?? fallbackLevel,
            progress: progress,
            settings: settings
        )
    }

    private var fallbackLevel: PuzzleLevel {
        PuzzleLevel(
            id: 1,
            title: "Preview",
            difficulty: .beginner,
            tubes: [
                Tube(layers: [.coral, .sunshine, .coral, .sunshine]),
                Tube(layers: [.sunshine, .coral, .sunshine, .coral]),
                Tube(),
                Tube(),
            ]
        )
    }
}

#Preview("Home — progress") {
    HomeScreenPreview()
}

#Preview("Level collection") {
    LevelGridPreview()
}

#Preview("Gameplay — medium") {
    GameScreenPreview()
}
#endif
