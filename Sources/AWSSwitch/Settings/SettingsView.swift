import SwiftUI

/// App-level preferences, opened from Settings… (⌘,) in the menu.
struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $model.launchAtLogin)
            }

            Section {
                Picker("Show", selection: $model.menuBarStyle) {
                    ForEach(MenuBarStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Menu Bar")
            } footer: {
                Text("Icon only takes less room, so macOS is less likely to hide it when the menu bar is crowded. The symbol still shows the environment tier, and production stays red.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Switch kubectl context with AWS profile", isOn: $model.syncKube)
            } header: {
                Text("Kubernetes")
            } footer: {
                Text("Selects the EKS context in the same AWS account, when there's exactly one.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}
