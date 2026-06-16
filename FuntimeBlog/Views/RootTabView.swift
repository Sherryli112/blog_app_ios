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
            Tab("首頁", systemImage: "flame.fill", value: 0) {
                NavigationStack {
                    HomeView(scrollToTopTrigger: scrollToTopTriggers[0, default: 0])
                }
            }
            Tab("分類", systemImage: "square.grid.2x2", value: 1) {
                NavigationStack {
                    CategoryView()
                }
            }
            Tab("搜尋", systemImage: "magnifyingglass", value: 2) {
                NavigationStack {
                    SearchView()
                }
            }
            Tab("收藏", systemImage: "heart.fill", value: 3) {
                NavigationStack {
                    FavoritesView(scrollToTopTrigger: scrollToTopTriggers[3, default: 0])
                }
            }
            Tab("個人", systemImage: "person.fill", value: 4) {
                NavigationStack {
                    ProfileView()
                }
            }
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
}
