import SwiftUI

public struct DashboardContentView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()
    var compact: Bool

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.s6) {
                XPProgressBar(
                    totalXP: appState.gamification.progress.totalXP,
                    level: appState.gamification.level,
                    title: appState.gamification.levelTitle,
                    compact: compact
                )
                DailyChallengesCard(engine: appState.gamification, compact: compact)
                header
                statsGrid
                BCButton("Start Study", variant: .primary, size: .lg) {
                    appState.startStudy(deckId: viewModel.subjects.first?.id)
                }
                BCCapsLabel("Decks")
                deckGrid
            }
            .padding(compact ? BCSpacing.s4 : BCSpacing.s7)
        }
        .background(BCColor.bgBase)
        .task { await viewModel.load(using: appState.api, gamification: appState.gamification) }
        .refreshable { await viewModel.load(using: appState.api, gamification: appState.gamification) }
        .overlay(alignment: .top) {
            if let error = viewModel.loadError {
                Text(error)
                    .font(BCFont.ui(BCFont.textSM))
                    .foregroundStyle(BCColor.colorDanger)
                    .padding(BCSpacing.s3)
                    .frame(maxWidth: .infinity)
                    .background(BCColor.colorDangerDim)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: BCSpacing.s1) {
                Text(Greeting.current())
                    .font(BCFont.ui(compact ? BCFont.textXL : BCFont.text2XL, weight: .semibold))
                    .foregroundStyle(BCColor.fg1)
                if let stats = viewModel.stats {
                    Text("\(stats.dueToday) cards due across \(viewModel.subjects.count) decks")
                        .font(BCFont.mono(BCFont.textXS))
                        .foregroundStyle(BCColor.fg3)
                }
            }
            Spacer()
            if !compact {
                BCButton("Start Study", variant: .primary) {
                    appState.startStudy(deckId: viewModel.subjects.first?.id)
                }
            }
        }
    }

    @ViewBuilder
    private var statsGrid: some View {
        let columns = compact
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)
        LazyVGrid(columns: columns, spacing: 14) {
            if let stats = viewModel.stats {
                StatCardView(label: "Streak", value: "\(stats.streakDays)", valueColor: BCColor.accent)
                StatCardView(label: "Due Today", value: "\(stats.dueToday)")
                if !compact {
                    StatCardView(label: "Cards Learned", value: "\(stats.cardsLearned)")
                    StatCardView(label: "Retention", value: String(format: "%.0f%%", stats.retentionPct), valueColor: BCColor.colorActive)
                } else {
                    StatCardView(label: "Retention", value: String(format: "%.0f%%", stats.retentionPct), valueColor: BCColor.colorActive)
                }
            }
        }
    }

    @ViewBuilder
    private var deckGrid: some View {
        let columns = compact
            ? [GridItem(.flexible())]
            : Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(viewModel.subjects) { subject in
                let deck = viewModel.deckStat(for: subject.id)
                DeckCardView(
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

public struct StudyContentView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = StudyViewModel()
    @State private var audioPlayer = CardAudioPlayer()
    var compact: Bool

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.s4) {
            controls
            if viewModel.isStudying, let card = viewModel.currentCard {
                studySession(card: card)
            } else {
                emptyState
            }
        }
        .padding(compact ? BCSpacing.s4 : BCSpacing.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(BCColor.bgBase)
        .task {
            await viewModel.loadSubjects(using: appState.api)
            viewModel.applyInitialDeck(appState.studyDeckId)
            appState.studyDeckId = nil
        }
        .onChange(of: viewModel.currentCard?.id) { _, _ in
            audioPlayer.stop()
        }
    }

    private var controls: some View {
        HStack(spacing: BCSpacing.s2) {
            BCSelect(
                options: viewModel.subjects.map { ($0.id, $0.name) },
                selection: $viewModel.selectedDeckId
            )
            if viewModel.isStudying {
                BCButton("Stop", variant: .secondary, size: .sm) {
                    viewModel.stop(gamification: appState.gamification)
                }
            } else {
                BCButton("Start", variant: .primary, size: .sm) {
                    Task {
                        await viewModel.start(using: appState.api, gamification: appState.gamification)
                    }
                }
            }
            Spacer()
            if viewModel.isStudying {
                ComboBadge(combo: appState.gamification.sessionCombo)
                Text(compact ? viewModel.progressLabelMobile : viewModel.progressLabelDesktop)
                    .font(BCFont.mono(BCFont.textXS))
                    .foregroundStyle(BCColor.fg3)
            }
        }
    }

    private func studySession(card: FlashcardDTO) -> some View {
        ScrollView {
            VStack(spacing: BCSpacing.s4) {
                BCCard(padding: compact ? BCSpacing.s6 : BCSpacing.s12) {
                    VStack(spacing: BCSpacing.s4) {
                        if card.hasMedia {
                            CardMediaView(
                                card: card,
                                showAnswer: viewModel.isRevealed,
                                audioPlayer: audioPlayer
                            )
                        } else {
                            BCCapsLabel("Question")
                            Text(card.question)
                                .font(BCFont.ui(compact ? BCFont.textLG : BCFont.text2XL))
                                .foregroundStyle(BCColor.fg1)
                                .multilineTextAlignment(.center)
                        }
                        if !viewModel.isRevealed {
                            BCButton("Show Answer", variant: .secondary) { viewModel.reveal() }
                        } else if !card.hasMedia {
                            Divider().overlay(BCColor.borderDefault)
                            BCCapsLabel("Answer")
                            Text(card.answer)
                                .font(BCFont.ui(BCFont.textMD))
                                .foregroundStyle(BCColor.colorInfo)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .shadow(color: .black.opacity(0.72), radius: 16, y: 4)

                if viewModel.isRevealed {
                    confidencePanel
                }
            }
        }
    }

    private var confidencePanel: some View {
        BCCard(padding: BCSpacing.s4) {
            VStack(alignment: .leading, spacing: BCSpacing.s3) {
                HStack {
                    BCCapsLabel("AI Predicted Recall")
                    Spacer()
                    Text("\(viewModel.predictedRecall)%")
                        .font(BCFont.mono(BCFont.textSM))
                        .foregroundStyle(BCColor.colorInfo)
                }
                BCMeter(value: Double(viewModel.predictedRecall))
                if let hint = viewModel.calibrationHint {
                    Text(hint)
                        .font(BCFont.ui(BCFont.textXS))
                        .foregroundStyle(BCColor.fg3)
                }
                HStack {
                    BCCapsLabel("Confidence")
                    Spacer()
                    Text("\(Int(viewModel.confidence))%")
                        .font(BCFont.mono(BCFont.textSM))
                        .foregroundStyle(BCColor.fg2)
                }
                BCSlider(value: $viewModel.confidence)
                BCButton("Submit", variant: .primary, isDisabled: viewModel.isSubmitting) {
                    Task {
                        await viewModel.submit(using: appState.api, gamification: appState.gamification)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: BCSpacing.s3) {
            Spacer()
            Text("Select a deck and press Start")
                .font(BCFont.ui(BCFont.textMD))
                .foregroundStyle(BCColor.fg3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

public struct StatsContentView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = StatsViewModel()
    var compact: Bool

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.s4) {
                statsRow
                if let stats = viewModel.stats {
                    ReviewsChartView(days: stats.reviewsLast7Days, maxCount: viewModel.maxReviewCount)
                    BCCard(padding: BCSpacing.s4) {
                        BCCapsLabel("Deck Retention")
                            .padding(.bottom, BCSpacing.s3)
                        ForEach(stats.deckStats) { deck in
                            DeckRetentionRow(
                                name: deck.name,
                                retention: deck.retentionPct,
                                color: DeckColor.color(for: deck.subjectId)
                            )
                            .padding(.vertical, BCSpacing.s1)
                        }
                    }
                }
            }
            .padding(compact ? BCSpacing.s4 : BCSpacing.s7)
        }
        .background(BCColor.bgBase)
        .task {
            await viewModel.load(using: appState.api)
            if let stats = viewModel.stats {
                appState.syncGamificationFromStats(stats)
            }
        }
        .refreshable {
            await viewModel.load(using: appState.api)
            if let stats = viewModel.stats {
                appState.syncGamificationFromStats(stats)
            }
        }
    }

    @ViewBuilder
    private var statsRow: some View {
        let columns = compact
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)
        LazyVGrid(columns: columns, spacing: 14) {
            if let stats = viewModel.stats {
                StatCardView(label: "Longest Streak", value: "\(stats.streakDays)", valueColor: BCColor.accent)
                StatCardView(label: "Cards Learned", value: "\(stats.cardsLearned)")
                StatCardView(label: "Retention", value: String(format: "%.0f%%", stats.retentionPct), valueColor: BCColor.colorActive)
                if !compact {
                    StatCardView(label: "Avg. Ease", value: String(format: "%.2f", stats.avgEase))
                }
            }
        }
    }
}
