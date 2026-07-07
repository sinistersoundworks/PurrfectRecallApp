import Foundation

public enum XPLevel {
    /// XP required to reach a given level (level 1 = 0 XP).
    public static func xpForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (level - 1) * (level - 1) * 50
    }

    public static func level(forTotalXP xp: Int) -> Int {
        var level = 1
        while xpForLevel(level + 1) <= xp {
            level += 1
        }
        return level
    }

    public static func title(for level: Int) -> String {
        switch level {
        case 1...4: "Curious Cat"
        case 5...9: "Word Wrangler"
        case 10...19: "Memory Mage"
        case 20...34: "Recall Ranger"
        case 35...49: "Brain Boss"
        default: "Legendary Learner"
        }
    }

    public static func progressInLevel(totalXP: Int) -> (current: Int, needed: Int, fraction: Double) {
        let level = level(forTotalXP: totalXP)
        let floor = xpForLevel(level)
        let ceiling = xpForLevel(level + 1)
        let span = max(ceiling - floor, 1)
        let current = totalXP - floor
        return (current, span, Double(current) / Double(span))
    }
}
