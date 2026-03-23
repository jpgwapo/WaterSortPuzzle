import SwiftUI

@main
@MainActor
struct WaterSortApp: App {
    @State private var progress = ProgressManager()
    @State private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView(progress: progress, settings: settings)
        }
    }
}
