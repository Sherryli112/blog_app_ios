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
        // 注意：官網 www.funtime.com.tw/blog 實際上永遠導向舊系統 WordPress，
        // 真正的「最新／熱門」排序來自舊系統 MySQL 的 blog_index_list 人工維護表，
        // 沒有對外 API。這裡用 Strapi 既有欄位近似（custom_published_at 是編輯可覆寫
        // 的顯示發佈時間；hot_rank 是人工標記的熱門分數，大部分文章沒有設值），
        // 順序不會跟官網逐字一致，是已知、經確認可接受的近似值。
        let sort = sortMode == .hot ? "hot_rank:asc" : "custom_published_at:desc"
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
