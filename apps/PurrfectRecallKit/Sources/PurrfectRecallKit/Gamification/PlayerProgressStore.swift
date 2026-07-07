import Foundation

public struct PlayerProgressData: Codable, Sendable {
    public var totalXP: Int = 0
    public var lifetimeReviews: Int = 0
    public var bestCombo: Int = 0
    public var unlockedAchievementIDs: Set<String> = []
    public var highScoreSessionXP: Int = 0
    public var daily: DailyDayState = DailyDayState()
    public var dailyAllCompleteDays: Int = 0
    public var dailyChallengeStreak: Int = 0
    public var lastDailyAllCompleteDate: String?
    public var lifetimeSessionsCompleted: Int = 0
    public var maxSessionReviews: Int = 0

    public init() {}
}

@MainActor
public enum PlayerProgressStore {
    private static let key = "purrfectrecall.player.progress"
    private static let legacyKey = "studyweb.player.progress"

    public static func load() -> PlayerProgressData {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(PlayerProgressData.self, from: data) {
            return decoded
        }
        if let data = UserDefaults.standard.data(forKey: legacyKey),
           let decoded = try? JSONDecoder().decode(PlayerProgressData.self, from: data) {
            save(decoded)
            return decoded
        }
        return PlayerProgressData()
    }

    public static func save(_ progress: PlayerProgressData) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
