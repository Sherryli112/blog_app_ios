import Foundation
import Observation

@Observable
final class ArticleListViewModel {
    enum ViewState {
        case loading
        case loaded([Article])
        case failed(String)
    }

    private let service: ArticleServing
    private(set) var category: String?
    let city: String?
    let searchText: String?

    var state: ViewState = .loading
    private(set) var isLoadingMore = false

    private var articles: [Article] = []
    private var page = 0
    private var pageCount = 1

    init(service: ArticleServing = APIArticleService(),
         category: String? = nil,
         city: String? = nil,
         searchText: String? = nil) {
        self.service = service
        self.category = category
        self.city = city
        self.searchText = searchText
    }

    func load() async {
        state = .loading
        page = 0
        pageCount = 1
        articles = []
        await fetchNextPage()
    }

    func setCategory(_ newCategory: String?) async {
        guard newCategory != category else { return }
        category = newCategory
        await load()
    }

    func loadMoreIfNeeded(currentItem: Article) async {
        guard let last = articles.last, last.id == currentItem.id else { return }
        await fetchNextPage()
    }

    private func fetchNextPage() async {
        guard !isLoadingMore, page < pageCount else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let result = try await service.fetchArticles(
                page: page + 1,
                query: ArticleQuery(category: category,
                                    city: city,
                                    text: searchText)
            )
            page = result.page
            pageCount = result.pageCount
            articles += result.articles
            state = .loaded(articles)
        } catch {
            if articles.isEmpty {
                state = .failed("無法載入文章，請稍後再試。")
            }
        }
    }
}
