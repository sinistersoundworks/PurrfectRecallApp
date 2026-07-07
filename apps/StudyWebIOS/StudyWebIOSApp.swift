import StudyWebKit
import SwiftUI

@main
struct StudyWebIOSApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}
