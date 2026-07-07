import PurrfectRecallKit
import SwiftUI

@main
struct PurrfectRecallIOSApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}
