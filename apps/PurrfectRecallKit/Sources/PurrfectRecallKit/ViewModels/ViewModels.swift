import Foundation
import Observation

@Observable
@MainActor
public final class DashboardViewModel {
    public var stats: StatsDTO?
    public var subjects: [SubjectDTO] = []
    public var isLoading = false
    public var loadError: String?

    public init() {}

    public func load(using api: APIClient, gamification: GamificationEngine? = nil) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            async let statsTask = api.fetchStats()
            async let subjectsTask = api.fetchSubjects()
            stats = try await statsTask
            subjects = try await subjectsTask
            if let stats, let gamification {
                gamification.syncFromStats(stats)
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    public func deckStat(for subjectId: Int) -> DeckStatsDTO? {
        stats?.deckStats.first { $0.subjectId == subjectId }
    }
}

@Observable
@MainActor
public final class StudyViewModel {
    public var subjects: [SubjectDTO] = []
    public var selectedDeckId: Int?
    public var queue: [FlashcardDTO] = []
    public var currentIndex = 0
    public var isStudying = false
    public var isRevealed = false
    public var confidence: Double = 50
    public var isSubmitting = false
    public var sessionStartedAt: Date?
    public var sessionId = UUID().uuidString

    public init() {}

    public var currentCard: FlashcardDTO? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    public var progressLabelDesktop: String {
        guard !queue.isEmpty else { return "" }
        return "CARD \(currentIndex + 1) OF \(queue.count)"
    }

    public var progressLabelMobile: String {
        guard !queue.isEmpty else { return "" }
        return "\(currentIndex + 1) / \(queue.count)"
    }

    public var predictedRecall: Int {
        if let card = currentCard, let pct = card.predictedRecallPct {
            return Int(pct.rounded())
        }
        return SM2.predictedRecallPercent(confidence: confidence)
    }

    public func loadSubjects(using api: APIClient) async {
        do {
            subjects = try await api.fetchSubjects()
            if selectedDeckId == nil {
                selectedDeckId = subjects.first?.id
            }
        } catch {
            subjects = []
        }
    }

    public func applyInitialDeck(_ deckId: Int?) {
        if let deckId { selectedDeckId = deckId }
    }

    public static func preferredDeckId(subjects: [SubjectDTO], stats: StatsDTO?) -> Int? {
        if let stats,
           let best = stats.deckStats.max(by: { $0.due < $1.due }),
           best.due > 0 {
            return best.subjectId
        }
        return subjects.first?.id
    }

    public func quickStart(using api: APIClient, gamification: GamificationEngine?, stats: StatsDTO?) async {
        await loadSubjects(using: api)
        selectedDeckId = Self.preferredDeckId(subjects: subjects, stats: stats) ?? selectedDeckId
        await start(using: api, gamification: gamification)
    }

    public func start(using api: APIClient, gamification: GamificationEngine? = nil) async {
        gamification?.resetSession()
        sessionId = UUID().uuidString
        sessionStartedAt = Date()
        guard let deckId = selectedDeckId else { return }
        do {
            var cards = try await api.fetchStudyQueue(subjectId: deckId, limit: 50)
            if cards.isEmpty {
                cards = try await api.fetchFlashcards(subjectId: deckId)
            }
            queue = cards
            currentIndex = 0
            isStudying = !queue.isEmpty
            isRevealed = false
            confidence = 50
        } catch {
            queue = []
            isStudying = false
        }
    }

    public func stop(gamification: GamificationEngine? = nil) {
        gamification?.finishSession()
        queue = []
        currentIndex = 0
        isStudying = false
        isRevealed = false
    }

    public func reveal() {
        isRevealed = true
        sessionStartedAt = Date()
    }

    public func submit(using api: APIClient, gamification: GamificationEngine? = nil) async {
        guard let card = currentCard else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        let quality = SM2.quality(fromConfidencePercent: confidence)
        let responseMs: Int? = {
            guard let sessionStartedAt else { return nil }
            return Int(Date().timeIntervalSince(sessionStartedAt) * 1000)
        }()
        let result = try? await api.reviewFlashcard(
            id: card.id,
            quality: quality,
            confidence: Int(confidence.rounded()),
            responseMs: responseMs,
            sessionId: sessionId
        )
        if let index = queue.firstIndex(where: { $0.id == card.id }),
           let updated = result?.card {
            queue[index] = updated
        }
        if let gamification {
            let stats = try? await api.fetchStats()
            _ = gamification.recordReview(
                quality: quality,
                subjectId: card.subjectId,
                stats: stats
            )
        }
        sessionStartedAt = Date()
        currentIndex += 1
        isRevealed = false
        confidence = 50
        if currentIndex >= queue.count {
            stop(gamification: gamification)
        }
    }
}

@Observable
@MainActor
public final class DecksViewModel {
    public var subjects: [SubjectDTO] = []
    public var cards: [FlashcardDTO] = []
    public var selectedDeckId: Int?
    public var searchText = ""
    public var newDeckName = ""
    public var newDeckDescription = ""
    public var newQuestion = ""
    public var newAnswer = ""
    public var editingCard: FlashcardDTO?
    public var editQuestion = ""
    public var editAnswer = ""
    public var editingSubject: SubjectDTO?
    public var editSubjectName = ""
    public var editSubjectDescription = ""

    public init() {}

    public var filteredSubjects: [SubjectDTO] {
        guard !searchText.isEmpty else { return subjects }
        return subjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || ($0.description ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    public var filteredCards: [FlashcardDTO] {
        guard !searchText.isEmpty else { return cards }
        return cards.filter {
            $0.question.localizedCaseInsensitiveContains(searchText)
                || $0.answer.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var selectedSubject: SubjectDTO? {
        subjects.first { $0.id == selectedDeckId }
    }

    public func load(using api: APIClient) async {
        do {
            subjects = try await api.fetchSubjects()
            if selectedDeckId == nil {
                selectedDeckId = subjects.first?.id
            }
            await loadCards(using: api)
        } catch {
            subjects = []
            cards = []
        }
    }

    public func loadCards(using api: APIClient) async {
        guard let deckId = selectedDeckId else {
            cards = []
            return
        }
        do {
            cards = try await api.fetchFlashcards(subjectId: deckId)
        } catch {
            cards = []
        }
    }

    public func selectDeck(_ id: Int) {
        selectedDeckId = id
    }

    public func createDeck(using api: APIClient) async throws {
        let subject = try await api.createSubject(
            SubjectCreateRequest(name: newDeckName, description: newDeckDescription.isEmpty ? nil : newDeckDescription)
        )
        newDeckName = ""
        newDeckDescription = ""
        subjects.append(subject)
        selectedDeckId = subject.id
        await loadCards(using: api)
    }

    public func createCard(using api: APIClient) async throws {
        guard let deckId = selectedDeckId else { return }
        _ = try await api.createFlashcard(
            FlashcardCreateRequest(subjectId: deckId, question: newQuestion, answer: newAnswer)
        )
        newQuestion = ""
        newAnswer = ""
        await loadCards(using: api)
    }

    public func beginEditCard(_ card: FlashcardDTO) {
        editingCard = card
        editQuestion = card.question
        editAnswer = card.answer
    }

    public func saveEditCard(using api: APIClient) async throws {
        guard let card = editingCard else { return }
        _ = try await api.updateFlashcard(
            id: card.id,
            FlashcardUpdateRequest(question: editQuestion, answer: editAnswer)
        )
        editingCard = nil
        await loadCards(using: api)
    }

    public func deleteCard(_ card: FlashcardDTO, using api: APIClient) async throws {
        try await api.deleteFlashcard(id: card.id)
        await loadCards(using: api)
    }

    public func beginEditSubject(_ subject: SubjectDTO) {
        editingSubject = subject
        editSubjectName = subject.name
        editSubjectDescription = subject.description ?? ""
    }

    public func saveEditSubject(using api: APIClient) async throws {
        guard let subject = editingSubject else { return }
        _ = try await api.updateSubject(
            id: subject.id,
            SubjectCreateRequest(name: editSubjectName, description: editSubjectDescription.isEmpty ? nil : editSubjectDescription)
        )
        editingSubject = nil
        await load(using: api)
    }

    public func deleteSubject(_ subject: SubjectDTO, using api: APIClient) async throws {
        try await api.deleteSubject(id: subject.id)
        if selectedDeckId == subject.id { selectedDeckId = nil }
        await load(using: api)
    }
}

@Observable
@MainActor
public final class StatsViewModel {
    public var stats: StatsDTO?
    public var isLoading = false

    public init() {}

    public func load(using api: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            stats = try await api.fetchStats()
        } catch {
            stats = nil
        }
    }

    public var maxReviewCount: Int {
        max(stats?.reviewsLast7Days.map(\.count).max() ?? 1, 1)
    }
}
