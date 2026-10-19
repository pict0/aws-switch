import AWSSwitchCore
import SwiftUI

/// One AWS profile in the menu: tick when current, account ID and SSO session time beneath.
struct ProfileRow: View {
    @Bindable var model: AppModel
    let profile: AWSProfile
    let tier: EnvironmentTier

    var body: some View {
        Toggle(isOn: $model[isSelected: profile]) {
            Label {
                Text(profile.name)
                Text(subtitle)
            } icon: {
                Image(nsImage: TierImages.marker(tier))
            }
        }
    }

    private var subtitle: String {
        [profile.accountId, sessionText]
            .compactMap { $0 }
            .joined(separator: "  ·  ")
    }

    private var sessionText: String {
        guard let expiry = model.expiry(for: profile) else { return "Not signed in" }
        let remaining = expiry.timeIntervalSinceNow
        if remaining <= 0 { return "Session expired" }
        let left = Duration.seconds(remaining).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
        return "\(left) left"
    }
}
