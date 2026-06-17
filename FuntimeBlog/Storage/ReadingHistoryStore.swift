import Foundation
import Observation
import SwiftData

@Observable
final class ReadingHistoryStore {
    private static let maxCount = 50

    private let context: ModelContext
    /// 目前資料範圍：登入者 email（小寫），訪客為空字串。
    private var owner: String = ""
    private(set) var articles: [Article] = []

    init(context: ModelContext) {
        self.context = context
        load()
    }

    /// Preview / 測試用：獨立的記憶體內儲存。
    convenience init() {
        self.init(context: PersistenceContainer.makeInMemoryContext())
    }

    /// 切換目前使用者（登入/登出時呼叫），並載入該使用者的閱讀紀錄。
    func setOwner(_ email: String?) {
        owner = email?.lowercased() ?? ""
        load()
    }

    func append(_ article: Article) {
        let id = article.id
        let o = owner
        // 移除同一使用者既有的同一篇紀錄，稍後重新插入到最前面（最近閱讀）。
        let dupDescriptor = FetchDescriptor<HistoryEntity>(
            predicate: #Predicate { $0.id == id && $0.ownerEmail == o }
        )
        if let duplicates = try? context.fetch(dupDescriptor) {
            duplicates.forEach { context.delete($0) }
        }
        context.insert(HistoryEntity(article: article, viewedAt: Date(), ownerEmail: owner))
        try? context.save()

        // 超過上限時，刪除此使用者最舊的紀錄。
        let allDescriptor = FetchDescriptor<HistoryEntity>(
            predicate: #Predicate { $0.ownerEmail == o },
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        let entities = (try? context.fetch(allDescriptor)) ?? []
        if entities.count > Self.maxCount {
            entities[Self.maxCount...].forEach { context.delete($0) }
            try? context.save()
        }

        load()
    }

    func clear() {
        let o = owner
        try? context.delete(model: HistoryEntity.self, where: #Predicate { $0.ownerEmail == o })
        try? context.save()
        articles = []
    }

    private func load() {
        let o = owner
        let descriptor = FetchDescriptor<HistoryEntity>(
            predicate: #Predicate { $0.ownerEmail == o },
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        articles = entities.map(\.article)
    }
}
