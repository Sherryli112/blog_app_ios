import SwiftUI

@main
struct FuntimeBlogApp: App {
    @State private var bookmarkStore = BookmarkStore()
    @State private var historyStore = ReadingHistoryStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(bookmarkStore)
                .environment(historyStore)
        }
    }
}
