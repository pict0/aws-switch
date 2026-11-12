import AWSSwitchCore
import SwiftUI

/// The menu bar item: the AWS pill, with the Databricks pill beside it when a Databricks profile is set.
struct MenuBarLabel: View {
    let aws: String?
    let awsTier: EnvironmentTier?
    let databricks: String?
    let style: MenuBarStyle

    var body: some View {
        // The badges are bitmaps, so VoiceOver needs the profiles spelled out.
        HStack(spacing: 2) {
            Image(nsImage: awsBadge)
            if let databricks {
                Image(nsImage: databricksBadge(databricks))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var awsBadge: NSImage {
        switch style {
        case .badge: TierImages.badge(profile: aws, tier: awsTier)
        case .compact: TierImages.compactBadge(tier: awsTier)
        }
    }

    private func databricksBadge(_ profile: String) -> NSImage {
        let tier = EnvironmentTier.classify(profile)
        return switch style {
        case .badge: TierImages.databricksBadge(profile: profile, tier: tier)
        case .compact: TierImages.compactBadge(tier: tier)
        }
    }

    private var accessibilityLabel: String {
        let awsText = aws.map { "AWS profile \($0)" } ?? "No AWS profile"
        return databricks.map { "\(awsText), Databricks profile \($0)" } ?? awsText
    }
}
