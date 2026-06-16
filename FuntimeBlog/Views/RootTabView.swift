import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Int = 0
    @State private var scrollToTopTriggers: [Int: Int] = [:]

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
            .tabItem { Label("首頁", systemImage: "flame.fill") }
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
            .tabItem { Label("收藏", systemImage: "heart.fill") }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("個人", systemImage: "person.fill") }
            .tag(4)
        }
        .tint(AppTheme.Color.primary)
        .fontDesign(.rounded)
    }
}

#Preview {
    RootTabView()
        .environment(FavoritesStore())
        .environment(ReadingHistoryStore())
        .environment(AuthStore())
        .environment(GameStore())
}
