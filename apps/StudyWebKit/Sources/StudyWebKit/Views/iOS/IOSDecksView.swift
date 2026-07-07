import SwiftUI

public struct IOSDecksView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DecksViewModel()
    @State private var showDetail = false
    @State private var showError: String?

    public init() {}

    public var body: some View {
        Group {
            if showDetail, viewModel.selectedSubject != nil {
                deckDetail
            } else {
                deckList
            }
        }
        .background(BCColor.bgBase)
        .task {
            await viewModel.load(using: appState.api)
            if let deckId = appState.selectedDeckId {
                viewModel.selectDeck(deckId)
                appState.selectedDeckId = nil
                await viewModel.loadCards(using: appState.api)
                showDetail = true
            }
        }
        .alert("Error", isPresented: Binding(
            get: { showError != nil },
            set: { if !$0 { showError = nil } }
        )) {
            Button("OK") { showError = nil }
        } message: {
            Text(showError ?? "")
        }
        .sheet(item: $viewModel.editingCard) { _ in editCardSheet }
        .sheet(item: $viewModel.editingSubject) { _ in editSubjectSheet }
    }

    private var deckList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.s3) {
                BCInput("Search decks…", text: $viewModel.searchText)
                HStack {
                    BCInput("New deck", text: $viewModel.newDeckName)
                    BCButton("Add", variant: .secondary, size: .sm) {
                        Task {
                            do { try await viewModel.createDeck(using: appState.api) }
                            catch { showError = error.localizedDescription }
                        }
                    }
                }
                ForEach(viewModel.filteredSubjects) { subject in
                    Button {
                        viewModel.selectDeck(subject.id)
                        Task { await viewModel.loadCards(using: appState.api) }
                        showDetail = true
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: BCRadius.xs)
                                .fill(DeckColor.color(for: subject.id))
                                .frame(width: 7, height: 7)
                            Text(subject.name)
                                .font(BCFont.ui(BCFont.textBase, weight: .semibold))
                                .foregroundStyle(BCColor.fg1)
                            Spacer()
                            Text("›")
                                .foregroundStyle(BCColor.fg3)
                        }
                        .padding(BCSpacing.s3)
                        .background(BCColor.bgRaised)
                        .clipShape(RoundedRectangle(cornerRadius: BCRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(BCSpacing.s4)
        }
    }

    private var deckDetail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.s3) {
                Button {
                    showDetail = false
                } label: {
                    Text("‹ All Decks")
                        .font(BCFont.ui(BCFont.textSM, weight: .medium))
                        .foregroundStyle(BCColor.accent)
                }
                .buttonStyle(.plain)

                if let subject = viewModel.selectedSubject {
                    Text(subject.name)
                        .font(BCFont.ui(BCFont.textXL, weight: .semibold))
                        .foregroundStyle(BCColor.fg1)

                    BCCard {
                        BCInput("Question", text: $viewModel.newQuestion)
                        BCInput("Answer", text: $viewModel.newAnswer)
                        BCButton("Add Flashcard", variant: .primary, size: .sm) {
                            Task {
                                do { try await viewModel.createCard(using: appState.api) }
                                catch { showError = error.localizedDescription }
                            }
                        }
                    }

                    ForEach(viewModel.cards) { card in
                        BCCard {
                            VStack(alignment: .leading, spacing: BCSpacing.s2) {
                                HStack {
                                    BCStatusPill(CardStatus.kind(for: card))
                                    Spacer()
                                }
                                Text(card.question).foregroundStyle(BCColor.fg1)
                                Text(card.answer).foregroundStyle(BCColor.fg2).font(BCFont.ui(BCFont.textSM))
                                HStack {
                                    BCButton("Edit", variant: .secondary, size: .sm) { viewModel.beginEditCard(card) }
                                    BCButton("Delete", variant: .secondary, size: .sm) {
                                        Task {
                                            do { try await viewModel.deleteCard(card, using: appState.api) }
                                            catch { showError = error.localizedDescription }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(BCSpacing.s4)
        }
    }

    private var editCardSheet: some View {
        VStack(alignment: .leading, spacing: BCSpacing.s3) {
            Text("Edit Flashcard").font(BCFont.ui(BCFont.textLG, weight: .semibold))
            BCInput("Question", text: $viewModel.editQuestion)
            BCInput("Answer", text: $viewModel.editAnswer)
            BCButton("Save", variant: .primary) {
                Task {
                    do { try await viewModel.saveEditCard(using: appState.api) }
                    catch { showError = error.localizedDescription }
                }
            }
        }
        .padding(BCSpacing.s4)
        .presentationDetents([.medium])
        .background(BCColor.bgBase)
    }

    private var editSubjectSheet: some View {
        VStack(alignment: .leading, spacing: BCSpacing.s3) {
            Text("Edit Deck").font(BCFont.ui(BCFont.textLG, weight: .semibold))
            BCInput("Name", text: $viewModel.editSubjectName)
            BCInput("Description", text: $viewModel.editSubjectDescription)
            BCButton("Save", variant: .primary) {
                Task {
                    do { try await viewModel.saveEditSubject(using: appState.api) }
                    catch { showError = error.localizedDescription }
                }
            }
        }
        .padding(BCSpacing.s4)
        .presentationDetents([.medium])
        .background(BCColor.bgBase)
    }
}
