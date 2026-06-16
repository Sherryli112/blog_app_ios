import Foundation
import Observation

@Observable
final class ArticleDetailViewModel {
    enum ContentState {
        case loading
        case loaded(String)
        case failed(String)
    }

    let summary: Article
    private let service: ArticleServing
    var contentState: ContentState = .loading

    init(article: Article, service: ArticleServing = APIArticleService()) {
        self.summary = article
        self.service = service
    }

    func load() async {
        if let html = summary.contentHTML, !html.isEmpty {
            contentState = .loaded(html)
            return
        }
        guard !summary.slug.isEmpty else {
            contentState = .loaded("<p>\(summary.excerpt)</p>")
            return
        }
        contentState = .loading
        do {
            let full = try await service.articleDetail(slug: summary.slug)
            contentState = .loaded(full.contentHTML ?? "<p>\(full.excerpt)</p>")
        } catch {
            contentState = .failed("無法載入文章內容，請稍後再試。")
        }
    }
}
