import SwiftUI

public enum BCFont {
    public static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    public static let text2XS: CGFloat = 9
    public static let textXS: CGFloat = 10
    public static let textSM: CGFloat = 11
    public static let textBase: CGFloat = 12
    public static let textMD: CGFloat = 13
    public static let textLG: CGFloat = 15
    public static let textXL: CGFloat = 18
    public static let text2XL: CGFloat = 22
    public static let text3XL: CGFloat = 28
    public static let text4XL: CGFloat = 38
}

public struct BCCapsLabel: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .font(BCFont.ui(BCFont.textXS, weight: .medium))
            .tracking(0.08 * BCFont.textXS)
            .foregroundStyle(BCColor.fg3)
    }
}
