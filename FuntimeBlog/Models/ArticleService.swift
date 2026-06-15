import Foundation

struct ArticlePage {
    let articles: [Article]
    let page: Int
    let pageCount: Int
    var hasMore: Bool { page < pageCount }
}

struct ArticleQuery: Equatable {
    var category: String?
    var city: String?
    var tag: String?
    var text: String?

    init(category: String? = nil,
         city: String? = nil,
         tag: String? = nil,
         text: String? = nil) {
        self.category = category
        self.city = city
        self.tag = tag
        self.text = text
    }
}

struct Region: Identifiable, Hashable {
    let id: Int
    let name: String
    let cities: [String]
}

protocol ArticleServing {
    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage
    func articleDetail(slug: String) async throws -> Article
    func regions() async throws -> [Region]
    func authorArticles(authorSlug: String, page: Int) async throws -> ArticlePage
}

struct StaticArticleService: ArticleServing {
    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage {
        var articles = SampleData.articles
        if let city = query.city, !city.isEmpty {
            articles = articles.filter { $0.tags.contains(city) }
        }
        if let category = query.category, !category.isEmpty {
            articles = articles.filter { $0.tags.contains(category) }
        }
        if let text = query.text, !text.isEmpty {
            articles = articles.filter {
                $0.title.localizedCaseInsensitiveContains(text)
                    || $0.excerpt.localizedCaseInsensitiveContains(text)
            }
        }
        return ArticlePage(articles: articles, page: 1, pageCount: 1)
    }

    func articleDetail(slug: String) async throws -> Article {
        SampleData.articles.first { $0.slug == slug || $0.id == slug }
            ?? SampleData.articles[0]
    }

    func regions() async throws -> [Region] {
        [
            Region(id: 41, name: "台灣", cities: ["台北", "台中", "台南", "高雄", "宜蘭", "花蓮"]),
            Region(id: 42, name: "日本", cities: ["東京", "關西", "北海道", "沖繩"]),
            Region(id: 43, name: "東南亞", cities: ["泰國", "越南", "馬來西亞"])
        ]
    }

    func authorArticles(authorSlug: String, page: Int) async throws -> ArticlePage {
        let articles = SampleData.articles.filter { $0.authorSlug == authorSlug }
        return ArticlePage(articles: articles, page: 1, pageCount: 1)
    }
}
