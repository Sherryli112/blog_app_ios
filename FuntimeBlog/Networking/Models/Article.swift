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
    /// 文章所屬城市（來自 ft_theme），用於旅遊護照印章收集，與 tags 索引無關。
    let city: String?
}

struct ArticlePage {
    let articles: [Article]
    let page: Int
    let pageCount: Int
    var hasMore: Bool { page < pageCount }
}

struct ArticleQuery: Hashable {
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
