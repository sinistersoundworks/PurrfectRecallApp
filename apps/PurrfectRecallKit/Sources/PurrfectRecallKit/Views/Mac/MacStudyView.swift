import SwiftUI

#if os(macOS)

public struct MacStudyView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = StudyViewModel()
    @State private var audioPlayer = CardAudioPlayer()

    private var gamification: GamificationEngine { appState.gamification }

    public init() {}

    public var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            studyControlBar
            Divider()
            Group {
                if viewModel.isStudying, let card = viewModel.currentCard {
                    activeSession(card: card)
                } else {
                    idleState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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

    private var studyControlBar: some View {
        HStack(spacing: 16) {
            Picker("Deck", selection: $viewModel.selectedDeckId) {
                Text("Select deck").tag(Optional<Int>.none)
                ForEach(viewModel.subjects) { subject in
                    Text(subject.name).tag(Optional(subject.id))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 220)
            .disabled(viewModel.isStudying)

            if viewModel.isStudying {
                ComboBadge(combo: gamification.sessionCombo)
                Text(viewModel.progressLabelDesktop)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(BCColor.fg2)
            }

            Spacer()

            if viewModel.isStudying {
                Button("Stop Session", role: .destructive) {
                    viewModel.stop(gamification: gamification)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    Task { await viewModel.start(using: appState.api, gamification: gamification) }
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(BCColor.accent)
                .disabled(viewModel.selectedDeckId == nil)
            }
        }
        .padding(.horizontal, MacLayout.pagePadding)
        .padding(.vertical, 12)
        .background(BCColor.bgRaised)
    }

    private var idleState: some View {
        ContentUnavailableView {
            Label("Ready to Study", systemImage: "text.book.closed")
        } description: {
            Text("Choose a deck above, then start a review session.")
        } actions: {
            Button("Start Session") {
                Task { await viewModel.start(using: appState.api, gamification: gamification) }
            }
            .buttonStyle(.borderedProminent)
            .tint(BCColor.accent)
            .disabled(viewModel.selectedDeckId == nil)
        }
    }

    private func activeSession(card: FlashcardDTO) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                MacPanel("Question") {
                    if card.hasMedia {
                        CardMediaView(
                            card: card,
                            showAnswer: viewModel.isRevealed,
                            audioPlayer: audioPlayer
                        )
                    } else {
                        Text(card.question)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(BCColor.fg1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }

                    if !viewModel.isRevealed {
                        Button("Show Answer") {
                            viewModel.reveal()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else if !card.hasMedia {
                        Divider()
                        Text("Answer")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BCColor.fg2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(card.answer)
                            .font(.title3)
                            .foregroundStyle(BCColor.colorInfo)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: MacLayout.studyCardMaxWidth)

                if viewModel.isRevealed {
                    confidencePanel
                        .frame(maxWidth: MacLayout.studyCardMaxWidth)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MacLayout.pagePadding)
            .padding(.vertical, 32)
        }
    }

    private var confidencePanel: some View {
        MacPanel("Rate Your Recall") {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Predicted Recall", systemImage: "waveform.path.ecg")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BCColor.fg2)
                        Spacer()
                        Text("\(viewModel.predictedRecall)%")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(BCColor.colorInfo)
                    }
                    BCMeter(value: Double(viewModel.predictedRecall))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confidence")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BCColor.fg2)
                        Spacer()
                        Text("\(Int(viewModel.confidence))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(BCColor.fg1)
                    }
                    Slider(value: $viewModel.confidence, in: 0...100, step: 1)
                        .tint(BCColor.accent)
                }

                Button {
                    Task { await viewModel.submit(using: appState.api, gamification: gamification) }
                } label: {
                    Label("Submit & Continue", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BCColor.accent)
                .controlSize(.large)
                .disabled(viewModel.isSubmitting)
            }
        }
    }
}

#endif
