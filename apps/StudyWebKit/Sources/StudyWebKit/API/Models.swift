import Foundation

public struct SubjectDTO: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let description: String?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case createdAt = "created_at"
    }
}

public struct FlashcardDTO: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let subjectId: Int
    public let question: String
    public let answer: String
    public let createdAt: Date
    public let lastReviewed: Date?
    public let interval: Int
    public let easeFactor: Double
    public let repetition: Int
    public let dueDate: Date

    enum CodingKeys: String, CodingKey {
        case id, question, answer, interval, repetition
        case subjectId = "subject_id"
        case createdAt = "created_at"
        case lastReviewed = "last_reviewed"
        case easeFactor = "ease_factor"
        case dueDate = "due_date"
    }
}

public struct ReviewDayCountDTO: Codable, Sendable {
    public let date: String
    public let count: Int
}

public struct DeckStatsDTO: Codable, Identifiable, Sendable {
    public var id: Int { subjectId }
    public let subjectId: Int
    public let name: String
    public let total: Int
    public let mastered: Int
    public let due: Int
    public let retentionPct: Double

    enum CodingKeys: String, CodingKey {
        case name, total, mastered, due
        case subjectId = "subject_id"
        case retentionPct = "retention_pct"
    }
}

public struct StatsDTO: Codable, Sendable {
    public let streakDays: Int
    public let dueToday: Int
    public let cardsLearned: Int
    public let retentionPct: Double
    public let avgEase: Double
    public let reviewsLast7Days: [ReviewDayCountDTO]
    public let deckStats: [DeckStatsDTO]

    enum CodingKeys: String, CodingKey {
        case streakDays = "streak_days"
        case dueToday = "due_today"
        case cardsLearned = "cards_learned"
        case retentionPct = "retention_pct"
        case avgEase = "avg_ease"
        case reviewsLast7Days = "reviews_last_7_days"
        case deckStats = "deck_stats"
    }
}

public struct SubjectCreateRequest: Encodable, Sendable {
    public let name: String
    public let description: String?

    public init(name: String, description: String?) {
        self.name = name
        self.description = description
    }
}

public struct FlashcardCreateRequest: Encodable, Sendable {
    public let subjectId: Int
    public let question: String
    public let answer: String

    enum CodingKeys: String, CodingKey {
        case question, answer
        case subjectId = "subject_id"
    }

    public init(subjectId: Int, question: String, answer: String) {
        self.subjectId = subjectId
        self.question = question
        self.answer = answer
    }
}

public struct FlashcardUpdateRequest: Encodable, Sendable {
    public let subjectId: Int?
    public let question: String?
    public let answer: String?

    enum CodingKeys: String, CodingKey {
        case question, answer
        case subjectId = "subject_id"
    }

    public init(subjectId: Int? = nil, question: String? = nil, answer: String? = nil) {
        self.subjectId = subjectId
        self.question = question
        self.answer = answer
    }
}

public struct ReviewRequest: Encodable, Sendable {
    public let quality: Int

    public init(quality: Int) {
        self.quality = quality
    }
}
