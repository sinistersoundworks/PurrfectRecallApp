import SwiftUI

#if os(macOS)

public struct MacDecksView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DecksViewModel()
    @State private var showError: String?
    @State private var cardSearchText = ""

    public init() {}

    public var body: some View {
        @Bindable var viewModel = viewModel

        HSplitView {
            DeckSidebarPanel(
                viewModel: viewModel,
                showError: $showError,
                api: appState.api
            )
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)

            DeckDetailPanel(
                viewModel: viewModel,
                cardSearchText: $cardSearchText,
                showError: $showError,
                appState: appState
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(viewModel.selectedSubject?.name ?? "Decks")
        .task(id: appState.dataRefreshToken) {
            await reloadDecks(viewModel: viewModel)
        }
        .overlay(alignment: .top) {
            if let error = viewModel.loadError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(BCColor.colorDanger)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(BCColor.colorDangerDim)
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
        .sheet(item: $viewModel.editingCard) { _ in
            EditCardSheet(viewModel: viewModel, showError: $showError, api: appState.api)
        }
        .sheet(item: $viewModel.editingSubject) { _ in
            EditSubjectSheet(viewModel: viewModel, showError: $showError, api: appState.api)
        }
    }

    private func reloadDecks(viewModel: DecksViewModel) async {
        await viewModel.load(using: appState.api)
        if let deckId = appState.selectedDeckId {
            viewModel.selectDeck(deckId)
            appState.selectedDeckId = nil
            await viewModel.loadCards(using: appState.api)
        }
    }
}

// MARK: - Sidebar

private struct DeckSidebarPanel: View {
    @Bindable var viewModel: DecksViewModel
    @Binding var showError: String?
    let api: APIClient

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search decks", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding(12)
                .background(.ultraThinMaterial)
                .overlay(alignment: .bottom) { Divider() }

            ScrollView {
                LazyVStack(spacing: 4) {
                    if viewModel.filteredSubjects.isEmpty {
                        ContentUnavailableView(
                            "No Decks",
                            systemImage: "rectangle.stack",
                            description: Text("Create a deck below or run `make start-api`.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 140)
                        .padding(.top, 16)
                    } else {
                        ForEach(viewModel.filteredSubjects) { subject in
                            deckRow(subject)
                        }
                    }
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("New deck name", text: $viewModel.newDeckName)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task {
                        do { try await viewModel.createDeck(using: api) }
                        catch { showError = error.localizedDescription }
                    }
                } label: {
                    Label("Create Deck", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BCColor.accent)
                .disabled(viewModel.newDeckName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) { Divider() }
        }
        .background(BCColor.bgRaised)
    }

    private func deckRow(_ subject: SubjectDTO) -> some View {
        let isSelected = viewModel.selectedDeckId == subject.id
        return Button {
            viewModel.selectDeck(subject.id)
            Task { await viewModel.loadCards(using: api) }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(DeckColor.color(for: subject.id))
                    .frame(width: 8, height: 8)
                Text(subject.name)
                    .foregroundStyle(BCColor.fg1)
                Spacer()
                if isSelected {
                    Text("\(viewModel.cards.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? BCColor.accentDim : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit Deck…") { viewModel.beginEditSubject(subject) }
            Button("Delete Deck", role: .destructive) {
                Task {
                    do { try await viewModel.deleteSubject(subject, using: api) }
                    catch { showError = error.localizedDescription }
                }
            }
        }
    }
}

// MARK: - Detail

private struct DeckDetailPanel: View {
    @Bindable var viewModel: DecksViewModel
    @Binding var cardSearchText: String
    @Binding var showError: String?
    let appState: AppState

    private var filteredCards: [FlashcardDTO] {
        guard !cardSearchText.isEmpty else { return viewModel.cards }
        return viewModel.cards.filter {
            $0.question.localizedCaseInsensitiveContains(cardSearchText)
                || $0.answer.localizedCaseInsensitiveContains(cardSearchText)
        }
    }

    var body: some View {
        if let subject = viewModel.selectedSubject {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(subject.name)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(BCColor.fg1)
                            if let description = subject.description, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundStyle(BCColor.fg2)
                            }
                            let stats = deckStats(for: subject.id)
                            Text("\(stats.mastered) mastered · \(stats.due) due · \(stats.total) cards")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(BCColor.fg3)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Button("Edit Deck") { viewModel.beginEditSubject(subject) }
                                .buttonStyle(.bordered)
                            Button {
                                appState.startStudy(deckId: subject.id)
                            } label: {
                                Label("Study Deck", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BCColor.accent)
                        }
                    }

                    MacPanel("Add Flashcard") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Question", text: $viewModel.newQuestion, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                            TextField("Answer", text: $viewModel.newAnswer, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                            Button {
                                Task {
                                    do { try await viewModel.createCard(using: appState.api) }
                                    catch { showError = error.localizedDescription }
                                }
                            } label: {
                                Label("Add Card", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BCColor.accent)
                            .disabled(viewModel.newQuestion.isEmpty || viewModel.newAnswer.isEmpty)
                        }
                    }

                    MacPanel("Cards") {
                        TextField("Search cards", text: $cardSearchText)
                            .textFieldStyle(.roundedBorder)

                        if filteredCards.isEmpty {
                            ContentUnavailableView(
                                "No Cards",
                                systemImage: "rectangle.on.rectangle.slash",
                                description: Text("Add a flashcard above to populate this deck.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(filteredCards) { card in
                                    cardRow(card)
                                    if card.id != filteredCards.last?.id {
                                        Divider().padding(.leading, 8)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(MacLayout.pagePadding)
                .frame(maxWidth: MacLayout.pageMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(BCColor.bgBase)
        } else {
            ContentUnavailableView(
                "Select a Deck",
                systemImage: "rectangle.stack",
                description: Text("Choose a deck from the sidebar or create a new one.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BCColor.bgBase)
        }
    }

    private func cardRow(_ card: FlashcardDTO) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(card.question)
                        .font(.body.weight(.medium))
                        .foregroundStyle(BCColor.fg1)
                    if card.hasMedia {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.caption)
                            .foregroundStyle(BCColor.accent)
                    }
                }
                Text(card.answer)
                    .font(.subheadline)
                    .foregroundStyle(BCColor.fg2)
            }
            Spacer()
            BCStatusPill(CardStatus.kind(for: card))
            HStack(spacing: 8) {
                Button("Edit") { viewModel.beginEditCard(card) }
                    .buttonStyle(.bordered)
                Button("Delete", role: .destructive) {
                    Task {
                        do { try await viewModel.deleteCard(card, using: appState.api) }
                        catch { showError = error.localizedDescription }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 12)
    }

    private func deckStats(for subjectId: Int) -> (mastered: Int, due: Int, total: Int) {
        let total = viewModel.cards.count
        let mastered = viewModel.cards.filter { $0.repetition >= 2 }.count
        let due = viewModel.cards.filter { $0.dueDate <= Date() }.count
        return (mastered, due, total)
    }
}

// MARK: - Sheets

private struct EditCardSheet: View {
    @Bindable var viewModel: DecksViewModel
    @Binding var showError: String?
    let api: APIClient

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Flashcard").font(.title3.weight(.semibold))
            TextField("Question", text: $viewModel.editQuestion, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...6)
            TextField("Answer", text: $viewModel.editAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...6)
            HStack {
                Spacer()
                Button("Cancel") { viewModel.editingCard = nil }
                Button("Save") {
                    Task {
                        do { try await viewModel.saveEditCard(using: api) }
                        catch { showError = error.localizedDescription }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(BCColor.accent)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}

private struct EditSubjectSheet: View {
    @Bindable var viewModel: DecksViewModel
    @Binding var showError: String?
    let api: APIClient

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Deck").font(.title3.weight(.semibold))
            TextField("Name", text: $viewModel.editSubjectName)
                .textFieldStyle(.roundedBorder)
            TextField("Description", text: $viewModel.editSubjectDescription)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { viewModel.editingSubject = nil }
                Button("Save") {
                    Task {
                        do { try await viewModel.saveEditSubject(using: api) }
                        catch { showError = error.localizedDescription }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(BCColor.accent)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}

#endif
