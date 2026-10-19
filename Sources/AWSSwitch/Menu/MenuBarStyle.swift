/// How the menu bar item presents the current profile.
enum MenuBarStyle: String, CaseIterable, Identifiable {
    /// Coloured pill with tier symbol and full profile name.
    case badge
    /// Coloured tier symbol only: narrow, so macOS is less likely to hide it when the bar is crowded.
    case compact

    var id: Self { self }

    var title: String {
        switch self {
        case .badge: "Profile name"
        case .compact: "Icon only"
        }
    }
}
