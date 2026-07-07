import SwiftUI
import AppKit

#if os(macOS)

public struct MacMenuBarStudyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    @State private var viewModel = StudyViewModel()
    @State private var audioPlayer = CardAudioPlayer()
    @State private var stats: StatsDTO?
    @State private var loadError: String?
    @State private var sessionNotice: String?
    @State private var isQuickStarting = false

    private static let lastDeckKey = "purrfectrecall.menubar.deckId"

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 400, height: 580)
        .background(BCColor.bgBase)
        .preferredColorScheme(.dark)
        .task {
            appState.bootstrapGamification()
            await bootstrap()
        }
        .onChange(of: viewModel.selectedDeckId) { _, deckId in
            if let deckId {
                UserDefaults.standard.set(deckId, forKey: Self.lastDeckKey)
            }
        }
        .onChange(of: viewModel.currentCard?.id) { _, _ in
            audioPlayer.stop()
        }
        .overlay {
            if let celebration = appState.gamification.activeCelebration {
                CelebrationOverlay(celebration: celebration) {
                    appState.gamification.dismissCelebration()
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "cat.fill")
                .foregroundStyle(BCColor.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Quick Study")
                    .font(.headline)
                    .foregroundStyle(BCColor.fg1)
                if let stats {
                    Text("\(stats.dueToday) due today")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(BCColor.fg3)
                }
            }
            Spacer()
            if viewModel.isStudying {
                ComboBadge(combo: appState.gamification.sessionCombo)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(BCColor.bgRaised)
    }

    @ViewBuilder
    private var content: some View {
        if let loadError {
            ContentUnavailableView(
                "Cannot Reach API",
                systemImage: "wifi.exclamationmark",
                description: Text(loadError)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.isStudying, let card = viewModel.currentCard {
            studySession(card: card)
        } else {
            idleState
        }
    }

    private var idleState: some View {
        VStack(spacing: 16) {
            Picker("Deck", selection: $viewModel.selectedDeckId) {
                Text("Select deck").tag(Optional<Int>.none)
                ForEach(viewModel.subjects) { subject in
                    Text(subject.name).tag(Optional(subject.id))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task { await startSession(quick: false) }
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(BCColor.accent)
            .controlSize(.large)
            .disabled(viewModel.selectedDeckId == nil || isQuickStarting)

            Button {
                Task { await startSession(quick: true) }
            } label: {
                Label("Quick Study (most due)", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.subjects.isEmpty || isQuickStarting)

            Spacer()
            if let sessionNotice {
                Text(sessionNotice)
                    .font(.caption)
                    .foregroundStyle(BCColor.fg2)
                    .multilineTextAlignment(.center)
            }
            Text("Study from the menu bar without opening the main window.")
                .font(.caption)
                .foregroundStyle(BCColor.fg3)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func studySession(card: FlashcardDTO) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.progressLabelDesktop)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(BCColor.fg2)
                Spacer()
                Button("Stop", role: .destructive) {
                    viewModel.stop(gamification: appState.gamification)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView {
                VStack(spacing: 14) {
                    MacPanel("Question") {
                        if card.hasMedia {
                            CardMediaView(
                                card: card,
                                showAnswer: viewModel.isRevealed,
                                audioPlayer: audioPlayer
                            )
                        } else {
                            Text(card.question)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(BCColor.fg1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        if !viewModel.isRevealed {
                            Button("Show Answer") { viewModel.reveal() }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                        } else if !card.hasMedia {
                            Divider()
                            Text(card.answer)
                                .font(.body.weight(.medium))
                                .foregroundStyle(BCColor.colorInfo)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    if viewModel.isRevealed {
                        confidencePanel
                    }
                }
                .padding(16)
            }
        }
    }

    private var confidencePanel: some View {
        MacPanel("Rate Your Recall") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Confidence")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BCColor.fg2)
                    Spacer()
                    Text("\(Int(viewModel.confidence))%")
                        .font(.caption.monospacedDigit())
                }
                Slider(value: $viewModel.confidence, in: 0...100, step: 1)
                    .tint(BCColor.accent)
                Button {
                    Task {
                        await viewModel.submit(
                            using: appState.api,
                            gamification: appState.gamification
                        )
                    }
                } label: {
                    Label("Submit & Continue", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BCColor.accent)
                .disabled(viewModel.isSubmitting)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Open App") {
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.link)
            Spacer()
            Text("Lv.\(appState.gamification.level)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(BCColor.fg3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(BCColor.bgRaised)
    }

    private func bootstrap() async {
        loadError = nil
        do {
            async let subjectsTask = appState.api.fetchSubjects()
            async let statsTask = appState.api.fetchStats()
            viewModel.subjects = try await subjectsTask
            stats = try await statsTask
            if let stats {
                appState.syncGamificationFromStats(stats)
            }
            if let saved = UserDefaults.standard.object(forKey: Self.lastDeckKey) as? Int,
               viewModel.subjects.contains(where: { $0.id == saved }) {
                viewModel.selectedDeckId = saved
            } else {
                viewModel.selectedDeckId = StudyViewModel.preferredDeckId(
                    subjects: viewModel.subjects,
                    stats: stats
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func startSession(quick: Bool) async {
        isQuickStarting = true
        defer { isQuickStarting = false }
        if quick {
            await viewModel.quickStart(
                using: appState.api,
                gamification: appState.gamification,
                stats: stats
            )
        } else {
            await viewModel.start(using: appState.api, gamification: appState.gamification)
        }
        sessionNotice = viewModel.isStudying ? nil : "No cards available in this deck right now."
    }
}

#endif
