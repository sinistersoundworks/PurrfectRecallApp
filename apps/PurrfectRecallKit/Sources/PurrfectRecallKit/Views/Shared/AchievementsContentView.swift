import SwiftUI

public struct AchievementsContentView: View {
    let engine: GamificationEngine
    let gameCenter: GameCenterService
    var compact: Bool = false

    public init(engine: GamificationEngine, gameCenter: GameCenterService, compact: Bool = false) {
        self.engine = engine
        self.gameCenter = gameCenter
        self.compact = compact
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 16 : 24) {
                hero
                progressSummary
                dailySection
                achievementGrid
                if gameCenter.isAuthenticated, let name = gameCenter.displayName {
                    gameCenterBanner(name)
                }
            }
            .padding(compact ? 16 : 24)
        }
        .background(BCColor.bgBase)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundStyle(BCColor.accent)
                Text("Trophy Room")
                    .font(compact ? .title2.weight(.bold) : .largeTitle.weight(.bold))
                    .foregroundStyle(BCColor.fg1)
            }
            Text("\(engine.unlockedCount) of \(AchievementCatalog.all.count) achievements unlocked")
                .font(.subheadline)
                .foregroundStyle(BCColor.fg2)
        }
    }

    private var progressSummary: some View {
        XPProgressBar(
            totalXP: engine.progress.totalXP,
            level: engine.level,
            title: engine.levelTitle,
            compact: compact
        )
    }

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Challenges")
                .font(.headline)
                .foregroundStyle(BCColor.fg1)
            DailyChallengesCard(engine: engine, compact: compact)
        }
    }

    private var achievementGrid: some View {
        let columns = compact
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(AchievementCatalog.all) { achievement in
                AchievementBadge(
                    achievement: achievement,
                    unlocked: engine.isUnlocked(achievement.id)
                )
            }
        }
    }

    private func gameCenterBanner(_ name: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "gamecontroller.fill")
                .foregroundStyle(BCColor.colorInfo)
            Text("Signed in to Game Center as \(name). Scores sync to leaderboards.")
                .font(.caption)
                .foregroundStyle(BCColor.fg2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BCColor.bgRaised, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? BCColor.accentDim : BCColor.bgControl)
                    .frame(width: 56, height: 56)
                Image(systemName: achievement.symbol)
                    .font(.title2)
                    .foregroundStyle(unlocked ? BCColor.accent : BCColor.fg3)
                    .symbolEffect(.pulse, isActive: unlocked)
            }
            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(unlocked ? BCColor.fg1 : BCColor.fg3)
                .multilineTextAlignment(.center)
            Text(achievement.detail)
                .font(.caption2)
                .foregroundStyle(BCColor.fg3)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(BCColor.bgRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(unlocked ? BCColor.accent.opacity(0.5) : BCColor.borderDefault, lineWidth: 1)
        }
        .opacity(unlocked ? 1 : 0.72)
    }
}

#if os(macOS)

public struct MacAchievementsView: View {
    @Environment(AppState.self) private var appState

    public init() {}

    public var body: some View {
        AchievementsContentView(
            engine: appState.gamification,
            gameCenter: appState.gameCenter
        )
        .navigationTitle("Trophies")
    }
}

#endif
