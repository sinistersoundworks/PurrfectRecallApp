import StudyWebKit
import SwiftUI

@main
struct StudyWebMacApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MacRootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
    }
}
