import SwiftUI

public enum BCButtonVariant {
    case primary
    case secondary
}

public enum BCButtonSize {
    case sm
    case lg

    var height: CGFloat {
        switch self {
        case .sm: 26
        case .lg: 40
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .sm: BCFont.textSM
        case .lg: BCFont.textMD
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .sm: BCSpacing.s3
        case .lg: BCSpacing.s4
        }
    }
}

public struct BCButton: View {
    let title: String
    var variant: BCButtonVariant = .primary
    var size: BCButtonSize = .lg
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    public init(
        _ title: String,
        variant: BCButtonVariant = .primary,
        size: BCButtonSize = .lg,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(BCFont.ui(size.fontSize, weight: .medium))
                .foregroundStyle(foreground)
                .padding(.horizontal, size.horizontalPadding)
                .frame(height: size.height)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: BCRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: BCRadius.sm)
                        .stroke(border, lineWidth: variant == .secondary ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.4 : 1)
        .disabled(isDisabled)
        .animation(.easeOut(duration: BCTransition.fast), value: isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary: BCColor.fgOnAccent
        case .secondary: BCColor.fg1
        }
    }

    private var background: Color {
        switch variant {
        case .primary: BCColor.accent
        case .secondary: BCColor.bgControl
        }
    }

    private var border: Color {
        variant == .secondary ? BCColor.borderDefault : .clear
    }
}

public struct BCCard<Content: View>: View {
    var padding: CGFloat = BCSpacing.s3
    @ViewBuilder let content: () -> Content

    public init(padding: CGFloat = BCSpacing.s3, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        content()
            .padding(padding)
            .background(BCColor.bgRaised)
            .clipShape(RoundedRectangle(cornerRadius: BCRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.md)
                    .stroke(BCColor.borderDefault, lineWidth: 1)
            )
    }
}

public struct BCInput: View {
    let placeholder: String
    @Binding var text: String

    public init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(BCFont.ui(BCFont.textMD))
            .foregroundStyle(BCColor.fg1)
            .padding(.horizontal, BCSpacing.s2)
            .frame(height: 30)
            .background(BCColor.bgControl)
            .clipShape(RoundedRectangle(cornerRadius: BCRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.sm)
                    .stroke(BCColor.borderDefault, lineWidth: 1)
            )
    }
}

public struct BCSelect: View {
    let options: [(id: Int, name: String)]
    @Binding var selection: Int?

    public init(options: [(id: Int, name: String)], selection: Binding<Int?>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        Picker("", selection: $selection) {
            Text("Select deck").tag(Optional<Int>.none)
            ForEach(options, id: \.id) { option in
                Text(option.name).tag(Optional(option.id))
            }
        }
        .labelsHidden()
        .font(BCFont.ui(BCFont.textSM))
        .foregroundStyle(BCColor.fg1)
        .padding(.horizontal, BCSpacing.s2)
        .frame(height: 26)
        .background(BCColor.bgControl)
        .clipShape(RoundedRectangle(cornerRadius: BCRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: BCRadius.sm)
                .stroke(BCColor.borderDefault, lineWidth: 1)
        )
    }
}

public struct BCSlider: View {
    @Binding var value: Double

    public init(value: Binding<Double>) {
        self._value = value
    }

    public var body: some View {
        Slider(value: $value, in: 0...100, step: 1)
            .tint(BCColor.accent)
    }
}

public struct BCMeter: View {
    let value: Double

    public init(value: Double) {
        self.value = value
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: BCRadius.xs)
                    .fill(BCColor.bgControl)
                RoundedRectangle(cornerRadius: BCRadius.xs)
                    .fill(BCColor.colorInfo)
                    .frame(width: geo.size.width * min(max(value / 100, 0), 1))
            }
        }
        .frame(height: 8)
    }
}

public enum CardStatusKind: String {
    case due = "DUE"
    case learning = "LEARNING"
    case mastered = "MASTERED"
}

public struct BCStatusPill: View {
    let status: CardStatusKind

    public init(_ status: CardStatusKind) {
        self.status = status
    }

    public var body: some View {
        Text(status.rawValue)
            .font(BCFont.mono(BCFont.text2XS, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, BCSpacing.s2)
            .padding(.vertical, BCSpacing.s1)
            .background(background)
            .clipShape(Capsule())
    }

    private var foreground: Color {
        switch status {
        case .due: BCColor.accent
        case .learning: BCColor.colorWarn
        case .mastered: BCColor.colorActive
        }
    }

    private var background: Color {
        switch status {
        case .due: BCColor.accentDim
        case .learning: BCColor.colorWarnDim
        case .mastered: BCColor.colorActiveDim
        }
    }
}

public struct BCProgressBar: View {
    let progress: Double
    let color: Color
    let label: String

    public init(progress: Double, color: Color, label: String) {
        self.progress = progress
        self.color = color
        self.label = label
    }

    public var body: some View {
        HStack(spacing: BCSpacing.s2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BCColor.bgControl)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 4)
            Text(label)
                .font(BCFont.mono(BCFont.text2XS))
                .foregroundStyle(BCColor.fg3)
        }
    }
}
