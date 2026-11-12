#if DEBUG
import AppKit
import AWSSwitchCore
import SwiftUI

/// Debug builds only: AWSSWITCH_DEBUG_OPEN_MENU=1 opens the status item's menu at launch, so it can be
/// screenshotted without clicking a menu bar that may be crowded or inaccessible to automation.
enum DebugMenu {
    @MainActor static func openIfRequested() {
        guard ProcessInfo.processInfo.environment["AWSSWITCH_DEBUG_OPEN_MENU"] == "1" else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            let button = NSApp.windows.lazy.compactMap { $0.contentView.flatMap(statusButton) }.first
            // SwiftUI keeps the MenuBarExtra menu on the (private) status item. Pop it up at a fixed
            // point: the item itself may sit under the notch or in overflow, where it can't be seen.
            let item = button?.window?.value(forKey: "statusItem") as? NSStatusItem
            item?.menu?.popUp(positioning: nil, at: NSPoint(x: 200, y: 700), in: nil)
        }
    }

    /// AWSSWITCH_DEBUG_DUMP_LABEL=<file.png> renders sample menu bar labels to a PNG and exits. The status item
    /// is drawn by the system, outside our windows, so it can't be screenshotted by window.
    @MainActor static func dumpLabelIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["AWSSWITCH_DEBUG_DUMP_LABEL"] else { return }
        let samples: [(String?, String?)] = [
            ("uktote-group-ltd", "development"), ("uktote-group-ltd", "production"),
            ("b2c-production", "production"), ("uktote-group-ltd", nil), (nil, nil),
        ]
        let rows = VStack(alignment: .leading, spacing: 8) {
            ForEach(MenuBarStyle.allCases) { style in
                ForEach(samples.indices, id: \.self) { i in
                    MenuBarLabel(
                        aws: samples[i].0, awsTier: samples[i].0.map(EnvironmentTier.classify),
                        databricks: samples[i].1, style: style)
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.85))
        let renderer = ImageRenderer(content: rows)
        renderer.scale = 3
        if let tiff = renderer.nsImage?.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: path))
        }
        exit(0)
    }

    private static func statusButton(in view: NSView) -> NSStatusBarButton? {
        if let button = view as? NSStatusBarButton { return button }
        return view.subviews.lazy.compactMap(statusButton).first
    }
}
#endif
