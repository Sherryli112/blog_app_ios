import SwiftUI

struct CategoryArticleListView: View {
    let query: ArticleQuery
    @State private var viewModel: CategoryArticleListViewModel

    init(query: ArticleQuery) {
        self.query = query
        _viewModel = State(initialValue: CategoryArticleListViewModel(query: query))
    }

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading where viewModel.articles.isEmpty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message) where viewModel.articles.isEmpty:
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.reload() } }
                }
            case .loaded where viewModel.articles.isEmpty:
                ContentUnavailableView("此分類尚無文章", systemImage: "tray")
            default:
                articleList
            }
        }
        .navigationTitle(query.city ?? query.category ?? "文章")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
    }

    private var articleList: some View {
        List {
            ForEach(viewModel.articles) { article in
                NavigationLink(value: article) {
                    ArticleRow(article: article)
                }
                .buttonStyle(.plain)
                .onAppear {
                    if article.id == viewModel.articles.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.reload() }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryArticleListView(query: ArticleQuery(city: "東京"))
    }
    .environment(FavoritesStore())
    .environment(ReadingHistoryStore())
}
