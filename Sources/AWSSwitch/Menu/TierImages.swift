import AppKit
import AWSSwitchCore
import SwiftUI

/// Menu bar labels and menu item images. Other tiers use template or dynamic-colour
/// images so they match the system's own icons in light and dark mode; production alone is
/// drawn in red, which needs a non-template bitmap because macOS tints templates monochrome.
@MainActor
enum TierImages {
    static func badge(profile: String?, tier: EnvironmentTier?) -> NSImage {
        let tier = tier ?? .shared
        let content = HStack(spacing: 4) {
            Image(systemName: profile == nil ? "cloud" : tier.symbol)
                .font(.system(size: 11, weight: tier.isProduction ? .bold : .medium))
            Text(profile ?? "No AWS profile")
                .font(.system(size: 12, weight: tier.isProduction ? .semibold : .medium))
        }
        guard tier.isProduction else {
            return render(content.foregroundStyle(.black).padding(.horizontal, 2).frame(height: 18), template: true)
        }
        return render(content.foregroundStyle(.white).padding(.horizontal, 7).frame(height: 18).background(prodPill))
    }

    /// Narrow alternative to `badge`: just the tier symbol.
    static func compactBadge(tier: EnvironmentTier?) -> NSImage {
        let tier = tier ?? .shared
        let symbol = Image(systemName: tier.symbol).font(.system(size: 12, weight: .bold))
        guard tier.isProduction else {
            return render(symbol.foregroundStyle(.black).frame(width: 18, height: 18), template: true)
        }
        return render(symbol.foregroundStyle(.white).frame(width: 22, height: 18).background(prodPill))
    }

    /// Row markers, built once per tier: every menu row uses one, on every update.
    private static let markers = Dictionary(uniqueKeysWithValues: EnvironmentTier.allCases.map { ($0, makeMarker($0)) })

    static func marker(_ tier: EnvironmentTier) -> NSImage {
        markers[tier] ?? makeMarker(tier)
    }

    /// A symbol image with a dynamic system colour, resolved when drawn, so it follows the
    /// menu's appearance: grey for most tiers, system red for production.
    private static func makeMarker(_ tier: EnvironmentTier) -> NSImage {
        let colour: NSColor = tier.isProduction ? .systemRed : .secondaryLabelColor
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            .applying(.init(paletteColors: [colour]))
        let image = NSImage(systemSymbolName: tier.symbol, accessibilityDescription: tier.title)?
            .withSymbolConfiguration(config)
        return image ?? NSImage()
    }

    private static var prodPill: some View {
        RoundedRectangle(cornerRadius: 5).fill(Color(nsColor: .systemRed))
    }

    private static func render(_ view: some View, template: Bool = false) -> NSImage {
        let renderer = ImageRenderer(content: view)
        // Fixed 3x rather than NSScreen.main's scale: with mixed-resolution displays the main
        // screen isn't necessarily the one showing the menu bar. AppKit downsamples cleanly.
        renderer.scale = 3
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = template
        return image
    }
}
