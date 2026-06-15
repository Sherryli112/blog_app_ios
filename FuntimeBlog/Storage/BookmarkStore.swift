import Foundation
import Observation

@Observable
final class BookmarkStore {
    private static let storageKey = "bookmarkedArticles"
    private let defaults: UserDefaults

    private(set) var articles: [Article]
    private var ids: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Article].self, from: data) {
            articles = decoded
            ids = Set(decoded.map(\.id))
        } else {
            articles = []
            ids = []
        }
    }

    func isBookmarked(_ article: Article) -> Bool {
        ids.contains(article.id)
    }

    func toggle(_ article: Article) {
        if ids.contains(article.id) {
            ids.remove(article.id)
            articles.removeAll { $0.id == article.id }
        } else {
            ids.insert(article.id)
            articles.insert(article, at: 0)
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(articles) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
