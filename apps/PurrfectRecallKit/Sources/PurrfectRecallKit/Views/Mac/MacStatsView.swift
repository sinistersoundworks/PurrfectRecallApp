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
                if stats.weakestDeckName != nil || stats.improvingDeckName != nil || stats.globalStudyTip != nil {
                    insightsPanel(stats)
                }
                reviewsChart(stats)
                if let forecast = viewModel.forecast, !forecast.points.isEmpty {
                    forecastChart(forecast)
                }
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

    private func insightsPanel(_ stats: StatsDTO) -> some View {
        MacPanel("Insights") {
            VStack(alignment: .leading, spacing: 10) {
                if let name = stats.weakestDeckName {
                    insightRow(
                        icon: "exclamationmark.triangle.fill",
                        tint: BCColor.colorDanger,
                        title: "Weakest deck",
                        detail: "\(name) — review when fresh"
                    )
                }
                if let name = stats.improvingDeckName {
                    insightRow(
                        icon: "arrow.up.right.circle.fill",
                        tint: BCColor.colorActive,
                        title: "Improving",
                        detail: name
                    )
                }
                if let tip = stats.globalStudyTip {
                    insightRow(
                        icon: "clock.fill",
                        tint: BCColor.colorInfo,
                        title: "Study timing",
                        detail: tip
                    )
                }
            }
        }
    }

    private func insightRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BCColor.fg1)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(BCColor.fg2)
            }
        }
    }

    private func forecastChart(_ forecast: ForecastDTO) -> some View {
        MacPanel("Retention Forecast — Next \(forecast.days) Days") {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(forecast.points, id: \.date) { point in
                    VStack(spacing: 8) {
                        if let pct = point.expectedRetentionPct {
                            Text(String(format: "%.0f%%", pct))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(BCColor.fg2)
                        } else {
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(BCColor.fg3)
                        }
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(BCColor.colorInfo.opacity(0.85))
                            .frame(height: forecastBarHeight(for: point.expectedRetentionPct))
                        Text(shortDayLabel(point.date))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(BCColor.fg3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120, alignment: .bottom)
        }
    }

    private func forecastBarHeight(for pct: Double?) -> CGFloat {
        guard let pct else { return 6 }
        let ratio = CGFloat(pct / viewModel.maxForecastRetention)
        return max(6, ratio * 72)
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
                        let insight = stats.deckInsights.first { $0.subjectId == deck.subjectId }
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(DeckColor.color(for: deck.subjectId))
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(deck.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(BCColor.fg1)
                                    if insight?.needsAttention == true {
                                        Text("Needs attention")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(BCColor.colorDanger)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(BCColor.colorDangerDim, in: Capsule())
                                    }
                                }
                                if let insight {
                                    Text(insight.trendLabel)
                                        .font(.caption)
                                        .foregroundStyle(BCColor.fg3)
                                }
                            }
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
