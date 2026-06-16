import Foundation
import Observation

@Observable
final class CategoryArticleListViewModel {
    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    var articles: [Article] = []
    var loadState: LoadState = .idle
    var isLoadingMore = false

    private var currentPage = 0
    private var totalPages = 1
    var hasMore: Bool { currentPage < totalPages }

    let query: ArticleQuery
    private let service: ArticleServing

    init(query: ArticleQuery, service: ArticleServing = APIArticleService()) {
        self.query = query
        self.service = service
    }

    func load() async {
        guard case .idle = loadState else { return }
        loadState = .loading
        currentPage = 0
        totalPages = 1
        articles = []
        await fetchPage()
    }

    func reload() async {
        loadState = .idle
        await load()
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        await fetchPage()
        isLoadingMore = false
    }

    private func fetchPage() async {
        do {
            let result = try await service.fetchArticles(page: currentPage + 1, query: query)
            articles.append(contentsOf: result.articles)
            currentPage = result.page
            totalPages = result.pageCount
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
