import Foundation
import Observation

@Observable
final class ReadingHistoryStore {
    private static let storageKey = "readingHistory"
    private static let maxCount = 50

    private(set) var articles: [Article]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Article].self, from: data) {
            articles = decoded
        } else {
            articles = []
        }
    }

    func append(_ article: Article) {
        articles.removeAll { $0.id == article.id }
        articles.insert(article, at: 0)
        if articles.count > Self.maxCount {
            articles = Array(articles.prefix(Self.maxCount))
        }
        persist()
    }

    func clear() {
        articles = []
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(articles) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
