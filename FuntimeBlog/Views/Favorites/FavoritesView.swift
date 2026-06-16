import SwiftUI

struct FavoritesView: View {
    let scrollToTopTrigger: Int
    @Environment(FavoritesStore.self) private var favorites
    @State private var deleteTriggered = false

    var body: some View {
        Group {
            if favorites.articles.isEmpty {
                ContentUnavailableView(
                    "尚無收藏",
                    systemImage: "heart",
                    description: Text("閱讀文章時點擊愛心即可收藏")
                )
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(favorites.articles) { article in
                            NavigationLink(value: article) {
                                ArticleRow(article: article)
                            }
                            .buttonStyle(.plain)
                            .id(article.id)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    favorites.toggle(article)
                                    deleteTriggered.toggle()
                                } label: {
                                    Label("移除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: scrollToTopTrigger) { _, _ in
                        if let first = favorites.articles.first {
                            withAnimation { proxy.scrollTo(first.id, anchor: .top) }
                        }
                    }
                }
            }
        }
        .navigationTitle("收藏")
        .navigationBarTitleDisplayMode(.large)
        .sensoryFeedback(.impact(weight: .medium), trigger: deleteTriggered)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView(scrollToTopTrigger: 0)
    }
    .environment(FavoritesStore())
    .environment(ReadingHistoryStore())
}
