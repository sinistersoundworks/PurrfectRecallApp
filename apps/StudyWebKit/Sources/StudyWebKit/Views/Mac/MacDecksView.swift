import SwiftUI

public struct MacDecksView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DecksViewModel()
    @State private var showError: String?

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            leftRail
                .frame(width: 340)
                .background(BCColor.bgRaised)
                .overlay(alignment: .trailing) {
                    Rectangle().fill(BCColor.borderSubtle).frame(width: 1)
                }
            rightPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BCColor.bgBase)
        }
        .task {
            await viewModel.load(using: appState.api)
            if let deckId = appState.selectedDeckId {
                viewModel.selectDeck(deckId)
                appState.selectedDeckId = nil
                await viewModel.loadCards(using: appState.api)
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
        .sheet(item: $viewModel.editingCard) { card in
            editCardSheet(card)
        }
        .sheet(item: $viewModel.editingSubject) { subject in
            editSubjectSheet(subject)
        }
    }

    private var leftRail: some View {
        VStack(alignment: .leading, spacing: BCSpacing.s3) {
            BCInput("Search decks…", text: $viewModel.searchText)
            HStack {
                BCInput("New deck name", text: $viewModel.newDeckName)
                BCButton("New Deck", variant: .secondary, size: .sm) {
                    Task {
                        do { try await viewModel.createDeck(using: appState.api) }
                        catch { showError = error.localizedDescription }
                    }
                }
            }
            ScrollView {
                VStack(spacing: BCSpacing.s1) {
                    ForEach(viewModel.filteredSubjects) { subject in
                        deckRow(subject)
                    }
                }
            }
        }
        .padding(BCSpacing.s4)
    }

    private func deckRow(_ subject: SubjectDTO) -> some View {
        let selected = viewModel.selectedDeckId == subject.id
        return Button {
            viewModel.selectDeck(subject.id)
            Task { await viewModel.loadCards(using: appState.api) }
        } label: {
            HStack(spacing: BCSpacing.s2) {
                RoundedRectangle(cornerRadius: BCRadius.xs)
                    .fill(DeckColor.color(for: subject.id))
                    .frame(width: 7, height: 7)
                Text(subject.name)
                    .font(BCFont.ui(BCFont.textMD, weight: .medium))
                    .foregroundStyle(BCColor.fg1)
                Spacer()
                Text("\(viewModel.subjects.first(where: { $0.id == subject.id }) != nil ? cardCountLabel(subject.id) : "0")")
                    .font(BCFont.mono(BCFont.text2XS))
                    .foregroundStyle(BCColor.fg3)
            }
            .padding(.horizontal, BCSpacing.s2)
            .padding(.vertical, BCSpacing.s2)
            .background(selected ? BCColor.accentDim : BCColor.bgControl)
            .clipShape(RoundedRectangle(cornerRadius: BCRadius.sm))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit") { viewModel.beginEditSubject(subject) }
            Button("Delete", role: .destructive) {
                Task {
                    do { try await viewModel.deleteSubject(subject, using: appState.api) }
                    catch { showError = error.localizedDescription }
                }
            }
        }
    }

    private func cardCountLabel(_ subjectId: Int) -> String {
        if viewModel.selectedDeckId == subjectId {
            return "\(viewModel.cards.count)"
        }
        return "…"
    }

    @ViewBuilder
    private var rightPane: some View {
        if let subject = viewModel.selectedSubject {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.s4) {
                    HStack {
                        VStack(alignment: .leading, spacing: BCSpacing.s1) {
                            Text(subject.name)
                                .font(BCFont.ui(BCFont.textXL, weight: .semibold))
                                .foregroundStyle(BCColor.fg1)
                            if let description = subject.description {
                                Text(description)
                                    .font(BCFont.ui(BCFont.textSM))
                                    .foregroundStyle(BCColor.fg3)
                            }
                        }
                        Spacer()
                        if let deck = deckStats(for: subject.id) {
                            Text("\(deck.mastered) mastered · \(deck.due) due")
                                .font(BCFont.mono(BCFont.textXS))
                                .foregroundStyle(BCColor.fg3)
                        }
                    }

                    BCCard {
                        VStack(alignment: .leading, spacing: BCSpacing.s2) {
                            BCCapsLabel("Add Flashcard")
                            BCInput("Question", text: $viewModel.newQuestion)
                            BCInput("Answer", text: $viewModel.newAnswer)
                            BCButton("Add", variant: .primary, size: .sm) {
                                Task {
                                    do { try await viewModel.createCard(using: appState.api) }
                                    catch { showError = error.localizedDescription }
                                }
                            }
                        }
                    }

                    BCInput("Search cards…", text: $viewModel.searchText)

                    ForEach(viewModel.filteredCards) { card in
                        cardRow(card)
                    }
                }
                .padding(BCSpacing.s6)
            }
        } else {
            Text("Select or create a deck")
                .font(BCFont.ui(BCFont.textMD))
                .foregroundStyle(BCColor.fg3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cardRow(_ card: FlashcardDTO) -> some View {
        BCCard {
            HStack(alignment: .top, spacing: BCSpacing.s3) {
                VStack(alignment: .leading, spacing: BCSpacing.s1) {
                    Text(card.question)
                        .font(BCFont.ui(BCFont.textMD, weight: .medium))
                        .foregroundStyle(BCColor.fg1)
                    Text(card.answer)
                        .font(BCFont.ui(BCFont.textSM))
                        .foregroundStyle(BCColor.fg2)
                }
                Spacer()
                BCStatusPill(CardStatus.kind(for: card))
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

    private func deckStats(for subjectId: Int) -> DeckStatsDTO? {
        // loaded on demand via stats in future; derive from cards for now
        let total = viewModel.cards.count
        let mastered = viewModel.cards.filter { $0.repetition >= 2 }.count
        let due = viewModel.cards.filter { $0.dueDate <= Date() }.count
        return DeckStatsDTO(subjectId: subjectId, name: "", total: total, mastered: mastered, due: due, retentionPct: 0)
    }

    private func editCardSheet(_ card: FlashcardDTO) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.s3) {
            Text("Edit Flashcard").font(BCFont.ui(BCFont.textLG, weight: .semibold)).foregroundStyle(BCColor.fg1)
            BCInput("Question", text: $viewModel.editQuestion)
            BCInput("Answer", text: $viewModel.editAnswer)
            HStack {
                BCButton("Save", variant: .primary) {
                    Task {
                        do {
                            try await viewModel.saveEditCard(using: appState.api)
                        } catch { showError = error.localizedDescription }
                    }
                }
                BCButton("Cancel", variant: .secondary) { viewModel.editingCard = nil }
            }
        }
        .padding(BCSpacing.s6)
        .frame(minWidth: 420, minHeight: 260)
        .background(BCColor.bgBase)
    }

    private func editSubjectSheet(_ subject: SubjectDTO) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.s3) {
            Text("Edit Deck").font(BCFont.ui(BCFont.textLG, weight: .semibold)).foregroundStyle(BCColor.fg1)
            BCInput("Name", text: $viewModel.editSubjectName)
            BCInput("Description", text: $viewModel.editSubjectDescription)
            HStack {
                BCButton("Save", variant: .primary) {
                    Task {
                        do { try await viewModel.saveEditSubject(using: appState.api) }
                        catch { showError = error.localizedDescription }
                    }
                }
                BCButton("Cancel", variant: .secondary) { viewModel.editingSubject = nil }
            }
        }
        .padding(BCSpacing.s6)
        .frame(minWidth: 420, minHeight: 260)
        .background(BCColor.bgBase)
    }
}