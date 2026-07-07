import AppKit
import PurrfectRecallKit
import SwiftUI

private final class PurrfectRecallAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct PurrfectRecallMacApp: App {
    @NSApplicationDelegateAdaptor(PurrfectRecallAppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @State private var menuBarVisible = true

    var body: some Scene {
        WindowGroup(id: "main") {
            MacRootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra(
            AppBrand.displayName,
            systemImage: "cat.fill",
            isInserted: $menuBarVisible
        ) {
            MacMenuBarStudyView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
