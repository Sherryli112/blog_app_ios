import SwiftUI

struct AuthorView: View {
    let authorSlug: String
    let authorName: String
    @State private var articles: [Article] = []
    @State private var isLoading = false
    @State private var hasLoaded = false
    private let service: ArticleServing = APIArticleService()

    var body: some View {
        List {
            Section {
                HStack(spacing: AppTheme.Spacing.lg) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.Color.primary)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(authorName)
                            .font(.title2.bold())
                        Text("@\(authorSlug)")
                            .font(AppTheme.Font.meta)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .listRowSeparator(.hidden)
            }

            Section("文章") {
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(articles) { article in
                        NavigationLink(value: article) {
                            ArticleRow(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                    if articles.isEmpty && hasLoaded {
                        ContentUnavailableView("尚無文章", systemImage: "doc")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(authorName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .task {
            guard !hasLoaded else { return }
            isLoading = true
            let query = ArticleQuery(tag: authorSlug)
            if let page = try? await service.fetchArticles(page: 1, query: query) {
                articles = page.articles
            }
            isLoading = false
            hasLoaded = true
        }
    }
}

#Preview {
    NavigationStack {
        AuthorView(authorSlug: "sivan", authorName: "Sivan")
    }
    .environment(FavoritesStore())
    .environment(ReadingHistoryStore())
}
