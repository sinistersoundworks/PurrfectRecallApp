import Foundation

public struct ReviewCelebration: Identifiable, Sendable {
    public let id = UUID()
    public let xpGained: Int
    public let combo: Int
    public let leveledUp: Bool
    public let newLevel: Int
    public let unlockedAchievements: [Achievement]
    public let completedDailyChallenges: [DailyChallenge]
    public let headline: String

    public init(
        xpGained: Int,
        combo: Int,
        leveledUp: Bool,
        newLevel: Int,
        unlockedAchievements: [Achievement],
        completedDailyChallenges: [DailyChallenge] = [],
        headline: String
    ) {
        self.xpGained = xpGained
        self.combo = combo
        self.leveledUp = leveledUp
        self.newLevel = newLevel
        self.unlockedAchievements = unlockedAchievements
        self.completedDailyChallenges = completedDailyChallenges
        self.headline = headline
    }
}

@MainActor
@Observable
public final class GamificationEngine {
    public private(set) var progress: PlayerProgressData
    public var sessionCombo = 0
    public var sessionReviewCount = 0
    public var sessionStrongCount = 0
    public var sessionXPGained = 0
    public var activeCelebration: ReviewCelebration?

    private let gameCenter: GameCenterService

    public init(gameCenter: GameCenterService) {
        self.gameCenter = gameCenter
        self.progress = PlayerProgressStore.load()
        ensureDailyReset()
    }

    public var level: Int { XPLevel.level(forTotalXP: progress.totalXP) }
    public var levelTitle: String { XPLevel.title(for: level) }

    public var dailyChallenges: [DailyChallengeStatus] {
        ensureDailyReset()
        return DailyChallengeCatalog.challenges().map { challenge in
            DailyChallengeStatus(
                challenge: challenge,
                current: challenge.currentValue(in: progress.daily),
                target: challenge.target,
                isComplete: challenge.isComplete(in: progress.daily),
                isClaimed: progress.daily.claimedChallengeIDs.contains(challenge.id)
            )
        }
    }

    public var dailyCompletedCount: Int {
        dailyChallenges.filter(\.isComplete).count
    }

    public var dailyAllComplete: Bool {
        let challenges = dailyChallenges
        return !challenges.isEmpty && challenges.allSatisfy(\.isComplete)
    }

    public func resetSession() {
        sessionCombo = 0
        sessionReviewCount = 0
        sessionStrongCount = 0
        sessionXPGained = 0
    }

    public func recordReview(quality: Int, subjectId: Int?, stats: StatsDTO?) -> ReviewCelebration {
        ensureDailyReset()

        let strong = quality >= 3
        if strong {
            sessionCombo += 1
            sessionStrongCount += 1
        } else {
            sessionCombo = 0
        }
        sessionReviewCount += 1
        updateDailyForReview(quality: quality, subjectId: subjectId)

        var xp = max(5, quality * 12)
        if sessionCombo >= 3 {
            xp += min(sessionCombo * 4, 40)
        }
        if quality >= 5 {
            xp += 10
        }

        let previousLevel = level
        progress.totalXP += xp
        sessionXPGained += xp
        progress.lifetimeReviews += 1
        progress.bestCombo = max(progress.bestCombo, sessionCombo)
        progress.highScoreSessionXP = max(progress.highScoreSessionXP, sessionXPGained)

        var unlocked = checkAchievements(stats: stats, includeDaily: false)
        let dailyCompleted = claimNewlyCompletedDailyChallenges()
        for challenge in dailyCompleted {
            progress.totalXP += challenge.xpReward
        }
        unlocked.append(contentsOf: recordDailyAllCompleteIfNeeded())

        let newLevel = level
        let leveledUp = newLevel > previousLevel
        if leveledUp {
            unlocked.append(contentsOf: checkAchievements(stats: stats, includeDaily: false))
        }

        PlayerProgressStore.save(progress)
        syncLeaderboards(stats: stats)

        let totalXP = xp + dailyCompleted.reduce(0) { $0 + $1.xpReward }
        let headline = celebrationHeadline(
            quality: quality,
            combo: sessionCombo,
            leveledUp: leveledUp,
            dailyCompleted: !dailyCompleted.isEmpty
        )
        let celebration = ReviewCelebration(
            xpGained: totalXP,
            combo: sessionCombo,
            leveledUp: leveledUp,
            newLevel: newLevel,
            unlockedAchievements: dedupeAchievements(unlocked),
            completedDailyChallenges: dailyCompleted,
            headline: headline
        )
        activeCelebration = celebration
        return celebration
    }

    public func finishSession() {
        ensureDailyReset()
        guard sessionReviewCount > 0 else {
            resetSession()
            return
        }

        progress.daily.sessionsCompleted += 1
        progress.lifetimeSessionsCompleted += 1
        progress.maxSessionReviews = max(progress.maxSessionReviews, sessionReviewCount)

        var unlocked: [Achievement] = []
        if sessionReviewCount > 0, sessionStrongCount == sessionReviewCount, sessionReviewCount >= 3 {
            unlocked.append(contentsOf: unlock("perfect_session"))
        }
        unlocked.append(contentsOf: checkAchievements(stats: nil, includeDaily: true))
        let dailyCompleted = claimNewlyCompletedDailyChallenges()
        for challenge in dailyCompleted {
            progress.totalXP += challenge.xpReward
        }
        unlocked.append(contentsOf: recordDailyAllCompleteIfNeeded())

        if !unlocked.isEmpty || !dailyCompleted.isEmpty {
            let bonusXP = dailyCompleted.reduce(0) { $0 + $1.xpReward }
                + unlocked.reduce(0) { $0 + $1.xpReward }
            activeCelebration = ReviewCelebration(
                xpGained: bonusXP,
                combo: sessionCombo,
                leveledUp: false,
                newLevel: level,
                unlockedAchievements: dedupeAchievements(unlocked),
                completedDailyChallenges: dailyCompleted,
                headline: unlocked.isEmpty ? "Session complete!" : "Session rewards!"
            )
        }

        PlayerProgressStore.save(progress)
        resetSession()
    }

    public func syncFromStats(_ stats: StatsDTO) {
        ensureDailyReset()
        _ = checkAchievements(stats: stats, includeDaily: true)
        PlayerProgressStore.save(progress)
        syncLeaderboards(stats: stats)
    }

    public func dismissCelebration() {
        activeCelebration = nil
    }

    public func isUnlocked(_ achievementID: String) -> Bool {
        progress.unlockedAchievementIDs.contains(achievementID)
    }

    public var unlockedCount: Int { progress.unlockedAchievementIDs.count }

    // MARK: - Daily

    private func ensureDailyReset() {
        let today = DailyChallengeCatalog.todayKey()
        guard progress.daily.dateKey != today else { return }
        progress.daily = DailyDayState(dateKey: today)
        PlayerProgressStore.save(progress)
    }

    private func updateDailyForReview(quality: Int, subjectId: Int?) {
        let hour = Calendar.current.component(.hour, from: .now)
        if progress.daily.reviewCount == 0 {
            if hour < 8 { progress.daily.studiedBeforeEight = true }
            if hour < 10 { progress.daily.studiedBeforeHour = true }
        }
        if hour >= 22 {
            progress.daily.studiedAfterHour = true
        }

        progress.daily.reviewCount += 1
        if quality >= 3 {
            progress.daily.strongReviewCount += 1
        }
        progress.daily.bestCombo = max(progress.daily.bestCombo, sessionCombo)

        if let subjectId, !progress.daily.deckIds.contains(subjectId) {
            progress.daily.deckIds.append(subjectId)
        }
    }

    private func claimNewlyCompletedDailyChallenges() -> [DailyChallenge] {
        var claimed: [DailyChallenge] = []
        for status in dailyChallenges where status.isComplete && !status.isClaimed {
            progress.daily.claimedChallengeIDs.insert(status.challenge.id)
            claimed.append(status.challenge)
        }
        return claimed
    }

    private func recordDailyAllCompleteIfNeeded() -> [Achievement] {
        guard dailyAllComplete, !progress.daily.allCompleteRecorded else { return [] }
        progress.daily.allCompleteRecorded = true
        progress.dailyAllCompleteDays += 1

        let today = DailyChallengeCatalog.todayKey()
        if let last = progress.lastDailyAllCompleteDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = .current
            if let lastDate = formatter.date(from: last),
               let next = Calendar.current.date(byAdding: .day, value: 1, to: lastDate),
               DailyChallengeCatalog.todayKey(from: next) == today {
                progress.dailyChallengeStreak += 1
            } else if last != today {
                progress.dailyChallengeStreak = 1
            }
        } else {
            progress.dailyChallengeStreak = 1
        }
        progress.lastDailyAllCompleteDate = today

        progress.totalXP += 25
        return unlock("daily_first")
            + unlock("daily_streak_7", when: progress.dailyChallengeStreak >= 7)
            + unlock("daily_streak_30", when: progress.dailyChallengeStreak >= 30)
    }

    // MARK: - Achievements

    @discardableResult
    private func unlock(_ id: String, when condition: Bool = true) -> [Achievement] {
        guard condition else { return [] }
        guard !progress.unlockedAchievementIDs.contains(id),
              let achievement = AchievementCatalog.byID(id)
        else { return [] }
        progress.unlockedAchievementIDs.insert(id)
        progress.totalXP += achievement.xpReward
        gameCenter.unlockAchievement(id)
        return [achievement]
    }

    private func checkAchievements(stats: StatsDTO?, includeDaily: Bool) -> [Achievement] {
        var unlocked: [Achievement] = []
        func u(_ id: String, when condition: Bool = true) {
            unlocked.append(contentsOf: unlock(id, when: condition))
        }

        u("first_review", when: progress.lifetimeReviews >= 1)
        u("combo_3", when: progress.bestCombo >= 3)
        u("combo_5", when: progress.bestCombo >= 5)
        u("combo_10", when: progress.bestCombo >= 10)
        u("combo_20", when: progress.bestCombo >= 20)
        u("session_10", when: sessionReviewCount >= 10 || progress.maxSessionReviews >= 10)
        u("marathon_30", when: sessionReviewCount >= 30 || progress.maxSessionReviews >= 30)
        u("sessions_25", when: progress.lifetimeSessionsCompleted >= 25)
        u("reviews_50", when: progress.lifetimeReviews >= 50)
        u("reviews_100", when: progress.lifetimeReviews >= 100)
        u("reviews_250", when: progress.lifetimeReviews >= 250)
        u("reviews_500", when: progress.lifetimeReviews >= 500)
        u("level_5", when: level >= 5)
        u("level_10", when: level >= 10)
        u("level_20", when: level >= 20)
        u("level_50", when: level >= 50)
        u("xp_1000", when: progress.totalXP >= 1000)
        u("xp_5000", when: progress.totalXP >= 5000)
        u("session_xp_100", when: progress.highScoreSessionXP >= 100)
        u("early_bird", when: progress.daily.studiedBeforeEight)
        u("night_owl", when: progress.daily.studiedAfterHour)

        if let stats {
            u("streak_3", when: stats.streakDays >= 3)
            u("streak_7", when: stats.streakDays >= 7)
            u("streak_14", when: stats.streakDays >= 14)
            u("streak_30", when: stats.streakDays >= 30)
            u("cards_25", when: stats.cardsLearned >= 25)
            u("cards_100", when: stats.cardsLearned >= 100)
            u("cards_500", when: stats.cardsLearned >= 500)
        }

        if includeDaily {
            u("daily_first", when: progress.dailyAllCompleteDays >= 1)
            u("daily_streak_7", when: progress.dailyChallengeStreak >= 7)
            u("daily_streak_30", when: progress.dailyChallengeStreak >= 30)
        }

        return unlocked
    }

    private func dedupeAchievements(_ achievements: [Achievement]) -> [Achievement] {
        var seen = Set<String>()
        return achievements.filter { seen.insert($0.id).inserted }
    }

    private func syncLeaderboards(stats: StatsDTO?) {
        gameCenter.submitScore(progress.totalXP, leaderboard: .totalXP)
        gameCenter.submitScore(progress.lifetimeReviews, leaderboard: .lifetimeReviews)
        if let stats {
            gameCenter.submitScore(stats.streakDays, leaderboard: .longestStreak)
        }
    }

    private func celebrationHeadline(
        quality: Int,
        combo: Int,
        leveledUp: Bool,
        dailyCompleted: Bool
    ) -> String {
        if leveledUp { return "Level up!" }
        if dailyCompleted { return "Daily challenge done!" }
        if combo >= 10 { return "Unstoppable!" }
        if combo >= 5 { return "Combo x\(combo)!" }
        if quality >= 5 { return "Crushed it!" }
        if quality >= 3 { return "Nice recall!" }
        return "Keep going!"
    }
}
