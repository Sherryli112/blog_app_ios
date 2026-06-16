import SwiftUI

@main
struct FuntimeBlogApp: App {
    @State private var favoritesStore = FavoritesStore()
    @State private var readingHistoryStore = ReadingHistoryStore()
    @State private var authStore = AuthStore()
    @State private var gameStore = GameStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(favoritesStore)
                .environment(readingHistoryStore)
                .environment(authStore)
                .environment(gameStore)
        }
    }
}
