import Foundation
import Observation
import SwiftData

@Observable
final class AuthStore {
    private let context: ModelContext

    private(set) var user: User?
    var isLoggedIn: Bool { user != nil }

    init(context: ModelContext) {
        self.context = context
        user = Self.fetchEntity(in: context)?.user
    }

    /// Preview 用：獨立的記憶體內儲存。
    convenience init() {
        self.init(context: PersistenceContainer.makeInMemoryContext())
    }

    func save(user: User) {
        self.user = user
        // 單裝置單一登入狀態：清掉舊紀錄再寫入。
        try? context.delete(model: AuthSessionEntity.self)
        context.insert(AuthSessionEntity(user: user))
        try? context.save()
    }

    func logout() {
        user = nil
        try? context.delete(model: AuthSessionEntity.self)
        try? context.save()
    }

    private static func fetchEntity(in context: ModelContext) -> AuthSessionEntity? {
        var descriptor = FetchDescriptor<AuthSessionEntity>()
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
