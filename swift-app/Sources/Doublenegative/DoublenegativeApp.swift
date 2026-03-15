import SwiftUI
import SwiftData

@main
struct DoublenegativeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ImageItem.self, PhotoCollection.self, Recipe.self])
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
}
