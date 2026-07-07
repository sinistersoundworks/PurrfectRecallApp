import SwiftUI

#if os(macOS)

public struct MacDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()

    public init() {}

    public var body: some View {
        @Bindable var viewModel = viewModel
        MacPageContainer {
            playerHero
            DailyChallengesCard(engine: appState.gamification)
            header(viewModel: viewModel)
            statsRow(viewModel: viewModel)
            insightsSection(viewModel: viewModel)
            decksSection(viewModel: viewModel)
        }
        .task(id: appState.dataRefreshToken) {
            await viewModel.load(using: appState.api, gamification: appState.gamification)
        }
        .overlay(alignment: .top) {
            if let error = viewModel.loadError {
                errorBanner(error)
            }
        }
    }

    private var playerHero: some View {
        XPProgressBar(
            totalXP: appState.gamification.progress.totalXP,
            level: appState.gamification.level,
            title: appState.gamification.levelTitle
        )
    }

    private func header(viewModel: DashboardViewModel) -> some View {
        HStack(alignment: .top) {
            MacSectionHeader(
                Greeting.current(),
                subtitle: viewModel.stats.map {
                    MacCopy.deckSummary(due: $0.dueToday, deckCount: viewModel.subjects.count)
                }
            )
            Spacer(minLength: 16)
            Button {
                appState.startStudy(deckId: preferredStudyDeckId(viewModel: viewModel))
            } label: {
                Label("Start Study", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(BCColor.accent)
            .controlSize(.large)
            .disabled(viewModel.subjects.isEmpty)
        }
    }

    @ViewBuilder
    private func statsRow(viewModel: DashboardViewModel) -> some View {
        if let stats = viewModel.stats {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                spacing: 16
            ) {
                MacStatTile("Streak", value: "\(stats.streakDays)", tint: BCColor.accent)
                MacStatTile("Due Today", value: "\(stats.dueToday)")
                MacStatTile("Cards Learned", value: "\(stats.cardsLearned)")
                MacStatTile("Best Combo", value: "x\(appState.gamification.progress.bestCombo)", tint: BCColor.colorInfo)
            }
        }
    }

    @ViewBuilder
    private func insightsSection(viewModel: DashboardViewModel) -> some View {
        if let stats = viewModel.stats,
           stats.weakestDeckName != nil || stats.improvingDeckName != nil {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                ],
                spacing: 16
            ) {
                if let name = stats.weakestDeckName,
                   let deck = stats.deckInsights.first(where: { $0.name == name }) {
                    MacInsightCard(
                        title: "Weakest Deck",
                        name: name,
                        detail: String(format: "%.0f%% retention", deck.retentionPct),
                        systemImage: "exclamationmark.triangle.fill",
                        tint: BCColor.colorDanger
                    ) {
                        appState.openDeck(deck.subjectId)
                    }
                }
                if let name = stats.improvingDeckName,
                   let deck = stats.deckInsights.first(where: { $0.name == name }) {
                    MacInsightCard(
                        title: "Improving",
                        name: name,
                        detail: deck.trendLabel,
                        systemImage: "arrow.up.right.circle.fill",
                        tint: BCColor.colorActive
                    ) {
                        appState.openDeck(deck.subjectId)
                    }
                }
            }
        }
    }

    private func decksSection(viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Decks")
                .font(.headline)
                .foregroundStyle(BCColor.fg1)

            if viewModel.subjects.isEmpty {
                ContentUnavailableView(
                    "No Decks Yet",
                    systemImage: "rectangle.stack.badge.plus",
                    description: Text("Create a deck in the Decks tab to get started.")
                )
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.subjects) { subject in
                        let deck = viewModel.deckStat(for: subject.id)
                        MacDeckCard(
                            name: subject.name,
                            description: subject.description,
                            due: deck?.due ?? 0,
                            mastered: deck?.mastered ?? 0,
                            total: deck?.total ?? 0,
                            color: DeckColor.color(for: subject.id)
                        ) {
                            appState.openDeck(subject.id)
                        }
                    }
                }
            }
        }
    }

    private func preferredStudyDeckId(viewModel: DashboardViewModel) -> Int? {
        viewModel.subjects.first { subject in
            (viewModel.deckStat(for: subject.id)?.due ?? 0) > 0
        }?.id ?? viewModel.subjects.first?.id
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(BCColor.colorDanger)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(BCColor.colorDangerDim)
    }
}

private struct MacDeckCard: View {
    let name: String
    let description: String?
    let due: Int
    let mastered: Int
    let total: Int
    let color: Color
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(BCColor.fg1)
                    Spacer()
                    if due > 0 {
                        Text("\(due) due")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(BCColor.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(BCColor.accentDim, in: Capsule())
                    }
                }
                if let description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(BCColor.fg2)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                ProgressView(value: total > 0 ? Double(mastered) / Double(total) : 0) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(BCColor.fg3)
                } currentValueLabel: {
                    Text("\(mastered)/\(total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(BCColor.fg2)
                }
                .tint(color)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHovered ? BCColor.bgElevated : BCColor.bgRaised,
                in: RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous)
                    .stroke(isHovered ? BCColor.borderStrong : BCColor.borderDefault, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct MacInsightCard: View {
    let title: String
    let name: String
    let detail: String
    let systemImage: String
    let tint: Color
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BCColor.fg3)
                }
                Text(name)
                    .font(.headline)
                    .foregroundStyle(BCColor.fg1)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(BCColor.fg2)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHovered ? BCColor.bgElevated : BCColor.bgRaised,
                in: RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: MacLayout.cardCornerRadius, style: .continuous)
                    .stroke(isHovered ? BCColor.borderStrong : BCColor.borderDefault, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#endif
