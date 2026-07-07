import Foundation
import GameKit

@MainActor
@Observable
public final class GameCenterService {
    public enum Leaderboard: String {
        case totalXP = "purrfectrecall.leaderboard.total_xp"
        case longestStreak = "purrfectrecall.leaderboard.streak"
        case lifetimeReviews = "purrfectrecall.leaderboard.reviews"
    }

    public var isAuthenticated = false
    public var displayName: String?
    public var authenticationFailed = false

    public init() {}

    public func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.authenticationFailed = true
                    self.isAuthenticated = false
                    self.displayName = nil
                    print("Game Center auth failed: \(error.localizedDescription)")
                    return
                }
                if viewController != nil {
                    // macOS may present sign-in; local dev often auto-authenticates sandbox player.
                    return
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.displayName = GKLocalPlayer.local.displayName
                self.authenticationFailed = !self.isAuthenticated
            }
        }
    }

    public func submitScore(_ value: Int, leaderboard: Leaderboard) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(
            value,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboard.rawValue]
        ) { error in
            if let error {
                print("Leaderboard submit failed: \(error.localizedDescription)")
            }
        }
    }

    public func unlockAchievement(_ achievementID: String) {
        guard isAuthenticated else { return }
        let achievement = GKAchievement(identifier: "purrfectrecall.achievement.\(achievementID)")
        achievement.percentComplete = 100
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement]) { error in
            if let error {
                print("Achievement report failed: \(error.localizedDescription)")
            }
        }
    }
}
