import SwiftUI
import SwiftData

@main
struct FuntimeBlogApp: App {
    private let container: ModelContainer

    @State private var favoritesStore: FavoritesStore
    @State private var readingHistoryStore: ReadingHistoryStore
    @State private var authStore: AuthStore
    @State private var gameStore: GameStore

    init() {
        let container = PersistenceContainer.makeShared()
        self.container = container
        let context = container.mainContext
        _favoritesStore = State(initialValue: FavoritesStore(context: context))
        _readingHistoryStore = State(initialValue: ReadingHistoryStore(context: context))
        _authStore = State(initialValue: AuthStore(context: context))
        _gameStore = State(initialValue: GameStore(context: context))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(favoritesStore)
                .environment(readingHistoryStore)
                .environment(authStore)
                .environment(gameStore)
        }
        .modelContainer(container)
    }
}
