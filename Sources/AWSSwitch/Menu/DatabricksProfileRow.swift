import AWSSwitchCore
import SwiftUI

/// One Databricks profile in the menu, with its workspace host beneath.
struct DatabricksProfileRow: View {
    @Bindable var model: AppModel
    let profile: DatabricksProfile

    var body: some View {
        Toggle(isOn: $model[isSelected: profile]) {
            Label {
                Text(profile.name)
                if let host = profile.host { Text(host) }
            } icon: {
                Image(nsImage: TierImages.marker(EnvironmentTier.classify(profile.name)))
            }
        }
    }
}
