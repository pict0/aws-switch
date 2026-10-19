import AWSSwitchCore
import SwiftUI

struct MenuContent: View {
    @Bindable var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        if let error = model.lastError {
            Label(error, systemImage: "exclamationmark.octagon")
            Divider()
        }

        MenuSectionHeader(title: "AWS", systemImage: "cloud")
        // Recent profiles are one click away; the full list lives in a submenu per tier.
        ForEach(model.recentProfiles) { profile in
            ProfileRow(model: model, profile: profile, tier: EnvironmentTier.classify(profile.name))
        }
        ForEach(model.profilesByTier, id: \.tier) { group in
            TierSubmenu(model: model, tier: group.tier, profiles: group.profiles)
        }

        if !model.kube.contexts.isEmpty {
            Divider()
            MenuSectionHeader(title: "Kubernetes", systemImage: "helm")
            ForEach(model.kube.contexts) { context in
                KubeContextRow(model: model, context: context)
            }
        }

        Divider()
        // Always present, disabled when there's nothing to sign in to (HIG: disable, don't hide).
        Button(signInTitle, systemImage: "person.badge.key", action: signIn)
            .disabled(currentProfile == nil)
        Button("Show Switch Log", systemImage: "list.bullet.rectangle", action: model.openSwitchLog)

        Divider()
        Button("About AWS Switch", action: model.showAbout)
        Button("Settings…", action: showSettings)
            .keyboardShortcut(",")
        Button("Quit AWS Switch") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var currentProfile: AWSProfile? {
        model.profiles.first { $0.name == model.current }
    }

    private var signInTitle: String {
        currentProfile.map { "Sign In to \($0.name)…" } ?? "Sign In…"
    }

    private func signIn() {
        if let currentProfile { model.login(currentProfile) }
    }

    private func showSettings() {
        // A menu bar-only app isn't active, so the window would otherwise open behind others.
        NSApp.activate()
        openSettings()
    }
}
