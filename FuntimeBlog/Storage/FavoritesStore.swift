import Foundation
import Observation

@Observable
final class FavoritesStore {
    private static let storageKey = "favoriteArticles"

    private(set) var articles: [Article]
    private var ids: Set<String>

    init() {
        let loaded: [Article]
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Article].self, from: data) {
            loaded = decoded
        } else {
            loaded = []
        }
        self.articles = loaded
        self.ids = Set(loaded.map(\.id))
    }

    func isFavorite(_ article: Article) -> Bool {
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
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
