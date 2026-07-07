import SwiftUI

#if os(macOS)

public struct MacRootView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    public init() {}

    public var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            sidebar(selection: $appState.selectedTab)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(BCColor.bgBase)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(width: 460, height: 220)
        }
        .alert("Error", isPresented: Binding(
            get: { appState.lastError != nil },
            set: { if !$0 { appState.lastError = nil } }
        )) {
            Button("OK") { appState.lastError = nil }
        } message: {
            Text(appState.lastError ?? "")
        }
        .overlay {
            if let celebration = appState.gamification.activeCelebration {
                CelebrationOverlay(celebration: celebration) {
                    appState.gamification.dismissCelebration()
                }
            }
        }
        .task { appState.bootstrapGamification() }
        .task { await monitorAPIHealth() }
    }

    private func monitorAPIHealth() async {
        var wasReachable = appState.isAPIReachable
        while !Task.isCancelled {
            await appState.refreshAPIHealth()
            if appState.isAPIReachable && !wasReachable {
                appState.bumpDataRefresh()
            }
            wasReachable = appState.isAPIReachable
            try? await Task.sleep(for: .seconds(3))
        }
    }

    private func sidebar(selection: Binding<AppTab>) -> some View {
        List(selection: selection) {
            Section {
                ForEach(AppTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.sfSymbol)
                        .tag(tab)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(AppBrand.displayName)
        .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(BCColor.accent)
                    Text("Lv.\(appState.gamification.level) \(appState.gamification.levelTitle)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(BCColor.fg2)
                    Spacer()
                    Text("\(appState.gamification.progress.totalXP) XP")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(BCColor.fg3)
                }
                .padding(.horizontal, 16)
                HStack(spacing: 8) {
                Circle()
                    .fill(appState.isAPIReachable ? BCColor.colorActive : BCColor.colorDanger)
                    .frame(width: 7, height: 7)
                Text(appState.isAPIReachable ? "API Connected" : "API Unreachable")
                    .font(.caption)
                    .foregroundStyle(appState.isAPIReachable ? BCColor.fg2 : BCColor.colorDanger)
                Spacer()
                if !appState.isAPIReachable {
                    Button("Retry") {
                        Task { await appState.retryAPIConnection() }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedTab {
        case .dashboard:
            MacDashboardView()
                .navigationTitle("Dashboard")
        case .study:
            MacStudyView()
                .navigationTitle("Study")
        case .decks:
            MacDecksView()
        case .stats:
            MacStatsView()
                .navigationTitle("Stats")
        case .achievements:
            MacAchievementsView()
        }
    }
}

#endif

// iOS root remains below

public struct IOSRootView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            navBar
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            tabBar
        }
        .background(BCColor.bgBase)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .overlay {
            if let celebration = appState.gamification.activeCelebration {
                CelebrationOverlay(celebration: celebration) {
                    appState.gamification.dismissCelebration()
                }
            }
        }
        .task { appState.bootstrapGamification() }
    }

    private var navBar: some View {
        HStack(spacing: BCSpacing.s2) {
            RoundedRectangle(cornerRadius: 5)
                .fill(BCColor.accentDim)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(BCColor.accent, lineWidth: 1))
                .frame(width: 22, height: 22)
                .overlay(Text(AppBrand.monogram).font(BCFont.ui(BCFont.textSM, weight: .bold)).foregroundStyle(BCColor.accent))
            Text(AppBrand.displayName)
                .font(BCFont.ui(BCFont.textMD, weight: .semibold))
                .foregroundStyle(BCColor.fg1)
            Spacer()
            Button("⚙") { showSettings = true }
                .buttonStyle(.plain)
                .foregroundStyle(BCColor.fg3)
        }
        .padding(.horizontal, BCSpacing.s4)
        .frame(height: 48)
        .background(BCColor.bgRaised)
        .overlay(alignment: .bottom) { Rectangle().fill(BCColor.borderSubtle).frame(height: 1) }
    }

    @ViewBuilder
    private var content: some View {
        switch appState.selectedTab {
        case .dashboard: DashboardContentView(compact: true)
        case .study: StudyContentView(compact: true)
        case .decks: IOSDecksView()
        case .stats: StatsContentView(compact: true)
        case .achievements:
            AchievementsContentView(
                engine: appState.gamification,
                gameCenter: appState.gameCenter,
                compact: true
            )
        }
    }

    private var tabBar: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, BCSpacing.s2)
        .padding(.vertical, BCSpacing.s2)
        .background(BCColor.bgRaised)
        .overlay(alignment: .top) { Rectangle().fill(BCColor.borderSubtle).frame(height: 1) }
    }

    private func tabItem(_ tab: AppTab) -> some View {
        let active = appState.selectedTab == tab
        return Button {
            appState.selectedTab = tab
        } label: {
            VStack(spacing: BCSpacing.s1) {
                Text(tab.icon)
                    .font(BCFont.ui(BCFont.textMD))
                    .foregroundStyle(active ? BCColor.fgOnAccent : BCColor.fg2)
                    .frame(width: 28, height: 24)
                    .background(active ? BCColor.accent : BCColor.bgControl)
                    .clipShape(RoundedRectangle(cornerRadius: BCRadius.sm))
                Text(tab.title)
                    .font(BCFont.ui(BCFont.text2XS, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? BCColor.accent : BCColor.fg3)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
