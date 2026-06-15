import Foundation
import Observation

@Observable
final class HomeViewModel {
    enum ViewState {
        case loading
        case loaded
        case failed(String)
    }

    private let service: ArticleServing
    private(set) var articles: [Article] = []
    var state: ViewState = .loading

    var heroArticles: [Article]    { Array(articles.prefix(5)) }
    var popularArticles: [Article] { Array(articles.dropFirst(5)) }

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let page = try await service.fetchArticles(page: 1, query: ArticleQuery())
            articles = page.articles
            state = page.articles.isEmpty ? .failed("目前沒有文章。") : .loaded
        } catch {
            state = .failed("無法載入首頁內容，請稍後再試。")
        }
    }
}
