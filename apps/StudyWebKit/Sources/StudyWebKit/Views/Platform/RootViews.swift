import SwiftUI

public struct MacRootView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 210)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BCColor.bgBase)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(width: 480, height: 280)
        }
        .alert("Error", isPresented: Binding(
            get: { appState.lastError != nil },
            set: { if !$0 { appState.lastError = nil } }
        )) {
            Button("OK") { appState.lastError = nil }
        } message: {
            Text(appState.lastError ?? "")
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: BCSpacing.s2) {
                RoundedRectangle(cornerRadius: BCRadius.lg)
                    .fill(BCColor.accentDim)
                    .overlay(RoundedRectangle(cornerRadius: BCRadius.lg).stroke(BCColor.accent, lineWidth: 1))
                    .frame(width: 26, height: 26)
                    .overlay(Text("S").font(BCFont.ui(BCFont.textMD, weight: .bold)).foregroundStyle(BCColor.accent))
                Text("StudyWeb")
                    .font(BCFont.ui(BCFont.textLG, weight: .semibold))
                    .foregroundStyle(BCColor.fg1)
                Spacer()
            }
            .padding(.horizontal, BCSpacing.s4)
            .frame(height: 56)
            .overlay(alignment: .bottom) { Rectangle().fill(BCColor.borderSubtle).frame(height: 1) }

            VStack(spacing: 2) {
                ForEach(AppTab.allCases) { tab in
                    navItem(tab)
                }
            }
            .padding(.horizontal, BCSpacing.s2)
            .padding(.top, BCSpacing.s3)

            Spacer()

            HStack(spacing: BCSpacing.s2) {
                Circle().fill(BCColor.colorActive).frame(width: 6, height: 6)
                Text("StudyWeb API")
                    .font(BCFont.ui(BCFont.textXS))
                    .foregroundStyle(BCColor.fg3)
                Spacer()
                Button("⚙") { showSettings = true }
                    .buttonStyle(.plain)
                    .foregroundStyle(BCColor.fg3)
            }
            .padding(.horizontal, BCSpacing.s3)
            .frame(height: 52)
            .background(BCColor.bgElevated)
            .overlay(alignment: .top) { Rectangle().fill(BCColor.borderSubtle).frame(height: 1) }
        }
        .background(BCColor.bgRaised)
        .overlay(alignment: .trailing) { Rectangle().fill(BCColor.borderSubtle).frame(width: 1) }
    }

    private func navItem(_ tab: AppTab) -> some View {
        let active = appState.selectedTab == tab
        return Button {
            appState.selectedTab = tab
        } label: {
            HStack(spacing: BCSpacing.s2) {
                Text(tab.icon).frame(width: 18)
                Text(tab.title)
                    .font(BCFont.ui(BCFont.textBase))
            }
            .foregroundStyle(active ? BCColor.accent : BCColor.fg2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BCSpacing.s3)
            .padding(.vertical, BCSpacing.s2)
            .background(active ? BCColor.accentDim : Color.clear)
            .overlay(alignment: .leading) {
                if active {
                    Rectangle().fill(BCColor.accent).frame(width: 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: BCRadius.sm))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        switch appState.selectedTab {
        case .dashboard: DashboardContentView(compact: false)
        case .study: StudyContentView(compact: false)
        case .decks: MacDecksView()
        case .stats: StatsContentView(compact: false)
        }
    }
}

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
    }

    private var navBar: some View {
        HStack(spacing: BCSpacing.s2) {
            RoundedRectangle(cornerRadius: 5)
                .fill(BCColor.accentDim)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(BCColor.accent, lineWidth: 1))
                .frame(width: 22, height: 22)
                .overlay(Text("S").font(BCFont.ui(BCFont.textSM, weight: .bold)).foregroundStyle(BCColor.accent))
            Text("StudyWeb")
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
