import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    enum Feedback {
        case selection
        case pour
        case invalid
        case success
    }

    private let selection = UISelectionFeedbackGenerator()
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        selection.prepare()
        lightImpact.prepare()
    }

    func play(_ feedback: Feedback, enabled: Bool) {
        guard enabled else { return }
        switch feedback {
        case .selection:
            selection.selectionChanged()
            selection.prepare()
        case .pour:
            lightImpact.impactOccurred(intensity: 0.72)
            lightImpact.prepare()
        case .invalid:
            notification.notificationOccurred(.warning)
        case .success:
            notification.notificationOccurred(.success)
        }
    }
}
