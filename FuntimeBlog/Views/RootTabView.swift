import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Int = 0
    @State private var scrollToTopTriggers: [Int: Int] = [:]

    @Environment(AuthStore.self) private var authStore
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(ReadingHistoryStore.self) private var readingHistoryStore
    @Environment(GameStore.self) private var gameStore

    /// 將三個本地資料 Store 切換到目前登入者（未登入則為訪客範圍）。
    private func applyOwner() {
        let email = authStore.user?.email
        favoritesStore.setOwner(email)
        readingHistoryStore.setOwner(email)
        gameStore.setOwner(email)
    }

    private var selectionBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab {
                    scrollToTopTriggers[newTab, default: 0] += 1
                }
                selectedTab = newTab
            }
        )
    }

    var body: some View {
        TabView(selection: selectionBinding) {
            NavigationStack {
                HomeView(scrollToTopTrigger: scrollToTopTriggers[0, default: 0])
            }
            .tabItem { Label("首頁", systemImage: "house") }
            .tag(0)

            NavigationStack {
                CategoryView()
            }
            .tabItem { Label("分類", systemImage: "square.grid.2x2") }
            .tag(1)

            NavigationStack {
                SearchView()
            }
            .tabItem { Label("搜尋", systemImage: "magnifyingglass") }
            .tag(2)

            NavigationStack {
                FavoritesView(scrollToTopTrigger: scrollToTopTriggers[3, default: 0])
            }
            .tabItem { Label("收藏", systemImage: "bookmark") }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("個人", systemImage: "person.fill") }
            .tag(4)
        }
        .tint(AppTheme.Color.primary)
        .fontDesign(.rounded)
        .task { applyOwner() }
        .onChange(of: authStore.user?.email) { _, _ in applyOwner() }
    }
}

#Preview {
    RootTabView()
        .environment(FavoritesStore())
        .environment(ReadingHistoryStore())
        .environment(AuthStore())
        .environment(GameStore())
}
