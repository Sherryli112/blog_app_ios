import Foundation

struct Article: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let author: String
    let authorSlug: String?
    let date: Date
    let tags: [String]
    let imageURL: URL?
    let slug: String
    let excerpt: String
    let contentHTML: String?
}

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
    var keyword: String?
    var sort: String?

    init(category: String? = nil, city: String? = nil, tag: String? = nil,
         keyword: String? = nil, sort: String? = nil) {
        self.category = category
        self.city = city
        self.tag = tag
        self.keyword = keyword
        self.sort = sort
    }
}
