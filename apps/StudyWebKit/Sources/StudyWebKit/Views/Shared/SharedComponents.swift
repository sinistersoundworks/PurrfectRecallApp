import SwiftUI

public struct StatCardView: View {
    let label: String
    let value: String
    var valueColor: Color = BCColor.fg1

    public init(label: String, value: String, valueColor: Color = BCColor.fg1) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }

    public var body: some View {
        BCCard {
            BCCapsLabel(label)
                .padding(.bottom, BCSpacing.s2)
            Text(value)
                .font(BCFont.mono(BCFont.text3XL, weight: .medium))
                .foregroundStyle(valueColor)
        }
    }
}

public struct DeckCardView: View {
    let name: String
    let description: String?
    let due: Int
    let mastered: Int
    let total: Int
    let color: Color
    let onTap: () -> Void

    public init(
        name: String,
        description: String?,
        due: Int,
        mastered: Int,
        total: Int,
        color: Color,
        onTap: @escaping () -> Void
    ) {
        self.name = name
        self.description = description
        self.due = due
        self.mastered = mastered
        self.total = total
        self.color = color
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BCSpacing.s2) {
                HStack(spacing: BCSpacing.s2) {
                    RoundedRectangle(cornerRadius: BCRadius.xs)
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(BCFont.ui(BCFont.textMD, weight: .semibold))
                        .foregroundStyle(BCColor.fg1)
                    Spacer()
                    if due > 0 {
                        Text("\(due) due")
                            .font(BCFont.mono(BCFont.text2XS))
                            .foregroundStyle(BCColor.accent)
                            .padding(.horizontal, BCSpacing.s2)
                            .padding(.vertical, 2)
                            .background(BCColor.accentDim)
                            .clipShape(Capsule())
                    }
                }
                if let description, !description.isEmpty {
                    Text(description)
                        .font(BCFont.ui(BCFont.textSM))
                        .foregroundStyle(BCColor.fg3)
                        .lineLimit(2)
                }
                BCProgressBar(
                    progress: total > 0 ? Double(mastered) / Double(total) : 0,
                    color: color,
                    label: "\(mastered)/\(total)"
                )
            }
            .padding(BCSpacing.s3)
            .background(BCColor.bgRaised)
            .clipShape(RoundedRectangle(cornerRadius: BCRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.md)
                    .stroke(BCColor.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

public struct ReviewsChartView: View {
    let days: [ReviewDayCountDTO]
    let maxCount: Int

    public init(days: [ReviewDayCountDTO], maxCount: Int) {
        self.days = days
        self.maxCount = maxCount
    }

    public var body: some View {
        BCCard(padding: BCSpacing.s4) {
            BCCapsLabel("Reviews — Last 7 Days")
                .padding(.bottom, BCSpacing.s4)
            HStack(alignment: .bottom, spacing: BCSpacing.s2) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: BCSpacing.s1) {
                        Text("\(day.count)")
                            .font(BCFont.mono(BCFont.text2XS))
                            .foregroundStyle(BCColor.fg2)
                        RoundedRectangle(cornerRadius: BCRadius.xs)
                            .fill(BCColor.accent)
                            .frame(height: barHeight(for: day.count))
                        Text(dayLabel(day.date))
                            .font(BCFont.mono(BCFont.text2XS))
                            .foregroundStyle(BCColor.fg3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
    }

    private func barHeight(for count: Int) -> CGFloat {
        let ratio = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
        return max(4, ratio * 80)
    }

    private func dayLabel(_ iso: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: iso) else { return iso.suffix(2).description }
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

public struct DeckRetentionRow: View {
    let name: String
    let retention: Double
    let color: Color

    public init(name: String, retention: Double, color: Color) {
        self.name = name
        self.retention = retention
        self.color = color
    }

    public var body: some View {
        HStack(spacing: BCSpacing.s2) {
            RoundedRectangle(cornerRadius: BCRadius.xs)
                .fill(color)
                .frame(width: 7, height: 7)
            Text(name)
                .font(BCFont.ui(BCFont.textSM, weight: .medium))
                .foregroundStyle(BCColor.fg1)
            BCProgressBar(progress: retention / 100, color: color, label: String(format: "%.0f%%", retention))
        }
    }
}

public struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        @Bindable var appState = appState
        VStack(alignment: .leading, spacing: BCSpacing.s4) {
            Text("Settings")
                .font(BCFont.ui(BCFont.textXL, weight: .semibold))
                .foregroundStyle(BCColor.fg1)
            BCCapsLabel("API Base URL")
            BCInput("http://127.0.0.1:8000", text: $appState.apiBaseURL)
            Text("Use your Mac's LAN IP when testing on a physical iPhone.")
                .font(BCFont.ui(BCFont.textSM))
                .foregroundStyle(BCColor.fg3)
            HStack {
                BCButton("Save", variant: .primary) {
                    appState.saveAPIBaseURL()
                    dismiss()
                }
                BCButton("Cancel", variant: .secondary) { dismiss() }
            }
            Spacer()
        }
        .padding(BCSpacing.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(BCColor.bgBase)
    }
}
