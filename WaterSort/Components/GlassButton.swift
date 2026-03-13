import SwiftUI

/// A large, tactile call-to-action that remains legible over the animated background.
struct GlassButton: View {
    enum Emphasis {
        case primary
        case secondary
        case quiet
        case destructive
    }

    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric(relativeTo: .body) private var minimumHeight: CGFloat = 56

    private let title: String
    private let systemImage: String?
    private let emphasis: Emphasis
    private let expandsHorizontally: Bool
    private let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        emphasis: Emphasis = .secondary,
        expandsHorizontally: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.emphasis = emphasis
        self.expandsHorizontally = expandsHorizontally
        self.action = action
    }

    init(
        title: String,
        systemImage: String? = nil,
        emphasis: Emphasis = .secondary,
        expandsHorizontally: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            systemImage: systemImage,
            emphasis: emphasis,
            expandsHorizontally: expandsHorizontally,
            action: action
        )
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .imageScale(.medium)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.chromaticHeadline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: expandsHorizontally ? .infinity : nil)
            .frame(minHeight: minimumHeight)
            .padding(.horizontal, 20)
            .foregroundStyle(foregroundStyle)
            .background { buttonBackground }
            .contentShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(ChromaticPressButtonStyle())
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(title)
    }

    private var foregroundStyle: Color {
        switch emphasis {
        case .destructive:
            return Color(red: 1, green: 0.66, blue: 0.72)
        default:
            return ChromaticTheme.primaryText
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 19, style: .continuous)

        switch emphasis {
        case .primary:
            shape
                .fill(ChromaticTheme.actionGradient)
                .overlay {
                    shape.strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: ChromaticTheme.violet.opacity(0.42), radius: 20, y: 10)

        case .secondary:
            shape
                .fill(.ultraThinMaterial)
                .overlay { shape.fill(Color.white.opacity(0.075)) }
                .overlay {
                    shape.strokeBorder(Color.white.opacity(0.19), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.18), radius: 14, y: 7)

        case .quiet:
            shape
                .fill(Color.white.opacity(0.055))
                .overlay {
                    shape.strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                }

        case .destructive:
            shape
                .fill(ChromaticTheme.coral.opacity(0.12))
                .overlay {
                    shape.strokeBorder(ChromaticTheme.coral.opacity(0.34), lineWidth: 1)
                }
        }
    }
}

/// Compact companion to `GlassButton` for navigation bars and floating controls.
struct GlassIconButton: View {
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 46

    let systemImage: String
    let accessibilityLabel: String
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
        }
        .buttonStyle(ChromaticPressButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct ChromaticPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? -0.035 : 0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72),
                value: configuration.isPressed
            )
    }
}
