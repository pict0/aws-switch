import SwiftUI

/// A section header with a generic SF Symbol and title. Brand logos are deliberately avoided:
/// AWS doesn't licence its logo for third-party tools. It's an enabled no-op button rather than
/// a disabled item because macOS dims the images of disabled menu items.
struct MenuSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Button {} label: {
            Label(title, systemImage: systemImage)
        }
        .accessibilityAddTraits(.isHeader)
    }
}
