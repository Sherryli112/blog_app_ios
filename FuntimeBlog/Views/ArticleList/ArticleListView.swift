import SwiftUI

struct ArticleListView: View {
    let title: String
    @State private var viewModel: ArticleListViewModel

    init(title: String = "",
         viewModel: ArticleListViewModel = ArticleListViewModel()) {
        self.title = title
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let articles):
                if articles.isEmpty {
                    ContentUnavailableView("沒有符合的文章",
                                          systemImage: "doc.text.magnifyingglass")
                        .frame(maxHeight: .infinity)
                } else {
                    articleList(articles)
                }

            case .failed(let message):
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.load() } }
                }
            }
        }
        .background(AppTheme.Color.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .task {
            if case .loading = viewModel.state { await viewModel.load() }
        }
    }

    private func articleList(_ articles: [Article]) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                ForEach(articles) { article in
                    ArticleCardLink(article: article)
                        .task { await viewModel.loadMoreIfNeeded(currentItem: article) }
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .refreshable { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        ArticleListView(
            title: "文章",
            viewModel: ArticleListViewModel(service: StaticArticleService())
        )
    }
    .environment(BookmarkStore())
}
