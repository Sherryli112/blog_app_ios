import SwiftUI

struct BookmarkView: View {
    @Environment(BookmarkStore.self) private var bookmarks

    var body: some View {
        let items = bookmarks.articles
        Group {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("還沒有書籤", systemImage: "bookmark")
                        .foregroundStyle(AppTheme.Color.primary)
                } description: {
                    Text("點文章上的書籤圖示，就能把文章存起來。")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.lg) {
                        ForEach(items) { article in
                            ArticleCardLink(article: article)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        bookmarks.toggle(article)
                                    } label: {
                                        Label("移除", systemImage: "bookmark.slash")
                                    }
                                }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
        }
        .background(AppTheme.Color.background)
        .navigationTitle("書籤")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }
}

#Preview {
    let store = BookmarkStore()
    store.toggle(SampleData.articles[0])
    store.toggle(SampleData.articles[1])
    return NavigationStack {
        BookmarkView()
    }
    .environment(store)
    .environment(ReadingHistoryStore())
}
