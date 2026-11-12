import AWSSwitchCore
import SwiftUI

@main
struct AWSSwitchApp: App {
    @State private var model = AppModel()

    init() {
        MenuItemImages.install()
        #if DEBUG
        DebugMenu.openIfRequested()
        DebugMenu.dumpLabelIfRequested()
        #endif
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            MenuBarLabel(
                aws: model.current, awsTier: model.currentTier,
                databricks: model.databricksCurrent, style: model.menuBarStyle)
        }

        Settings {
            SettingsView(model: model)
        }
    }
}
