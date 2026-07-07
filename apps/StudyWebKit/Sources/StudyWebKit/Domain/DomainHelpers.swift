import Foundation
import SwiftUI

public enum DeckColor {
    private static let palette: [Color] = [
        Color(hex: 0xF08C0A),
        Color(hex: 0x38C4F0),
        Color(hex: 0x34D058),
        Color(hex: 0xF05050),
        Color(hex: 0xF0B030),
        Color(hex: 0xA78BFA),
    ]

    public static func color(for subjectId: Int) -> Color {
        let index = abs(subjectId) % palette.count
        return palette[index]
    }
}

public enum CardStatus {
    public static func kind(for card: FlashcardDTO, now: Date = Date()) -> CardStatusKind {
        if card.repetition >= 2 { return .mastered }
        if card.repetition == 1 { return .learning }
        if card.dueDate <= now { return .due }
        return .learning
    }
}

public enum SM2 {
    public static func quality(fromConfidencePercent confidence: Double) -> Int {
        let value = confidence / 100.0
        if value < 0.2 { return 0 }
        if value < 0.4 { return 2 }
        if value < 0.6 { return 3 }
        if value < 0.8 { return 4 }
        return 5
    }

    public static func predictedRecallPercent(confidence: Double) -> Int {
        Int(55 + confidence * 0.2)
    }
}

public enum Greeting {
    public static func current() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
}
