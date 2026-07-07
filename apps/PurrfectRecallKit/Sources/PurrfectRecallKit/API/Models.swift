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
    public let example: String?
    public let ipa: String?
    public let imagePath: String?
    public let audioWord: String?
    public let audioMeaning: String?
    public let audioExample: String?
    public let createdAt: Date
    public let lastReviewed: Date?
    public let interval: Int
    public let easeFactor: Double
    public let repetition: Int
    public let dueDate: Date
    public let memoryState: Int?
    public let memoryStability: Double?
    public let memoryDifficulty: Double?
    public let predictedRecallPct: Double?

    enum CodingKeys: String, CodingKey {
        case id, question, answer, example, ipa, interval, repetition
        case subjectId = "subject_id"
        case imagePath = "image_path"
        case audioWord = "audio_word"
        case audioMeaning = "audio_meaning"
        case audioExample = "audio_example"
        case createdAt = "created_at"
        case lastReviewed = "last_reviewed"
        case easeFactor = "ease_factor"
        case dueDate = "due_date"
        case memoryState = "memory_state"
        case memoryStability = "memory_stability"
        case memoryDifficulty = "memory_difficulty"
        case predictedRecallPct = "predicted_recall_pct"
    }

    public var hasMedia: Bool {
        imagePath != nil
            || audioWord != nil
            || audioMeaning != nil
            || audioExample != nil
            || (example?.isEmpty == false)
            || (ipa?.isEmpty == false)
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

public struct DeckInsightDTO: Codable, Identifiable, Sendable {
    public var id: Int { subjectId }
    public let subjectId: Int
    public let name: String
    public let retentionPct: Double
    public let lapseRatePct: Double?
    public let avgDifficulty: Double?
    public let reviewCount: Int
    public let needsAttention: Bool
    public let trend: String
    public let studyTip: String?

    enum CodingKeys: String, CodingKey {
        case name, trend
        case subjectId = "subject_id"
        case retentionPct = "retention_pct"
        case lapseRatePct = "lapse_rate_pct"
        case avgDifficulty = "avg_difficulty"
        case reviewCount = "review_count"
        case needsAttention = "needs_attention"
        case studyTip = "study_tip"
    }

    public var trendLabel: String {
        switch trend {
        case "improving": "Improving"
        case "declining": "Declining"
        case "stable": "Stable"
        default: "Not enough data"
        }
    }
}

public struct StatsDTO: Codable, Sendable {
    public let streakDays: Int
    public let dueToday: Int
    public let cardsLearned: Int
    public let retentionPct: Double
    public let avgEase: Double
    public let recommendedDailyReviews: Int
    public let reviewsLast7Days: [ReviewDayCountDTO]
    public let deckStats: [DeckStatsDTO]
    public let deckInsights: [DeckInsightDTO]
    public let weakestDeckId: Int?
    public let weakestDeckName: String?
    public let improvingDeckId: Int?
    public let improvingDeckName: String?
    public let globalStudyTip: String?

    enum CodingKeys: String, CodingKey {
        case streakDays = "streak_days"
        case dueToday = "due_today"
        case cardsLearned = "cards_learned"
        case retentionPct = "retention_pct"
        case avgEase = "avg_ease"
        case recommendedDailyReviews = "recommended_daily_reviews"
        case reviewsLast7Days = "reviews_last_7_days"
        case deckStats = "deck_stats"
        case deckInsights = "deck_insights"
        case weakestDeckId = "weakest_deck_id"
        case weakestDeckName = "weakest_deck_name"
        case improvingDeckId = "improving_deck_id"
        case improvingDeckName = "improving_deck_name"
        case globalStudyTip = "global_study_tip"
    }
}

public struct ForecastPointDTO: Codable, Sendable {
    public let date: String
    public let expectedRetentionPct: Double?
    public let studiedCardCount: Int

    enum CodingKeys: String, CodingKey {
        case date
        case expectedRetentionPct = "expected_retention_pct"
        case studiedCardCount = "studied_card_count"
    }
}

public struct ForecastDTO: Codable, Sendable {
    public let days: Int
    public let points: [ForecastPointDTO]
}

public struct DeckCalibrationDTO: Codable, Identifiable, Sendable {
    public var id: Int { subjectId }
    public let subjectId: Int
    public let subjectName: String
    public let reviewCount: Int
    public let ready: Bool
    public let avgConfidence: Double?
    public let actualRecallPct: Double?
    public let overconfidencePct: Double?
    public let suggestedOffsetPct: Double?
    public let hint: String?

    enum CodingKeys: String, CodingKey {
        case ready, hint
        case subjectId = "subject_id"
        case subjectName = "subject_name"
        case reviewCount = "review_count"
        case avgConfidence = "avg_confidence"
        case actualRecallPct = "actual_recall_pct"
        case overconfidencePct = "overconfidence_pct"
        case suggestedOffsetPct = "suggested_offset_pct"
    }
}

public struct CalibrationDTO: Codable, Sendable {
    public let minReviewsRequired: Int
    public let totalReviewsWithConfidence: Int
    public let globalReady: Bool
    public let globalOverconfidencePct: Double?
    public let globalSuggestedOffsetPct: Double?
    public let globalHint: String?
    public let deckHint: String?
    public let decks: [DeckCalibrationDTO]

    enum CodingKeys: String, CodingKey {
        case decks
        case minReviewsRequired = "min_reviews_required"
        case totalReviewsWithConfidence = "total_reviews_with_confidence"
        case globalReady = "global_ready"
        case globalOverconfidencePct = "global_overconfidence_pct"
        case globalSuggestedOffsetPct = "global_suggested_offset_pct"
        case globalHint = "global_hint"
        case deckHint = "deck_hint"
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
    public let example: String?
    public let ipa: String?
    public let imagePath: String?
    public let audioWord: String?
    public let audioMeaning: String?
    public let audioExample: String?

    enum CodingKeys: String, CodingKey {
        case question, answer, example, ipa
        case subjectId = "subject_id"
        case imagePath = "image_path"
        case audioWord = "audio_word"
        case audioMeaning = "audio_meaning"
        case audioExample = "audio_example"
    }

    public init(
        subjectId: Int,
        question: String,
        answer: String,
        example: String? = nil,
        ipa: String? = nil,
        imagePath: String? = nil,
        audioWord: String? = nil,
        audioMeaning: String? = nil,
        audioExample: String? = nil
    ) {
        self.subjectId = subjectId
        self.question = question
        self.answer = answer
        self.example = example
        self.ipa = ipa
        self.imagePath = imagePath
        self.audioWord = audioWord
        self.audioMeaning = audioMeaning
        self.audioExample = audioExample
    }
}

public struct FlashcardUpdateRequest: Encodable, Sendable {
    public let subjectId: Int?
    public let question: String?
    public let answer: String?
    public let example: String?
    public let ipa: String?
    public let imagePath: String?
    public let audioWord: String?
    public let audioMeaning: String?
    public let audioExample: String?

    enum CodingKeys: String, CodingKey {
        case question, answer, example, ipa
        case subjectId = "subject_id"
        case imagePath = "image_path"
        case audioWord = "audio_word"
        case audioMeaning = "audio_meaning"
        case audioExample = "audio_example"
    }

    public init(
        subjectId: Int? = nil,
        question: String? = nil,
        answer: String? = nil,
        example: String? = nil,
        ipa: String? = nil,
        imagePath: String? = nil,
        audioWord: String? = nil,
        audioMeaning: String? = nil,
        audioExample: String? = nil
    ) {
        self.subjectId = subjectId
        self.question = question
        self.answer = answer
        self.example = example
        self.ipa = ipa
        self.imagePath = imagePath
        self.audioWord = audioWord
        self.audioMeaning = audioMeaning
        self.audioExample = audioExample
    }
}

public struct ReviewRequest: Encodable, Sendable {
    public let quality: Int
    public let confidence: Int?
    public let responseMs: Int?
    public let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case quality, confidence
        case responseMs = "response_ms"
        case sessionId = "session_id"
    }

    public init(quality: Int, confidence: Int? = nil, responseMs: Int? = nil, sessionId: String? = nil) {
        self.quality = quality
        self.confidence = confidence
        self.responseMs = responseMs
        self.sessionId = sessionId
    }
}

public struct FlashcardReviewResultDTO: Codable, Sendable {
    public let card: FlashcardDTO
    public let predictedRecallBeforePct: Double?
    public let predictedRecallAfterPct: Double?

    enum CodingKeys: String, CodingKey {
        case card
        case predictedRecallBeforePct = "predicted_recall_before_pct"
        case predictedRecallAfterPct = "predicted_recall_after_pct"
    }
}
