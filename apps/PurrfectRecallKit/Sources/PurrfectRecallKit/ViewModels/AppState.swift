import Foundation
import Observation

public enum AppTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case dashboard
    case study
    case decks
    case stats
    case achievements

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .study: "Study"
        case .decks: "Decks"
        case .stats: "Stats"
        case .achievements: "Trophies"
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: "⌂"
        case .study: "▶"
        case .decks: "▤"
        case .stats: "▥"
        case .achievements: "★"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .dashboard: "house"
        case .study: "play.circle"
        case .decks: "rectangle.stack"
        case .stats: "chart.bar"
        case .achievements: "trophy"
        }
    }
}

@Observable
@MainActor
public final class AppState {
    public var selectedTab: AppTab = .dashboard
    public var selectedDeckId: Int?
    public var studyDeckId: Int?
    public var apiBaseURL: String
    public var lastError: String?

    public let api = APIClient()
    public let gameCenter: GameCenterService
    public let gamification: GamificationEngine

    public init() {
        let gc = GameCenterService()
        gameCenter = gc
        gamification = GamificationEngine(gameCenter: gc)
        apiBaseURL = UserDefaults.standard.string(forKey: APIConfig.baseURLKey) ?? APIConfig.defaultBaseURL
    }

    public func saveAPIBaseURL() {
        APIConfig.setBaseURL(apiBaseURL)
    }

    public func openDeck(_ id: Int) {
        selectedDeckId = id
        selectedTab = .decks
    }

    public func startStudy(deckId: Int? = nil) {
        studyDeckId = deckId ?? selectedDeckId
        selectedTab = .study
    }

    public func reportError(_ error: Error) {
        lastError = error.localizedDescription
    }

    public func bootstrapGamification() {
        gameCenter.authenticate()
    }

    public func syncGamificationFromStats(_ stats: StatsDTO) {
        gamification.syncFromStats(stats)
    }
}
