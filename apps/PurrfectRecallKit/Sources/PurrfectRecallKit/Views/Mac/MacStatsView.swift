import SwiftUI

#if os(macOS)

public struct MacStatsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = StatsViewModel()

    public init() {}

    public var body: some View {
        MacPageContainer {
            if let stats = viewModel.stats {
                summaryRow(stats)
                reviewsChart(stats)
                retentionPanel(stats)
            } else if viewModel.isLoading {
                ProgressView("Loading statistics…")
                    .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                ContentUnavailableView(
                    "No Statistics",
                    systemImage: "chart.bar",
                    description: Text("Complete a study session to see your progress.")
                )
                .frame(maxWidth: .infinity, minHeight: 240)
            }
        }
        .task { await viewModel.load(using: appState.api) }
    }

    private func summaryRow(_ stats: StatsDTO) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
            spacing: 16
        ) {
            MacStatTile("Longest Streak", value: "\(stats.streakDays)", tint: BCColor.accent)
            MacStatTile("Cards Learned", value: "\(stats.cardsLearned)")
            MacStatTile(
                "Retention",
                value: String(format: "%.0f%%", stats.retentionPct),
                tint: BCColor.colorActive
            )
            MacStatTile("Avg. Ease", value: String(format: "%.2f", stats.avgEase))
        }
    }

    private func reviewsChart(_ stats: StatsDTO) -> some View {
        MacPanel("Reviews — Last 7 Days") {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(stats.reviewsLast7Days, id: \.date) { day in
                    VStack(spacing: 8) {
                        Text("\(day.count)")
                            .font(.caption.monospacedDigit().weight(.medium))
                            .foregroundStyle(BCColor.fg2)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(day.count > 0 ? BCColor.accent : BCColor.bgControl)
                            .frame(height: barHeight(for: day.count))
                        Text(shortDayLabel(day.date))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(BCColor.fg3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
    }

    private func retentionPanel(_ stats: StatsDTO) -> some View {
        MacPanel("Deck Retention") {
            if stats.deckStats.isEmpty {
                Text("No decks yet.")
                    .font(.subheadline)
                    .foregroundStyle(BCColor.fg2)
            } else {
                VStack(spacing: 14) {
                    ForEach(stats.deckStats) { deck in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(DeckColor.color(for: deck.subjectId))
                                .frame(width: 10, height: 10)
                            Text(deck.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(BCColor.fg1)
                            ProgressView(value: deck.retentionPct / 100) {
                                EmptyView()
                            }
                            .tint(DeckColor.color(for: deck.subjectId))
                            Text(String(format: "%.0f%%", deck.retentionPct))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(BCColor.fg2)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func barHeight(for count: Int) -> CGFloat {
        let maxCount = max(viewModel.maxReviewCount, 1)
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return max(6, ratio * 96)
    }

    private func shortDayLabel(_ iso: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: iso) else { return "—" }
        parser.dateFormat = "EEE"
        return parser.string(from: date).uppercased()
    }
}

#endif
