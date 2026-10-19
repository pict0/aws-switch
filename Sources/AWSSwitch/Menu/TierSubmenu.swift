import AWSSwitchCore
import SwiftUI

/// All profiles in one environment tier, as a submenu marked with the tier's symbol.
struct TierSubmenu: View {
    @Bindable var model: AppModel
    let tier: EnvironmentTier
    let profiles: [AWSProfile]

    var body: some View {
        Menu {
            ForEach(profiles) { profile in
                ProfileRow(model: model, profile: profile, tier: tier)
            }
        } label: {
            Label {
                Text(tier.title)
                Text("^[\(profiles.count) profile](inflect: true)")
            } icon: {
                Image(nsImage: TierImages.marker(tier))
            }
        }
    }
}
