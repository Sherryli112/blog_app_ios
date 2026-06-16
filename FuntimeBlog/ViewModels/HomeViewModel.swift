import Foundation
import Observation

@Observable
final class HomeViewModel {
    enum SortMode: String, CaseIterable {
        case latest = "最新"
        case hot = "熱門"
    }

    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    var articles: [Article] = []
    var sortMode: SortMode = .latest
    var loadState: LoadState = .idle
    var isLoadingMore = false

    private var currentPage = 0
    private var totalPages = 1
    var hasMore: Bool { currentPage < totalPages }

    private let service: ArticleServing

    init(service: ArticleServing = APIArticleService()) {
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

    func onSortModeChange() async {
        loadState = .idle
        await load()
    }

    private func fetchPage() async {
        let sort = sortMode == .hot ? "hot_rank:asc" : "publishedAt:desc"
        let query = ArticleQuery(sort: sort)
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
