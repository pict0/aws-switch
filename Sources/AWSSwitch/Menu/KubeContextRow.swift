import AWSSwitchCore
import SwiftUI

/// One kubectl context in the menu, with the AWS profile that owns its EKS cluster beneath.
struct KubeContextRow: View {
    @Bindable var model: AppModel
    let context: KubeContext

    var body: some View {
        Toggle(isOn: $model[isSelected: context]) {
            Label {
                Text(context.name)
                Text(model.linkedProfile(for: context)?.name ?? "local")
            } icon: {
                Image(nsImage: TierImages.marker(model.tier(of: context)))
            }
        }
    }
}
