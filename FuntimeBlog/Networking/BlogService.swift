import Foundation

protocol ArticleServing {
    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage
    func articleDetail(slug: String) async throws -> Article
    func regions() async throws -> [Region]
}

struct StaticArticleService: ArticleServing {
    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage {
        var articles = SampleData.articles
        if let city = query.city { articles = articles.filter { $0.tags.contains(city) } }
        if let category = query.category { articles = articles.filter { $0.tags.contains(category) } }
        if let keyword = query.keyword, !keyword.isEmpty {
            articles = articles.filter {
                $0.title.localizedCaseInsensitiveContains(keyword)
                || $0.excerpt.localizedCaseInsensitiveContains(keyword)
            }
        }
        return ArticlePage(articles: articles, page: 1, pageCount: 1)
    }

    func articleDetail(slug: String) async throws -> Article {
        SampleData.articles.first { $0.slug == slug } ?? SampleData.articles[0]
    }

    func regions() async throws -> [Region] {
        [
            Region(id: 41, name: "台灣", cities: ["台北", "台中", "台南", "高雄", "宜蘭", "花蓮"]),
            Region(id: 42, name: "日本", cities: ["東京", "關西", "北海道", "沖繩"]),
            Region(id: 43, name: "韓國", cities: ["首爾", "釜山"]),
        ]
    }
}

enum SampleData {
    static let articles: [Article] = [
        Article(id: "1", title: "東京必吃：澀谷隱藏版拉麵10選",
                author: "Sivan", authorSlug: "sivan",
                date: Date(), tags: ["日本", "東京"],
                imageURL: nil, slug: "tokyo-ramen-10",
                excerpt: "走進澀谷巷弄，發現讓人驚艷的拉麵秘境。", contentHTML: nil, city: "東京"),
        Article(id: "2", title: "台北週末市集完全攻略",
                author: "FunTime", authorSlug: nil,
                date: Date(), tags: ["台灣", "台北"],
                imageURL: nil, slug: "taipei-market-guide",
                excerpt: "每個週末都有新發現，台北市集文化的魅力所在。", contentHTML: nil, city: "台北"),
        Article(id: "3", title: "京都賞楓私房路線：遠離人群的秘境",
                author: "Sivan", authorSlug: "sivan",
                date: Date(), tags: ["日本", "關西"],
                imageURL: nil, slug: "kyoto-autumn-secret",
                excerpt: "不想跟著人潮走？這條路線讓你靜靜感受楓葉之美。", contentHTML: nil, city: "關西"),
    ]
}
