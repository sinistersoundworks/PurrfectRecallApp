import SwiftUI

#if os(macOS)

public enum MacLayout {
    public static let pageMaxWidth: CGFloat = 980
    public static let pagePadding: CGFloat = 28
    public static let sectionSpacing: CGFloat = 28
    public static let cardCornerRadius: CGFloat = 10
    public static let studyCardMaxWidth: CGFloat = 620
}

public struct MacPageContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MacLayout.sectionSpacing) {
                content()
            }
            .frame(maxWidth: MacLayout.pageMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, MacLayout.pagePadding)
            .padding(.vertical, 24)
        }
        .background(BCColor.bgBase)
    }
}

public struct MacSectionHeader: View {
    let title: String
    var subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(BCColor.fg1)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(BCColor.fg2)
            }
        }
    }
}

public struct MacStatTile: View {
    let title: String
    let value: String
    var tint: Color = BCColor.fg1

    public init(_ title: String, value: String, tint: Color = BCColor.fg1) {
        self.title = title
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BCColor.fg2)
            Text(value)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(BCColor.bgRaised, in: RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous)
                .stroke(BCColor.borderDefault, lineWidth: 1)
        }
    }
}

public struct MacPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    public init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(BCColor.fg1)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(BCColor.bgRaised, in: RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous)
                .stroke(BCColor.borderDefault, lineWidth: 1)
        }
    }
}

public enum MacCopy {
    public static func deckSummary(due: Int, deckCount: Int) -> String {
        let deckWord = deckCount == 1 ? "deck" : "decks"
        return "\(due) cards due across \(deckCount) \(deckWord)"
    }
}

#endif
