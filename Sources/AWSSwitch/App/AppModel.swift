import AppKit
import AWSSwitchCore
import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class AppModel {
    private(set) var profiles: [AWSProfile] = []
    private(set) var current: String?
    private(set) var expiries: [String: Date] = [:]
    private(set) var lastError: String?
    private(set) var kube = KubeConfigSnapshot.empty

    /// Mirrors `SMAppService.mainApp.status`, which isn't observable itself.
    private var launchAtLoginState = SMAppService.mainApp.status == .enabled
    private var syncKubeState = UserDefaults.standard.object(forKey: "syncKube") as? Bool ?? true
    private var menuBarStyleState = UserDefaults.standard.string(forKey: "menuBarStyle")
        .flatMap(MenuBarStyle.init(rawValue:)) ?? .badge
    /// Most recently used profile names, newest first.
    private(set) var recentNames = UserDefaults.standard.stringArray(forKey: "recentProfiles") ?? []
    private static let recentLimit = 4

    private let store = ContextStore()
    private let log = SwitchLog()
    private var kubeConfigModified: Date?
    private var kubeReloading = false
    private var hasLoaded = false

    init() {
        refresh()
        // Poll rather than watch: the file is replaced atomically (by us and by the CLI),
        // which invalidates file descriptors that a DispatchSource watcher would hold.
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    var currentTier: EnvironmentTier? { current.map(EnvironmentTier.classify) }

    /// Order of the tier submenus in the menu.
    private static let tierMenuOrder: [EnvironmentTier] = [.production, .shared, .preProduction]

    /// Profiles grouped by tier, in `tierMenuOrder`; empty tiers omitted.
    var profilesByTier: [(tier: EnvironmentTier, profiles: [AWSProfile])] {
        let grouped = Dictionary(grouping: profiles) { EnvironmentTier.classify($0.name) }
        return Self.tierMenuOrder.compactMap { tier in
            grouped[tier].map { (tier, $0) }
        }
    }

    /// Re-reads config, context and SSO expiry. Only assigns changed values: Observation
    /// notifies on every write, and an unchanged write would re-render the menu every poll.
    func refresh() {
        if let text = SafeFile.readString(AWSPaths.configFile) {
            update(\.profiles, to: AWSConfigParser.parse(text))
        }
        let previous = current
        update(\.current, to: store.read())
        update(\.expiries, to: SSOSessionStatus.expiries())

        // A change made outside the app (the awsswitch CLI) still drives kubectl.
        if hasLoaded, current != previous, let current { followProfileInKube(current) }
        if let current, recentNames.first != current { noteRecent(current) }
        hasLoaded = true

        let modified = Kubectl.configModified
        if modified != kubeConfigModified {
            kubeConfigModified = modified
            Task { await reloadKube() }
        }
    }

    private func update<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<AppModel, Value>, to value: Value) {
        if self[keyPath: keyPath] != value { self[keyPath: keyPath] = value }
    }

    func expiry(for profile: AWSProfile) -> Date? {
        SSOSessionStatus.expiry(for: profile, in: expiries)
    }

    func select(_ profile: AWSProfile) {
        guard profile.name != current else { return }
        if EnvironmentTier.classify(profile.name).requiresConfirmation, !confirmProd(profile) { return }
        do {
            try store.write(profile.name)
            log.record(from: current, to: profile.name)
            current = profile.name
            noteRecent(profile.name)
            lastError = nil
            followProfileInKube(profile.name)
        } catch {
            lastError = "Couldn't switch: \(error.localizedDescription)"
        }
    }

    /// Hands login to the AWS CLI, which opens the browser. The app never sees credentials.
    func login(_ profile: AWSProfile) {
        guard let aws = AWSCLI.path else {
            lastError = "aws CLI not found"
            return
        }
        Task {
            do {
                let result = try await ProcessRunner.run(aws, ["sso", "login", "--profile", profile.name])
                lastError = result.status == 0 ? nil : "Sign-in to \(profile.name) failed (exit \(result.status))"
            } catch {
                lastError = "Couldn't start sign-in: \(error.localizedDescription)"
            }
            refresh()
        }
    }

    // MARK: Kubernetes

    var currentKubeContext: KubeContext? { kube.contexts.first { $0.name == kube.current } }

    /// Tier of a kube context: that of the AWS profile owning its EKS cluster, else from its name.
    func tier(of context: KubeContext) -> EnvironmentTier {
        EnvironmentTier.classify(linkedProfile(for: context)?.name ?? context.name)
    }

    func linkedProfile(for context: KubeContext) -> AWSProfile? {
        kube.profile(for: context, in: profiles)
    }

    func selectKube(_ context: KubeContext) {
        guard context.name != kube.current else { return }
        if tier(of: context).requiresConfirmation, !confirm(
            title: "Switch kubectl to production?",
            detail: "\(context.name)\n\(context.cluster)\n\nkubectl in every terminal will use this context immediately.",
            action: "Switch to \(context.name)")
        { return }
        Task { await switchKube(to: context.name) }
    }

    private func followProfileInKube(_ profileName: String) {
        guard syncKube,
              let profile = profiles.first(where: { $0.name == profileName }),
              let context = kube.context(for: profile),
              context.name != kube.current
        else { return }
        // No second confirmation: switching to the AWS profile was already the decision.
        Task { await switchKube(to: context.name) }
    }

    private func switchKube(to name: String) async {
        let previous = kube.current
        do {
            try await Kubectl.useContext(name)
            log.record(from: previous, to: name, kind: "kube")
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        await reloadKube()
    }

    private func reloadKube() async {
        guard Kubectl.path != nil, !kubeReloading else { return }
        kubeReloading = true
        defer { kubeReloading = false }
        do {
            update(\.kube, to: try await Kubectl.snapshot())
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Recently used profiles that still exist in the config, newest first.
    var recentProfiles: [AWSProfile] {
        recentNames.compactMap { name in profiles.first { $0.name == name } }
    }

    private func noteRecent(_ name: String) {
        recentNames = Array(([name] + recentNames.filter { $0 != name }).prefix(Self.recentLimit))
        UserDefaults.standard.set(recentNames, forKey: "recentProfiles")
    }

    // MARK: Bindable selection and settings

    /// Whether a profile is the current one. Setting true switches to it (with prod
    /// confirmation); setting false is ignored, since the menu is a single choice.
    subscript(isSelected profile: AWSProfile) -> Bool {
        get { current == profile.name }
        set { if newValue { select(profile) } }
    }

    subscript(isSelected context: KubeContext) -> Bool {
        get { kube.current == context.name }
        set { if newValue { selectKube(context) } }
    }

    /// Switch kubectl to the profile's EKS context whenever the AWS profile changes.
    var syncKube: Bool {
        get { syncKubeState }
        set {
            syncKubeState = newValue
            UserDefaults.standard.set(newValue, forKey: "syncKube")
        }
    }

    /// Reads back the real status after registering, since registration can fail or need approval.
    var launchAtLogin: Bool {
        get { launchAtLoginState }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                lastError = "Launch at login: \(error.localizedDescription)"
            }
            launchAtLoginState = SMAppService.mainApp.status == .enabled
        }
    }

    var menuBarStyle: MenuBarStyle {
        get { menuBarStyleState }
        set {
            menuBarStyleState = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "menuBarStyle")
        }
    }

    func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    func openSwitchLog() {
        NSWorkspace.shared.open(SwitchLog.url)
    }

    private func confirmProd(_ profile: AWSProfile) -> Bool {
        var detail = profile.name + (profile.accountId.map { " (\($0))" } ?? "")
        detail += "\n\nEvery terminal will follow this profile at its next prompt."
        if syncKube, let context = kube.context(for: profile) {
            detail += "\nkubectl will switch to \(context.name)."
        }
        return confirm(title: "Switch to production?", detail: detail, action: "Switch to \(profile.name)")
    }

    /// Modal confirmation with Cancel as the default (Return) button.
    private func confirm(title: String, detail: String, action: String) -> Bool {
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: action)
        return alert.runModal() == .alertSecondButtonReturn
    }
}
