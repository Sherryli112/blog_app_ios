import Foundation
import SwiftData

// MARK: - SwiftData 實體
//
// 這些 @Model class 是本地持久化的儲存層，符合設計規格「本地儲存：SwiftData」。
// 各 Store 對外仍提供既有的 @Observable API，內部以這些實體 + ModelContext 取代 UserDefaults。
// view 端使用的仍是 Article / GameProfile / User 等既有 struct，由實體負責雙向轉換。

@Model
final class FavoriteArticleEntity {
    // id 不再唯一：同一篇文章可被不同 ownerEmail 各自收藏，去重由 Store 依 owner 處理。
    var id: String
    var title: String
    var author: String
    var authorSlug: String?
    var date: Date
    var tags: [String]
    var imageURL: URL?
    var slug: String
    var excerpt: String
    var contentHTML: String?
    var city: String?
    var addedAt: Date
    /// 擁有此收藏的使用者 email（小寫）；訪客為空字串。預設值供既有資料平滑遷移。
    var ownerEmail: String = ""

    init(article: Article, addedAt: Date, ownerEmail: String) {
        self.id = article.id
        self.title = article.title
        self.author = article.author
        self.authorSlug = article.authorSlug
        self.date = article.date
        self.tags = article.tags
        self.imageURL = article.imageURL
        self.slug = article.slug
        self.excerpt = article.excerpt
        self.contentHTML = article.contentHTML
        self.city = article.city
        self.addedAt = addedAt
        self.ownerEmail = ownerEmail
    }

    var article: Article {
        Article(id: id, title: title, author: author, authorSlug: authorSlug,
                date: date, tags: tags, imageURL: imageURL, slug: slug,
                excerpt: excerpt, contentHTML: contentHTML, city: city)
    }
}

@Model
final class HistoryEntity {
    // id 不再唯一：同一篇文章可在不同 ownerEmail 的歷史各自存在，去重由 Store 依 owner 處理。
    var id: String
    var title: String
    var author: String
    var authorSlug: String?
    var date: Date
    var tags: [String]
    var imageURL: URL?
    var slug: String
    var excerpt: String
    var contentHTML: String?
    var city: String?
    var viewedAt: Date
    /// 擁有此閱讀紀錄的使用者 email（小寫）；訪客為空字串。預設值供既有資料平滑遷移。
    var ownerEmail: String = ""

    init(article: Article, viewedAt: Date, ownerEmail: String) {
        self.id = article.id
        self.title = article.title
        self.author = article.author
        self.authorSlug = article.authorSlug
        self.date = article.date
        self.tags = article.tags
        self.imageURL = article.imageURL
        self.slug = article.slug
        self.excerpt = article.excerpt
        self.contentHTML = article.contentHTML
        self.city = article.city
        self.viewedAt = viewedAt
        self.ownerEmail = ownerEmail
    }

    var article: Article {
        Article(id: id, title: title, author: author, authorSlug: authorSlug,
                date: date, tags: tags, imageURL: imageURL, slug: slug,
                excerpt: excerpt, contentHTML: contentHTML, city: city)
    }
}

@Model
final class GameProfileEntity {
    var xp: Int
    var level: Int
    var streakDays: Int
    var lastCheckIn: Date?
    var stamps: [String]
    /// 擁有此遊戲檔的使用者 email（小寫）；訪客為空字串。預設值供既有資料平滑遷移。
    var ownerEmail: String = ""

    init(profile: GameProfile, ownerEmail: String) {
        self.xp = profile.xp
        self.level = profile.level
        self.streakDays = profile.streakDays
        self.lastCheckIn = profile.lastCheckIn
        self.stamps = profile.stamps
        self.ownerEmail = ownerEmail
    }

    var profile: GameProfile {
        GameProfile(xp: xp, level: level, streakDays: streakDays,
                    lastCheckIn: lastCheckIn, stamps: stamps)
    }

    func apply(_ profile: GameProfile) {
        xp = profile.xp
        level = profile.level
        streakDays = profile.streakDays
        lastCheckIn = profile.lastCheckIn
        stamps = profile.stamps
    }
}

@Model
final class AuthSessionEntity {
    var userID: Int
    var username: String
    var email: String
    var confirmed: Bool
    var blocked: Bool

    init(user: User) {
        self.userID = user.id
        self.username = user.username
        self.email = user.email
        self.confirmed = user.confirmed
        self.blocked = user.blocked
    }

    var user: User {
        User(id: userID, username: username, email: email,
             confirmed: confirmed, blocked: blocked)
    }
}

// MARK: - 共用 ModelContainer 工廠

enum PersistenceContainer {
    /// 所有本地實體的型別清單，App 與 in-memory 容器共用。
    static let models: [any PersistentModel.Type] = [
        FavoriteArticleEntity.self,
        HistoryEntity.self,
        GameProfileEntity.self,
        AuthSessionEntity.self
    ]

    /// App 正式使用的持久化容器（寫入磁碟）。
    static func makeShared() -> ModelContainer {
        let schema = Schema(models)
        do {
            return try ModelContainer(for: schema)
        } catch {
            // 萬一 schema 變更導致無法開啟舊 store，退回 in-memory 以免整個 App 無法啟動。
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: config)
        }
    }

    /// 每次呼叫都建立一個全新的記憶體內 context，供 Preview / 測試使用，彼此隔離。
    static func makeInMemoryContext() -> ModelContext {
        let schema = Schema(models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }
}
