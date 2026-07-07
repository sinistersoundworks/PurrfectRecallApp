import SwiftUI

public struct XPProgressBar: View {
    let totalXP: Int
    let level: Int
    let title: String
    var compact: Bool = false

    public init(totalXP: Int, level: Int, title: String, compact: Bool = false) {
        self.totalXP = totalXP
        self.level = level
        self.title = title
        self.compact = compact
    }

    public var body: some View {
        let progress = XPLevel.progressInLevel(totalXP: totalXP)
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack {
                Label("Level \(level)", systemImage: "sparkles")
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(BCColor.accent)
                Spacer()
                Text(title)
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(BCColor.fg2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(BCColor.bgControl)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [BCColor.accent, BCColor.colorActive],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progress.fraction))
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: progress.fraction)
                }
            }
            .frame(height: compact ? 8 : 12)
            Text("\(progress.current) / \(progress.needed) XP to level \(level + 1)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(BCColor.fg3)
        }
        .padding(compact ? 12 : 16)
        .background(BCColor.bgRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BCColor.borderDefault, lineWidth: 1)
        }
    }
}

public struct ComboBadge: View {
    let combo: Int

    public init(combo: Int) {
        self.combo = combo
    }

    public var body: some View {
        if combo >= 2 {
            HStack(spacing: 6) {
                Image(systemName: combo >= 5 ? "bolt.fill" : "flame.fill")
                    .symbolEffect(.bounce, value: combo)
                Text("x\(combo) combo")
                    .font(.subheadline.weight(.bold).monospacedDigit())
            }
            .foregroundStyle(combo >= 5 ? BCColor.colorActive : BCColor.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (combo >= 5 ? BCColor.colorActiveDim : BCColor.accentDim),
                in: Capsule()
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}

public struct CelebrationOverlay: View {
    let celebration: ReviewCelebration
    let onDismiss: () -> Void

    @State private var animate = false

    public init(celebration: ReviewCelebration, onDismiss: @escaping () -> Void) {
        self.celebration = celebration
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Image(systemName: celebration.leveledUp ? "star.circle.fill" : "party.popper.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(BCColor.accent)
                    .symbolEffect(.bounce, value: animate)
                    .scaleEffect(animate ? 1 : 0.5)

                Text(celebration.headline)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(BCColor.fg1)

                Text("+\(celebration.xpGained) XP")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(BCColor.colorActive)

                if celebration.combo >= 3 {
                    ComboBadge(combo: celebration.combo)
                }

                if celebration.leveledUp {
                    Text("You reached level \(celebration.newLevel)!")
                        .font(.subheadline)
                        .foregroundStyle(BCColor.fg2)
                }

                if !celebration.unlockedAchievements.isEmpty {
                    VStack(spacing: 10) {
                        Text("Achievement unlocked!")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BCColor.fg3)
                        ForEach(celebration.unlockedAchievements) { achievement in
                            HStack(spacing: 10) {
                                Image(systemName: achievement.symbol)
                                    .foregroundStyle(BCColor.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(achievement.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(achievement.detail)
                                        .font(.caption)
                                        .foregroundStyle(BCColor.fg2)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(BCColor.bgElevated, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                if !celebration.completedDailyChallenges.isEmpty {
                    VStack(spacing: 10) {
                        Text("Daily challenge complete!")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BCColor.fg3)
                        ForEach(celebration.completedDailyChallenges) { challenge in
                            HStack(spacing: 10) {
                                Image(systemName: challenge.symbol)
                                    .foregroundStyle(BCColor.colorActive)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(challenge.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text("+\(challenge.xpReward) XP")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(BCColor.colorActive)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(BCColor.colorActiveDim, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                Button("Nice!", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .tint(BCColor.accent)
                    .controlSize(.large)
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(BCColor.bgRaised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(BCColor.accent.opacity(0.4), lineWidth: 2)
            }
            .shadow(color: BCColor.accent.opacity(0.25), radius: 24)
            .scaleEffect(animate ? 1 : 0.85)
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                animate = true
            }
        }
        .sensoryFeedback(.success, trigger: celebration.id)
    }
}

public struct DailyChallengesCard: View {
    let engine: GamificationEngine
    var compact: Bool = false

    public init(engine: GamificationEngine, compact: Bool = false) {
        self.engine = engine
        self.compact = compact
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 16) {
            HStack {
                Label("Daily Challenges", systemImage: "target")
                    .font(compact ? .subheadline.weight(.semibold) : .headline)
                    .foregroundStyle(BCColor.fg1)
                Spacer()
                Text("\(engine.dailyCompletedCount)/3")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(engine.dailyAllComplete ? BCColor.colorActive : BCColor.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        engine.dailyAllComplete ? BCColor.colorActiveDim : BCColor.accentDim,
                        in: Capsule()
                    )
            }

            if engine.progress.dailyChallengeStreak > 0 {
                Text("Daily streak: \(engine.progress.dailyChallengeStreak) day\(engine.progress.dailyChallengeStreak == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(BCColor.fg2)
            }

            ForEach(engine.dailyChallenges) { status in
                dailyRow(status)
            }
        }
        .padding(compact ? 12 : 16)
        .background(BCColor.bgRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    engine.dailyAllComplete ? BCColor.colorActive.opacity(0.45) : BCColor.borderDefault,
                    lineWidth: 1
                )
        }
    }

    private func dailyRow(_ status: DailyChallengeStatus) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: status.isComplete ? "checkmark.circle.fill" : status.challenge.symbol)
                    .foregroundStyle(status.isComplete ? BCColor.colorActive : BCColor.fg2)
                    .symbolEffect(.bounce, value: status.isComplete)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.challenge.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(status.isComplete ? BCColor.fg1 : BCColor.fg2)
                    Text(status.challenge.detail)
                        .font(.caption2)
                        .foregroundStyle(BCColor.fg3)
                }
                Spacer()
                Text("+\(status.challenge.xpReward)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(BCColor.accent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BCColor.bgControl)
                    Capsule()
                        .fill(status.isComplete ? BCColor.colorActive : BCColor.accent)
                        .frame(width: max(4, geo.size.width * status.progressFraction))
                }
            }
            .frame(height: 6)
            Text("\(min(status.current, status.target)) / \(status.target)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(BCColor.fg3)
        }
    }
}
