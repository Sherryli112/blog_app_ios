import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("首頁", systemImage: "house")
            }

            NavigationStack {
                CategoryView()
            }
            .tabItem {
                Label("分類", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("搜尋", systemImage: "magnifyingglass")
            }

            NavigationStack {
                BookmarkView()
            }
            .tabItem {
                Label("書籤", systemImage: "bookmark")
            }
        }
        .tint(AppTheme.Color.primary)
        .fontDesign(.rounded)
    }
}

#Preview {
    RootTabView()
        .environment(BookmarkStore())
        .environment(ReadingHistoryStore())
}
