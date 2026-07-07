import Foundation

public struct Achievement: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String
    public let xpReward: Int

    public init(id: String, title: String, detail: String, symbol: String, xpReward: Int = 25) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.xpReward = xpReward
    }
}

public enum AchievementCatalog {
    public static let all: [Achievement] = [
        // Getting started
        Achievement(id: "first_review", title: "First Step", detail: "Complete your first card review.", symbol: "figure.walk"),
        Achievement(id: "session_10", title: "Study Sprint", detail: "Review 10 cards in one session.", symbol: "hare.fill"),
        Achievement(id: "marathon_30", title: "Marathon Mind", detail: "Review 30 cards in one session.", symbol: "figure.run.circle", xpReward: 50),

        // Combos
        Achievement(id: "combo_3", title: "On Fire", detail: "Hit a 3-card recall combo.", symbol: "flame"),
        Achievement(id: "combo_5", title: "Heating Up", detail: "Hit a 5-card recall combo.", symbol: "flame.fill"),
        Achievement(id: "combo_10", title: "Unstoppable", detail: "Chain 10 strong recalls in a row.", symbol: "bolt.fill"),
        Achievement(id: "combo_20", title: "Lightning Brain", detail: "Chain 20 strong recalls in a row.", symbol: "bolt.circle.fill", xpReward: 60),

        // Sessions & perfection
        Achievement(id: "perfect_session", title: "Flawless Run", detail: "Finish a session with every recall rated strong.", symbol: "star.fill", xpReward: 50),
        Achievement(id: "sessions_25", title: "Regular", detail: "Complete 25 study sessions.", symbol: "repeat.circle", xpReward: 40),

        // Streaks
        Achievement(id: "streak_3", title: "Hat Trick", detail: "Study three days in a row.", symbol: "calendar"),
        Achievement(id: "streak_7", title: "Week Warrior", detail: "Keep a 7-day study streak.", symbol: "calendar.badge.clock", xpReward: 40),
        Achievement(id: "streak_14", title: "Fortnight Focus", detail: "Keep a 14-day study streak.", symbol: "calendar.circle", xpReward: 55),
        Achievement(id: "streak_30", title: "Monthly Master", detail: "Keep a 30-day study streak.", symbol: "calendar.badge.checkmark", xpReward: 80),

        // Lifetime reviews
        Achievement(id: "reviews_50", title: "Fifty Club", detail: "Complete 50 lifetime reviews.", symbol: "50.circle.fill"),
        Achievement(id: "reviews_100", title: "Century", detail: "Complete 100 lifetime reviews.", symbol: "100.circle.fill", xpReward: 75),
        Achievement(id: "reviews_250", title: "Review Machine", detail: "Complete 250 lifetime reviews.", symbol: "infinity.circle", xpReward: 90),
        Achievement(id: "reviews_500", title: "Half Grand", detail: "Complete 500 lifetime reviews.", symbol: "500.circle", xpReward: 120),

        // Levels
        Achievement(id: "level_5", title: "Level 5", detail: "Reach player level 5.", symbol: "5.circle"),
        Achievement(id: "level_10", title: "Level 10", detail: "Reach player level 10.", symbol: "rosette"),
        Achievement(id: "level_20", title: "Level 20", detail: "Reach player level 20.", symbol: "crown", xpReward: 60),
        Achievement(id: "level_50", title: "Level 50", detail: "Reach player level 50.", symbol: "crown.fill", xpReward: 100),

        // Cards learned
        Achievement(id: "cards_25", title: "Card Collector", detail: "Learn 25 cards across all decks.", symbol: "rectangle.stack.fill"),
        Achievement(id: "cards_100", title: "Library Builder", detail: "Learn 100 cards across all decks.", symbol: "books.vertical.fill", xpReward: 55),
        Achievement(id: "cards_500", title: "Walking Encyclopedia", detail: "Learn 500 cards across all decks.", symbol: "building.columns.fill", xpReward: 100),

        // Daily challenges
        Achievement(id: "daily_first", title: "Daily Done", detail: "Complete all daily challenges in one day.", symbol: "sun.max.fill", xpReward: 40),
        Achievement(id: "daily_streak_7", title: "Challenge Week", detail: "Complete all dailies 7 days in a row.", symbol: "sun.horizon.fill", xpReward: 70),
        Achievement(id: "daily_streak_30", title: "Challenge Champion", detail: "Complete all dailies 30 days in a row.", symbol: "sparkles", xpReward: 120),

        // Time & habits
        Achievement(id: "early_bird", title: "Early Bird", detail: "Study before 8 AM.", symbol: "sunrise.fill"),
        Achievement(id: "night_owl", title: "Night Owl", detail: "Study after 10 PM.", symbol: "moon.stars.fill"),

        // XP milestones
        Achievement(id: "xp_1000", title: "XP Hunter", detail: "Earn 1,000 total XP.", symbol: "sparkle", xpReward: 30),
        Achievement(id: "xp_5000", title: "XP Titan", detail: "Earn 5,000 total XP.", symbol: "star.circle.fill", xpReward: 75),

        // Session records
        Achievement(id: "session_xp_100", title: "High Scorer", detail: "Earn 100+ XP in a single session.", symbol: "chart.line.uptrend.xyaxis", xpReward: 45),
    ]

    public static func byID(_ id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}
