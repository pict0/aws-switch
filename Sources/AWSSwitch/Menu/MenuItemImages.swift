import AppKit

/// macOS 27 hides menu item images unless an item opts in with `preferredImageVisibility = .visible`
/// (the default, `.automatic`, lets AppKit decide from system configuration, and here it hides them).
/// SwiftUI builds the menu bar menu itself and exposes no setting for this, so mark every item as it is added.
final class MenuItemImages: NSObject, @unchecked Sendable {
    /// `NSMenuItem.ImageVisibility.visible`. shortcut: set by key with an empirically found raw value (1 visible, 2 hidden, checked on macOS 27.2), because the API is newer than our 26.2 SDK; use the typed property once the SDK has it.
    private static let visible = 1
    private static let observer = MenuItemImages()

    static func install() {
        NotificationCenter.default.addObserver(
            observer, selector: #selector(itemAdded), name: NSMenu.didAddItemNotification, object: nil)
    }

    @objc private func itemAdded(_ note: Notification) {
        guard let menu = note.object as? NSMenu,
              let index = note.userInfo?["NSMenuItemIndex"] as? Int,
              menu.items.indices.contains(index) else { return }
        let item = menu.items[index]
        // No-op before macOS 27, where the property doesn't exist.
        guard item.responds(to: NSSelectorFromString("setPreferredImageVisibility:")) else { return }
        item.setValue(Self.visible, forKey: "preferredImageVisibility")
    }
}
