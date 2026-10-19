import AWSSwitchCore
import SwiftUI

@main
struct AWSSwitchApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            // The badge is a bitmap, so VoiceOver needs the profile spelled out.
            Image(nsImage: badge)
                .accessibilityLabel(model.current.map { "AWS profile \($0)" } ?? "No AWS profile")
        }

        Settings {
            SettingsView(model: model)
        }
    }

    private var badge: NSImage {
        switch model.menuBarStyle {
        case .badge: TierImages.badge(profile: model.current, tier: model.currentTier)
        case .compact: TierImages.compactBadge(tier: model.currentTier)
        }
    }
}
