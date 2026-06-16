import SwiftUI

@main
struct FuntimeBlogApp: App {
    @State private var favoritesStore = FavoritesStore()
    @State private var readingHistoryStore = ReadingHistoryStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(favoritesStore)
                .environment(readingHistoryStore)
        }
    }
}
