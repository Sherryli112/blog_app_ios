import Foundation
import Observation
import SwiftData

@Observable
final class FavoritesStore {
    private let context: ModelContext
    /// 目前資料範圍：登入者 email（小寫），訪客為空字串。
    private var owner: String = ""
    private(set) var articles: [Article] = []
    private var ids: Set<String> = []

    init(context: ModelContext) {
        self.context = context
        load()
    }

    /// Preview / 測試用：獨立的記憶體內儲存。
    convenience init() {
        self.init(context: PersistenceContainer.makeInMemoryContext())
    }

    /// 切換目前使用者（登入/登出時呼叫），並載入該使用者的收藏。
    func setOwner(_ email: String?) {
        owner = email?.lowercased() ?? ""
        load()
    }

    func isFavorite(_ article: Article) -> Bool {
        ids.contains(article.id)
    }

    func toggle(_ article: Article) {
        if ids.contains(article.id) {
            ids.remove(article.id)
            articles.removeAll { $0.id == article.id }
            let id = article.id
            let o = owner
            let descriptor = FetchDescriptor<FavoriteArticleEntity>(
                predicate: #Predicate { $0.id == id && $0.ownerEmail == o }
            )
            if let existing = try? context.fetch(descriptor) {
                existing.forEach { context.delete($0) }
            }
        } else {
            ids.insert(article.id)
            articles.insert(article, at: 0)
            context.insert(FavoriteArticleEntity(article: article, addedAt: Date(), ownerEmail: owner))
        }
        try? context.save()
    }

    private func load() {
        let o = owner
        let descriptor = FetchDescriptor<FavoriteArticleEntity>(
            predicate: #Predicate { $0.ownerEmail == o },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        articles = entities.map(\.article)
        ids = Set(articles.map(\.id))
    }
}
