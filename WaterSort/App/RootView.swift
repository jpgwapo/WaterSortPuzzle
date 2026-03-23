import SwiftUI

private enum AppRoute: Hashable {
    case levels
    case game(level: Int)
}

private enum AppSheet: String, Identifiable {
    case settings

    var id: String { rawValue }
}

@MainActor
struct RootView: View {
    let progress: ProgressManager
    let settings: SettingsStore

    @State private var path: [AppRoute] = []
    @State private var presentedSheet: AppSheet?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                progress: progress,
                onPlay: { openLevel(continueLevel) },
                onLevels: { path.append(.levels) },
                onSettings: { presentedSheet = .settings }
            )
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .tint(ChromaticTheme.aqua)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView(settings: settings, progress: progress)
            }
        }
        .onChange(of: progress.highestUnlockedLevel) { previous, current in
            guard current < previous else { return }
            let containsNewlyLockedGame = path.contains { route in
                if case .game(let level) = route {
                    return level > current
                }
                return false
            }
            if containsNewlyLockedGame {
                path = []
            }
        }
        .onChange(of: progress.resetGeneration) { _, _ in
            path = []
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .levels:
            LevelSelectionView(progress: progress) { level in
                guard progress.isUnlocked(level) else { return }
                openLevel(level)
            }

        case .game(let number):
            if let level = LevelProvider.level(number) {
                GameView(
                    level: level,
                    progress: progress,
                    settings: settings,
                    onClose: closeGame,
                    onOpenSettings: { presentedSheet = .settings },
                    onNextLevel: { advance(after: number) }
                )
                // GameView owns a StateObject seeded by this level. A new identity
                // prevents a completed board from surviving into the next route.
                .id(number)
            } else {
                ContentUnavailableView(
                    "Level unavailable",
                    systemImage: "drop.triangle",
                    description: Text("Choose another puzzle from the level collection.")
                )
            }
        }
    }

    private var continueLevel: Int {
        min(max(progress.highestUnlockedLevel, 1), LevelProvider.totalLevelCount)
    }

    private func openLevel(_ number: Int) {
        guard LevelProvider.level(number) != nil else { return }
        path.append(.game(level: number))
    }

    private func closeGame() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func advance(after level: Int) {
        guard path.last == .game(level: level) else { return }

        let nextLevel = level + 1
        if let next = LevelProvider.level(nextLevel), progress.isUnlocked(next.id) {
            path[path.index(before: path.endIndex)] = .game(level: next.id)
        } else {
            path = [.levels]
        }
    }
}
