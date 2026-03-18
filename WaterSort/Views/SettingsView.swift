import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings: SettingsStore
    private let progress: ProgressManager

    @State private var isShowingResetConfirmation = false

    init(settings: SettingsStore, progress: ProgressManager) {
        self.settings = settings
        self.progress = progress
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView(intensity: 0.58, showsParticles: false)

                Form {
                    soundSection
                    feelSection
                    progressSection
                    aboutSection
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(ChromaticTheme.aqua)
                }
            }
            .alert("Reset all progress?", isPresented: $isShowingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Progress", role: .destructive) {
                    progress.resetProgress()
                }
            } message: {
                Text(resetMessage)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .preferredColorScheme(.dark)
    }

    private var soundSection: some View {
        Section {
            Toggle(isOn: $settings.soundEffectsEnabled) {
                SettingsRowLabel(
                    title: "Sound Effects",
                    detail: "Pour and completion sounds",
                    systemImage: "speaker.wave.2.fill",
                    tint: ChromaticTheme.azure
                )
            }
            .tint(ChromaticTheme.aqua)
            .chromaticSettingsRow()

        } header: {
            SettingsSectionHeader(title: "Sound", systemImage: "waveform")
        } footer: {
            Text("Audio preferences are saved automatically on this device.")
                .foregroundStyle(ChromaticTheme.tertiaryText)
        }
    }

    private var feelSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                SettingsRowLabel(
                    title: "Haptics",
                    detail: "Gentle feedback for key actions",
                    systemImage: "iphone.radiowaves.left.and.right",
                    tint: ChromaticTheme.coral
                )
            }
            .tint(ChromaticTheme.aqua)
            .chromaticSettingsRow()
        } header: {
            SettingsSectionHeader(title: "Feel", systemImage: "hand.tap.fill")
        } footer: {
            Text("System accessibility settings always take priority.")
                .foregroundStyle(ChromaticTheme.tertiaryText)
        }
    }

    private var progressSection: some View {
        Section {
            HStack {
                SettingsRowLabel(
                    title: "Completed Levels",
                    detail: "Your current collection",
                    systemImage: "checkmark.seal.fill",
                    tint: ChromaticTheme.aqua
                )

                Spacer(minLength: 12)

                Text("\(completedCount) / \(totalLevels)")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(ChromaticTheme.aqua)
            }
            .chromaticSettingsRow()

            Button(role: .destructive) {
                isShowingResetConfirmation = true
            } label: {
                Label("Reset Progress", systemImage: "arrow.counterclockwise")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(Color(red: 1, green: 0.61, blue: 0.68))
            .buttonStyle(.plain)
            .chromaticSettingsRow()
            .accessibilityHint("Removes completion records and best move counts")
        } header: {
            SettingsSectionHeader(title: "Progress", systemImage: "chart.line.uptrend.xyaxis")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutWaterSortView()
            } label: {
                SettingsRowLabel(
                    title: "About Water Sort",
                    detail: "Version \(appVersion)",
                    systemImage: "info.circle.fill",
                    tint: ChromaticTheme.sunshine
                )
            }
            .chromaticSettingsRow()
        } header: {
            SettingsSectionHeader(title: "About", systemImage: "drop.fill")
        }
    }

    private var completedCount: Int {
        min(max(progress.completedCount, 0), totalLevels)
    }

    private var totalLevels: Int {
        LevelProvider.totalLevelCount
    }

    private var resetMessage: String {
        if completedCount == 0 {
            return "This will clear any saved best move counts. Your settings will stay the same."
        }
        return "This will lock later levels and remove progress for \(completedCount) completed level\(completedCount == 1 ? "" : "s"). Your settings will stay the same."
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

private struct SettingsRowLabel: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(ChromaticTheme.primaryText)

                Text(detail)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(ChromaticTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.16))

                Image(systemName: systemImage)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 34, height: 34)
        }
        .labelStyle(.titleAndIcon)
    }
}

private struct SettingsSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title.uppercased(), systemImage: systemImage)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(ChromaticTheme.secondaryText)
    }
}

private struct AboutWaterSortView: View {
    var body: some View {
        ZStack {
            BackgroundView(intensity: 0.62)

            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(ChromaticTheme.actionGradient)
                            .shadow(color: ChromaticTheme.violet.opacity(0.38), radius: 24, y: 12)

                        Image(systemName: "drop.fill")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 104, height: 104)
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("Water Sort")
                            .font(.chromaticHero)
                            .foregroundStyle(ChromaticTheme.primaryText)

                        Text("A small space for colorful thinking.")
                            .font(.chromaticBody)
                            .foregroundStyle(ChromaticTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        AboutFeature(
                            systemImage: "puzzlepiece.fill",
                            title: "\(LevelProvider.totalLevelCount) handcrafted puzzles",
                            detail: "Every board is designed to be solvable and grows gently in complexity.",
                            tint: ChromaticTheme.aqua
                        )
                        AboutFeature(
                            systemImage: "leaf.fill",
                            title: "Made for calm focus",
                            detail: "No timers, pressure, accounts, or network connection required.",
                            tint: ChromaticTheme.azure
                        )
                        AboutFeature(
                            systemImage: "heart.fill",
                            title: "Thoughtfully native",
                            detail: "Built with SwiftUI, Dynamic Type, and reduced-motion support.",
                            tint: ChromaticTheme.coral
                        )
                    }
                    .padding(20)
                    .chromaticGlass(cornerRadius: 24)

                    Text("Find your flow, one pour at a time.")
                        .font(.chromaticCaption)
                        .foregroundStyle(ChromaticTheme.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AboutFeature: View {
    let systemImage: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.chromaticHeadline)
                    .foregroundStyle(ChromaticTheme.primaryText)
                Text(detail)
                    .font(.chromaticBody)
                    .foregroundStyle(ChromaticTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func chromaticSettingsRow() -> some View {
        listRowBackground(Color.white.opacity(0.075))
            .listRowSeparatorTint(Color.white.opacity(0.09))
    }
}
