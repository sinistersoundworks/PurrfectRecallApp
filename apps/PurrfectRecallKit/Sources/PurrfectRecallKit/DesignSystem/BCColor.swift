import SwiftUI

public enum BCColor {
    public static let bgBase = Color(hex: 0x090909)
    public static let bgRaised = Color(hex: 0x111111)
    public static let bgElevated = Color(hex: 0x181818)
    public static let bgControl = Color(hex: 0x1C1C1C)
    public static let bgControlHover = Color(hex: 0x222222)
    public static let bgControlActive = Color(hex: 0x282828)
    public static let bgControlPressed = Color(hex: 0x0D0D0D)

    public static let borderSubtle = Color.white.opacity(0.05)
    public static let borderDefault = Color.white.opacity(0.09)
    public static let borderStrong = Color.white.opacity(0.16)
    public static let borderFocus = Color(hex: 0xF08C0A)

    public static let fg1 = Color(hex: 0xF2F2F2)
    public static let fg2 = Color(hex: 0xA4A4A4)
    public static let fg3 = Color(hex: 0x5C5C5C)
    public static let fg4 = Color(hex: 0x343434)
    public static let fgOnAccent = Color(hex: 0x0A0A0A)

    public static let accent = Color(hex: 0xF08C0A)
    public static let accentHover = Color(hex: 0xF5A128)
    public static let accentPressed = Color(hex: 0xCC7808)
    public static let accentDim = Color(hex: 0xF08C0A, alpha: 0.14)

    public static let colorActive = Color(hex: 0x34D058)
    public static let colorActiveDim = Color(hex: 0x34D058, alpha: 0.14)
    public static let colorDanger = Color(hex: 0xF05050)
    public static let colorDangerDim = Color(hex: 0xF05050, alpha: 0.14)
    public static let colorWarn = Color(hex: 0xF0B030)
    public static let colorWarnDim = Color(hex: 0xF0B030, alpha: 0.14)
    public static let colorInfo = Color(hex: 0x38C4F0)
    public static let colorInfoDim = Color(hex: 0x38C4F0, alpha: 0.14)
}

public extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
