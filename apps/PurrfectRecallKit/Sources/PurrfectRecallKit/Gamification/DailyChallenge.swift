import Foundation

public struct DailyDayState: Codable, Sendable, Equatable {
    public var dateKey: String = ""
    public var reviewCount: Int = 0
    public var strongReviewCount: Int = 0
    public var bestCombo: Int = 0
    public var sessionsCompleted: Int = 0
    public var deckIds: [Int] = []
    public var studiedBeforeHour: Bool = false
    public var studiedBeforeEight: Bool = false
    public var studiedAfterHour: Bool = false
    public var claimedChallengeIDs: Set<String> = []
    public var allCompleteRecorded: Bool = false

    public init() {}

    public init(dateKey: String) {
        self.dateKey = dateKey
    }
}

public struct DailyChallenge: Identifiable, Hashable, Sendable {
    public enum Metric: Hashable, Sendable {
        case reviews(Int)
        case combo(Int)
        case sessions(Int)
        case strongReviews(Int)
        case decksStudied(Int)
        case studiedBeforeHour(Int)
    }

    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String
    public let metric: Metric
    public let xpReward: Int

    public var target: Int {
        switch metric {
        case .reviews(let n), .combo(let n), .sessions(let n),
             .strongReviews(let n), .decksStudied(let n):
            return n
        case .studiedBeforeHour:
            return 1
        }
    }

    public init(
        id: String,
        title: String,
        detail: String,
        symbol: String,
        metric: Metric,
        xpReward: Int = 30
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.metric = metric
        self.xpReward = xpReward
    }

    public func currentValue(in day: DailyDayState) -> Int {
        switch metric {
        case .reviews:
            return day.reviewCount
        case .combo:
            return day.bestCombo
        case .sessions:
            return day.sessionsCompleted
        case .strongReviews:
            return day.strongReviewCount
        case .decksStudied:
            return day.deckIds.count
        case .studiedBeforeHour:
            return day.studiedBeforeHour && day.reviewCount > 0 ? 1 : 0
        }
    }

    public func isComplete(in day: DailyDayState) -> Bool {
        currentValue(in: day) >= target
    }
}

public struct DailyChallengeStatus: Identifiable, Sendable {
    public var id: String { challenge.id }
    public let challenge: DailyChallenge
    public let current: Int
    public let target: Int
    public let isComplete: Bool
    public let isClaimed: Bool

    public var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(current) / Double(target))
    }
}

public enum DailyChallengeCatalog {
    private static let templates: [DailyChallenge] = [
        DailyChallenge(
            id: "daily_reviews_10",
            title: "Quick Ten",
            detail: "Review 10 cards today.",
            symbol: "10.circle",
            metric: .reviews(10)
        ),
        DailyChallenge(
            id: "daily_reviews_20",
            title: "Twenty Pack",
            detail: "Review 20 cards today.",
            symbol: "20.circle",
            metric: .reviews(20),
            xpReward: 45
        ),
        DailyChallenge(
            id: "daily_reviews_30",
            title: "Card Marathon",
            detail: "Review 30 cards today.",
            symbol: "figure.run",
            metric: .reviews(30),
            xpReward: 60
        ),
        DailyChallenge(
            id: "daily_combo_3",
            title: "Combo Starter",
            detail: "Hit a 3-card recall combo.",
            symbol: "flame",
            metric: .combo(3)
        ),
        DailyChallenge(
            id: "daily_combo_5",
            title: "Combo Crusher",
            detail: "Hit a 5-card recall combo.",
            symbol: "bolt.fill",
            metric: .combo(5),
            xpReward: 40
        ),
        DailyChallenge(
            id: "daily_combo_7",
            title: "Combo Legend",
            detail: "Hit a 7-card recall combo.",
            symbol: "bolt.circle.fill",
            metric: .combo(7),
            xpReward: 55
        ),
        DailyChallenge(
            id: "daily_session_1",
            title: "Show Up",
            detail: "Finish one study session.",
            symbol: "checkmark.circle",
            metric: .sessions(1)
        ),
        DailyChallenge(
            id: "daily_session_2",
            title: "Double Session",
            detail: "Finish two study sessions.",
            symbol: "checkmark.circle.fill",
            metric: .sessions(2),
            xpReward: 50
        ),
        DailyChallenge(
            id: "daily_strong_8",
            title: "Sharp Mind",
            detail: "Get 8 strong recalls today.",
            symbol: "brain.head.profile",
            metric: .strongReviews(8)
        ),
        DailyChallenge(
            id: "daily_decks_2",
            title: "Deck Hopper",
            detail: "Study cards from 2 decks.",
            symbol: "rectangle.stack",
            metric: .decksStudied(2),
            xpReward: 35
        ),
        DailyChallenge(
            id: "daily_decks_3",
            title: "Deck Explorer",
            detail: "Study cards from 3 decks.",
            symbol: "map",
            metric: .decksStudied(3),
            xpReward: 50
        ),
        DailyChallenge(
            id: "daily_early_bird",
            title: "Early Bird",
            detail: "Study before 10 AM.",
            symbol: "sunrise.fill",
            metric: .studiedBeforeHour(10),
            xpReward: 35
        ),
    ]

    public static func todayKey(from date: Date = .now) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    public static func challenges(for date: Date = .now) -> [DailyChallenge] {
        let key = todayKey(from: date)
        let ranked = templates.sorted { lhs, rhs in
            rank(key: key, challengeID: lhs.id) < rank(key: key, challengeID: rhs.id)
        }
        return Array(ranked.prefix(3))
    }

    private static func rank(key: String, challengeID: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in "\(key)|\(challengeID)".utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }
}
