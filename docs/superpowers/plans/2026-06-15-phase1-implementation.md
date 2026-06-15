# FuntimeBlog iOS App — Phase 1 實作計劃

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 從零建立 FunTime Blog iOS App Phase 1 完整功能：文章列表（含無限捲動）、文章詳細頁（WKWebView）、分類瀏覽、關鍵字搜尋、書籤、閱讀歷史、作者頁。

**Architecture:** MVVM + Protocol-based 服務層。`@Observable` ViewModels 管理 UI 狀態；`ArticleServing` protocol 抽象真實 API 與假資料來源；`BookmarkStore` / `ReadingHistoryStore` 用 `@Observable + UserDefaults` 持久化本地資料。

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 17+), `@Observable`, `async/await`, `URLSession`, `WKWebView (UIViewRepresentable)`, `UserDefaults`

> ⚠️ **Windows 環境限制**：此計劃在 Windows 上撰寫所有 Swift 原始碼。標記「Verify on Mac」的步驟需在取得 Mac + Xcode 後執行。每個 Task 結束時 commit，讓 Mac 上可以直接 pull 並 build。

---

## 檔案結構

```
FuntimeBlog/                          ← Xcode target 根目錄
├── App/
│   └── FuntimeBlogApp.swift          # @main，注入全域 stores
├── Theme/
│   ├── AppTheme.swift                # 顏色、字體、間距、圓角常數
│   └── Color+Extensions.swift        # hex init、深淺模式 init
├── Components/
│   └── ViewModifiers.swift           # CardStyle、PressableCardStyle、GlassCircle
├── Models/
│   ├── Article.swift                 # Article struct（Identifiable, Hashable, Codable）
│   └── ArticleService.swift          # ArticleServing protocol、ArticlePage、ArticleQuery、Region、StaticArticleService
├── Data/
│   └── SampleData.swift              # 假資料（供 Preview）
├── Networking/
│   ├── FunTimeAPI.swift              # 底層 URLSession、proxy base URL、日期解析
│   └── BlogService.swift             # APIArticleService（實作 ArticleServing），含所有 DTO
├── Storage/
│   ├── BookmarkStore.swift           # @Observable，UserDefaults 持久化
│   └── ReadingHistoryStore.swift     # @Observable，UserDefaults 持久化
├── Views/
│   ├── RootTabView.swift             # TabView（4 tabs）
│   ├── Components/
│   │   ├── ArticleCard.swift         # ArticleCardView + ArticleCardLink
│   │   └── BookmarkButton.swift      # 書籤切換按鈕（toolbar + 卡片角落用）
│   ├── ArticleList/
│   │   ├── ArticleListViewModel.swift # 分頁 + 無限捲動 + 分類過濾
│   │   └── ArticleListView.swift     # 通用文章列表頁（Category/Search 共用）
│   ├── Home/
│   │   ├── HomeViewModel.swift
│   │   ├── HomeView.swift
│   │   ├── HeroCard.swift            # 首頁輪播大圖
│   │   └── PopularRow.swift          # 熱門文章列表列
│   ├── Article/
│   │   ├── ArticleHTML.swift         # HTML 頁面組裝 + CSS
│   │   ├── ArticleWebView.swift      # WKWebView UIViewRepresentable wrapper
│   │   ├── ArticleDetailViewModel.swift
│   │   └── ArticleDetailView.swift
│   ├── Category/
│   │   ├── CategoryViewModel.swift
│   │   └── CategoryView.swift        # DisclosureGroup 地區→城市樹，點城市→ArticleListView
│   ├── Search/
│   │   ├── SearchViewModel.swift     # 關鍵字搜尋 + 閱讀歷史
│   │   └── SearchView.swift
│   ├── Bookmark/
│   │   └── BookmarkView.swift
│   └── Author/
│       └── AuthorView.swift          # 作者頭像、簡介、該作者文章列表
```

---

## Task 1：Xcode 專案建立（Mac 操作）

**說明**：此 Task 需要在 Mac + Xcode 執行，Windows 上跳過，等有 Mac 後再補。其他 Tasks 只寫 Swift 原始碼，等 Mac 上完成此步驟後即可 build。

**Files:**
- Create: `FuntimeBlog.xcodeproj/`（Xcode 自動產生）
- Create: `FuntimeBlog/` 目錄結構

- [ ] **Step 1: 建立 Xcode 專案**

  File → New → Project → iOS → App，填入：
  - Product Name: `FuntimeBlog`
  - Organization Identifier: `com.funtime`
  - Bundle Identifier: `com.funtime.blog`
  - Interface: SwiftUI
  - Language: Swift
  - Minimum Deployment: iOS 17.0

- [ ] **Step 2: 建立資料夾結構**

  在 Xcode Project Navigator 中建立 Groups（不是 folder references）：
  `App` / `Theme` / `Components` / `Models` / `Data` / `Networking` / `Storage` / `Views/Components` / `Views/ArticleList` / `Views/Home` / `Views/Article` / `Views/Category` / `Views/Search` / `Views/Bookmark` / `Views/Author`

- [ ] **Step 3: 刪除 Xcode 自動產生的 ContentView.swift**

  刪除 `ContentView.swift`（會用我們的 `RootTabView` 取代）。

- [ ] **Step 4: 將後續 Tasks 的所有 .swift 檔加入 Xcode target**

  每新增一個檔案，確認 "Add to target: FuntimeBlog" 有勾選。

---

## Task 2：主題系統（AppTheme + Color extensions + ViewModifiers）

**Files:**
- Create: `FuntimeBlog/Theme/AppTheme.swift`
- Create: `FuntimeBlog/Theme/Color+Extensions.swift`
- Create: `FuntimeBlog/Components/ViewModifiers.swift`

- [ ] **Step 1: 建立 `Color+Extensions.swift`**

```swift
import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
```

- [ ] **Step 2: 建立 `AppTheme.swift`**

```swift
import SwiftUI

enum AppTheme {
    enum Color {
        static let primary      = SwiftUI.Color(hex: 0xF58900)
        static let primaryDark  = SwiftUI.Color(hex: 0xD97606)
        static let primaryLight = SwiftUI.Color(hex: 0xFFB04D)
        static let accent       = SwiftUI.Color(hex: 0x009E8E)
        static let accentLight  = SwiftUI.Color(hex: 0x2BC4B4)

        static let background   = SwiftUI.Color(light: SwiftUI.Color(hex: 0xF2F2F7),
                                                dark: SwiftUI.Color(hex: 0x121212))
        static let cardSurface  = SwiftUI.Color(light: .white,
                                                dark: SwiftUI.Color(hex: 0x1C1C1E))
        static let textPrimary  = SwiftUI.Color.primary
        static let textSecondary = SwiftUI.Color.secondary
    }

    enum Gradient {
        static let primary = LinearGradient(
            colors: [Color.primary, Color.primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Font {
        static let cardTitle     = SwiftUI.Font.title3.bold()
        static let sectionHeader = SwiftUI.Font.headline
        static let body          = SwiftUI.Font.body
        static let meta          = SwiftUI.Font.subheadline
        static let button        = SwiftUI.Font.headline
        static let tag           = SwiftUI.Font.caption.weight(.heavy)
    }

    enum Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 14
        static let card: CGFloat  = 22
        static let hero: CGFloat  = 18
    }
}
```

- [ ] **Step 3: 建立 `ViewModifiers.swift`**

```swift
import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .shadow(color: AppTheme.Color.primary.opacity(0.08), radius: 12, y: 6)
    }
}

struct GlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(8)
            .background(.ultraThinMaterial, in: Circle())
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
    func glassCircle() -> some View { modifier(GlassCircle()) }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add FuntimeBlog/Theme/ FuntimeBlog/Components/ViewModifiers.swift
git commit -m "feat: add AppTheme, Color extensions, ViewModifiers"
```

---

## Task 3：資料模型與服務 Protocol

**Files:**
- Create: `FuntimeBlog/Models/Article.swift`
- Create: `FuntimeBlog/Models/ArticleService.swift`

- [ ] **Step 1: 建立 `Article.swift`**

```swift
import Foundation

struct Article: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let author: String
    let authorSlug: String
    let date: Date
    let tags: [String]
    let coverSystemImageName: String
    let imageURL: URL?
    let slug: String
    let excerpt: String
    let contentHTML: String?

    init(
        id: String,
        title: String,
        author: String,
        authorSlug: String = "",
        date: Date,
        tags: [String],
        coverSystemImageName: String = "photo",
        imageURL: URL? = nil,
        slug: String = "",
        excerpt: String,
        contentHTML: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.authorSlug = authorSlug
        self.date = date
        self.tags = tags
        self.coverSystemImageName = coverSystemImageName
        self.imageURL = imageURL
        self.slug = slug
        self.excerpt = excerpt
        self.contentHTML = contentHTML
    }
}
```

- [ ] **Step 2: 建立 `ArticleService.swift`**

```swift
import Foundation

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
    var text: String?

    init(category: String? = nil,
         city: String? = nil,
         tag: String? = nil,
         text: String? = nil) {
        self.category = category
        self.city = city
        self.tag = tag
        self.text = text
    }
}

struct Region: Identifiable, Hashable {
    let id: Int
    let name: String
    let cities: [String]
}

struct AuthorProfile: Identifiable {
    let id: String
    let name: String
    let bio: String
    let avatarURL: URL?
}

protocol ArticleServing {
    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage
    func articleDetail(slug: String) async throws -> Article
    func regions() async throws -> [Region]
    func authorArticles(authorSlug: String, page: Int) async throws -> ArticlePage
}

struct StaticArticleService: ArticleServing {
    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage {
        var articles = SampleData.articles
        if let city = query.city, !city.isEmpty {
            articles = articles.filter { $0.tags.contains(city) }
        }
        if let category = query.category, !category.isEmpty {
            articles = articles.filter { $0.tags.contains(category) }
        }
        if let text = query.text, !text.isEmpty {
            articles = articles.filter {
                $0.title.localizedCaseInsensitiveContains(text)
                    || $0.excerpt.localizedCaseInsensitiveContains(text)
            }
        }
        return ArticlePage(articles: articles, page: 1, pageCount: 1)
    }

    func articleDetail(slug: String) async throws -> Article {
        SampleData.articles.first { $0.slug == slug || $0.id == slug }
            ?? SampleData.articles[0]
    }

    func regions() async throws -> [Region] {
        [
            Region(id: 41, name: "台灣", cities: ["台北", "台中", "台南", "高雄", "宜蘭", "花蓮"]),
            Region(id: 42, name: "日本", cities: ["東京", "關西", "北海道", "沖繩"]),
            Region(id: 43, name: "東南亞", cities: ["泰國", "越南", "馬來西亞"])
        ]
    }

    func authorArticles(authorSlug: String, page: Int) async throws -> ArticlePage {
        let articles = SampleData.articles.filter { $0.authorSlug == authorSlug }
        return ArticlePage(articles: articles, page: 1, pageCount: 1)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/Models/
git commit -m "feat: add Article model and ArticleServing protocol"
```

---

## Task 4：假資料（Preview 用）

**Files:**
- Create: `FuntimeBlog/Data/SampleData.swift`

- [ ] **Step 1: 建立 `SampleData.swift`**

```swift
import Foundation

enum SampleData {
    static let articles: [Article] = [
        Article(
            id: "1",
            title: "東京澀谷必去的 10 間居酒屋",
            author: "王小明",
            authorSlug: "wang-xiaoming",
            date: Date(timeIntervalSinceNow: -86400 * 2),
            tags: ["東京", "美食"],
            coverSystemImageName: "fork.knife",
            imageURL: nil,
            slug: "tokyo-izakaya-top10",
            excerpt: "澀谷的居酒屋文化是東京夜生活的縮影，這 10 間各有特色，從老字號到新潮融合料理應有盡有。"
        ),
        Article(
            id: "2",
            title: "台北信義區週末市集完整指南",
            author: "李小花",
            authorSlug: "li-xiaohua",
            date: Date(timeIntervalSinceNow: -86400 * 5),
            tags: ["台北", "文化"],
            coverSystemImageName: "bag",
            imageURL: nil,
            slug: "taipei-xinyi-market",
            excerpt: "每到週末，信義區的幾個市集聚集了設計師品牌、獨立書店和各式街頭小吃，是放鬆又能挖寶的好去處。"
        ),
        Article(
            id: "3",
            title: "沖繩慢旅：租台腳踏車環繞本島南部",
            author: "陳大山",
            authorSlug: "chen-dashan",
            date: Date(timeIntervalSinceNow: -86400 * 10),
            tags: ["沖繩", "旅遊"],
            coverSystemImageName: "bicycle",
            imageURL: nil,
            slug: "okinawa-cycling-south",
            excerpt: "沖繩南部的海岸線騎起來格外療癒，沿途有琉球文化遺址、傳統市場和無敵海景。"
        ),
        Article(
            id: "4",
            title: "花蓮太魯閣一日健行攻略",
            author: "張美麗",
            authorSlug: "zhang-meili",
            date: Date(timeIntervalSinceNow: -86400 * 15),
            tags: ["花蓮", "健行"],
            coverSystemImageName: "mountain.2",
            imageURL: nil,
            slug: "taroko-gorge-hiking",
            excerpt: "太魯閣峽谷的步道系統對第一次造訪的旅人也很友善，這份攻略從集合地點到返程接駁全部規劃好了。"
        ),
        Article(
            id: "5",
            title: "曼谷 Chatuchak 週末市集採購心得",
            author: "王小明",
            authorSlug: "wang-xiaoming",
            date: Date(timeIntervalSinceNow: -86400 * 20),
            tags: ["泰國", "購物"],
            coverSystemImageName: "cart",
            imageURL: nil,
            slug: "chatuchak-market-guide",
            excerpt: "號稱全球最大週末市集，15,000 個攤位讓人逛到腿軟，但掌握幾個技巧就能買到精品卻不超支。"
        )
    ]
}
```

- [ ] **Step 2: Commit**

```bash
git add FuntimeBlog/Data/SampleData.swift
git commit -m "feat: add sample data for SwiftUI previews"
```

---

## Task 5：網路層（FunTimeAPI + BlogService）

**Files:**
- Create: `FuntimeBlog/Networking/FunTimeAPI.swift`
- Create: `FuntimeBlog/Networking/BlogService.swift`

- [ ] **Step 1: 建立 `FunTimeAPI.swift`**

```swift
import Foundation

enum FunTimeAPI {
    static let proxyBase = URL(string: "https://www.funtime.com.tw/api/proxy/")!
    static let mediaHost = "https://mgmt.funtime.com.tw"

    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: mediaHost + path)
    }

    static func date(_ string: String?) -> Date {
        guard let string else { return Date() }
        return isoWithFraction.date(from: string)
            ?? isoPlain.date(from: string)
            ?? Date()
    }

    private static let isoWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain = ISO8601DateFormatter()

    static func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(
            url: proxyBase.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.badURL
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw APIError.badURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

enum APIError: LocalizedError {
    case badURL
    case badStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:             return "網址錯誤"
        case .badStatus(let c):   return "伺服器回應錯誤（\(c)）"
        case .decoding:           return "資料格式解析失敗"
        }
    }
}
```

- [ ] **Step 2: 建立 `BlogService.swift`**（含全部 DTO）

```swift
import Foundation

// MARK: - Shared DTOs

private struct ListResponseDTO<T: Decodable>: Decodable {
    let data: [T]
    let meta: MetaDTO
}

private struct MetaDTO: Decodable {
    let pagination: PaginationDTO
}

private struct PaginationDTO: Decodable {
    let page: Int
    let pageCount: Int
    let total: Int
}

private struct NamedDTO: Decodable {
    let name: String?
    let displayName: String?
}

private struct CoverDTO: Decodable {
    let url: String?
}

private struct AuthorDTO: Decodable {
    let name: String?
    let slug: String?
}

// MARK: - Article List DTO

private struct ArticleSummaryDTO: Decodable {
    let id: Int
    let title: String
    let excerpt: String?
    let slug: String
    let publishedAt: String?
    let cover: CoverDTO?
    let author: AuthorDTO?
    let theme: NamedDTO?
    let city: NamedDTO?

    func toArticle() -> Article {
        Article(
            id: String(id),
            title: title,
            author: author?.name ?? "FunTime",
            authorSlug: author?.slug ?? "",
            date: FunTimeAPI.date(publishedAt),
            tags: [theme?.displayName].compactMap { $0 },
            coverSystemImageName: "photo",
            imageURL: FunTimeAPI.imageURL(cover?.url),
            slug: slug,
            excerpt: excerpt ?? ""
        )
    }
}

// MARK: - Article Detail DTO

private struct ArticleDetailDTO: Decodable {
    let id: Int
    let title: String
    let excerpt: String?
    let slug: String
    let content: String?
    let publishedAt: String?
    let cover: CoverDTO?
    let author: AuthorDTO?
    let theme: NamedDTO?
    let category: NamedDTO?

    func toArticle() -> Article {
        let tags = [category?.displayName, theme?.displayName].compactMap { $0 }
        return Article(
            id: String(id),
            title: title,
            author: author?.name ?? "FunTime",
            authorSlug: author?.slug ?? "",
            date: FunTimeAPI.date(publishedAt),
            tags: tags,
            coverSystemImageName: "photo",
            imageURL: FunTimeAPI.imageURL(cover?.url),
            slug: slug,
            excerpt: excerpt ?? "",
            contentHTML: content
        )
    }
}

// MARK: - Region DTO

private struct RegionDTO: Decodable {
    let id: Int
    let displayName: String?
    let themes: [ThemeDTO]?

    struct ThemeDTO: Decodable {
        let displayName: String?
    }

    func toRegion() -> Region {
        Region(
            id: id,
            name: displayName ?? "",
            cities: (themes ?? []).compactMap { $0.displayName }
        )
    }
}

// MARK: - APIArticleService

struct APIArticleService: ArticleServing {
    private let pageSize = 20

    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "sort", value: "publishedAt:desc"),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)),
            URLQueryItem(name: "withExtraData", value: "true")
        ]
        if let category = query.category, !category.isEmpty {
            items.append(URLQueryItem(name: "filters[ft_category][display_name][$eq]", value: category))
        }
        if let city = query.city, !city.isEmpty {
            items.append(URLQueryItem(name: "filters[ft_theme][display_name][$eq]", value: city))
        }
        if let tag = query.tag, !tag.isEmpty {
            items.append(URLQueryItem(name: "filters[tags][name][$eq]", value: tag))
        }
        if let text = query.text, !text.isEmpty {
            items.append(URLQueryItem(name: "filters[title][$containsi]", value: text))
        }
        let response: ListResponseDTO<ArticleSummaryDTO> = try await FunTimeAPI.get("articles", query: items)
        return ArticlePage(
            articles: response.data.map { $0.toArticle() },
            page: response.meta.pagination.page,
            pageCount: response.meta.pagination.pageCount
        )
    }

    func articleDetail(slug: String) async throws -> Article {
        let dto: ArticleDetailDTO = try await FunTimeAPI.get("articles/slug/\(slug)")
        return dto.toArticle()
    }

    func regions() async throws -> [Region] {
        let dtos: [RegionDTO] = try await FunTimeAPI.get("ft-regions")
        return dtos.map { $0.toRegion() }.filter { !$0.cities.isEmpty }
    }

    func authorArticles(authorSlug: String, page: Int) async throws -> ArticlePage {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "filters[author][slug][$eq]", value: authorSlug),
            URLQueryItem(name: "sort", value: "publishedAt:desc"),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)),
            URLQueryItem(name: "withExtraData", value: "true")
        ]
        let response: ListResponseDTO<ArticleSummaryDTO> = try await FunTimeAPI.get("articles", query: items)
        return ArticlePage(
            articles: response.data.map { $0.toArticle() },
            page: response.meta.pagination.page,
            pageCount: response.meta.pagination.pageCount
        )
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/Networking/
git commit -m "feat: add FunTimeAPI client and BlogService (APIArticleService)"
```

---

## Task 6：本地儲存（BookmarkStore + ReadingHistoryStore）

**Files:**
- Create: `FuntimeBlog/Storage/BookmarkStore.swift`
- Create: `FuntimeBlog/Storage/ReadingHistoryStore.swift`

- [ ] **Step 1: 建立 `BookmarkStore.swift`**

```swift
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
```

- [ ] **Step 2: 建立 `ReadingHistoryStore.swift`**

```swift
import Foundation
import Observation

@Observable
final class ReadingHistoryStore {
    private static let storageKey = "readingHistory"
    private static let maxCount = 50
    private let defaults: UserDefaults

    private(set) var articles: [Article]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Article].self, from: data) {
            articles = decoded
        } else {
            articles = []
        }
    }

    func record(_ article: Article) {
        articles.removeAll { $0.id == article.id }
        articles.insert(article, at: 0)
        if articles.count > Self.maxCount {
            articles = Array(articles.prefix(Self.maxCount))
        }
        persist()
    }

    func clear() {
        articles = []
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(articles) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/Storage/
git commit -m "feat: add BookmarkStore and ReadingHistoryStore (UserDefaults)"
```

---

## Task 7：App 進入點與 Tab 導覽

**Files:**
- Create: `FuntimeBlog/App/FuntimeBlogApp.swift`
- Create: `FuntimeBlog/Views/RootTabView.swift`

- [ ] **Step 1: 建立 `FuntimeBlogApp.swift`**

```swift
import SwiftUI

@main
struct FuntimeBlogApp: App {
    @State private var bookmarkStore = BookmarkStore()
    @State private var historyStore = ReadingHistoryStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(bookmarkStore)
                .environment(historyStore)
        }
    }
}
```

- [ ] **Step 2: 建立 `RootTabView.swift`**

```swift
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("首頁", systemImage: "house")
            }

            NavigationStack {
                CategoryView()
            }
            .tabItem {
                Label("分類", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("搜尋", systemImage: "magnifyingglass")
            }

            NavigationStack {
                BookmarkView()
            }
            .tabItem {
                Label("書籤", systemImage: "bookmark")
            }
        }
        .tint(AppTheme.Color.primary)
        .fontDesign(.rounded)
    }
}

#Preview {
    RootTabView()
        .environment(BookmarkStore())
        .environment(ReadingHistoryStore())
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/App/ FuntimeBlog/Views/RootTabView.swift
git commit -m "feat: add app entry point and 4-tab RootTabView"
```

---

## Task 8：共用元件（ArticleCard + BookmarkButton）

**Files:**
- Create: `FuntimeBlog/Views/Components/ArticleCard.swift`
- Create: `FuntimeBlog/Views/Components/BookmarkButton.swift`

- [ ] **Step 1: 建立 `BookmarkButton.swift`**

```swift
import SwiftUI

struct BookmarkButton: View {
    let article: Article
    var circular: Bool = false
    @Environment(BookmarkStore.self) private var bookmarks

    var body: some View {
        Button {
            bookmarks.toggle(article)
        } label: {
            let isMarked = bookmarks.isBookmarked(article)
            if circular {
                Image(systemName: isMarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isMarked ? AppTheme.Color.primary : .secondary)
                    .glassCircle()
            } else {
                Image(systemName: isMarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isMarked ? AppTheme.Color.primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(bookmarks.isBookmarked(article) ? "取消書籤" : "加入書籤")
    }
}

#Preview {
    BookmarkButton(article: SampleData.articles[0], circular: true)
        .padding()
        .environment(BookmarkStore())
}
```

- [ ] **Step 2: 建立 `ArticleCard.swift`**

```swift
import SwiftUI

private let articleDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "zh_TW")
    f.dateStyle = .long
    f.timeStyle = .none
    return f
}()

struct ArticleCardView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .overlay { cover }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.hero))

            if let tag = article.tags.first {
                Text(tag.uppercased())
                    .font(AppTheme.Font.tag)
                    .foregroundStyle(AppTheme.Color.accent)
            }

            Text(article.title)
                .font(AppTheme.Font.cardTitle)
                .foregroundStyle(AppTheme.Color.textPrimary)
                .lineLimit(2)

            Text("\(article.author) · \(articleDateFormatter.string(from: article.date))")
                .font(AppTheme.Font.meta)
                .foregroundStyle(AppTheme.Color.textSecondary)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var cover: some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .empty:
                ZStack {
                    AppTheme.Gradient.primary
                    ProgressView().tint(.white)
                }
            default:
                ZStack {
                    AppTheme.Gradient.primary
                    Image(systemName: article.coverSystemImageName)
                        .resizable().scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }
}

struct ArticleCardLink: View {
    let article: Article

    var body: some View {
        NavigationLink(value: article) {
            ArticleCardView(article: article)
        }
        .buttonStyle(PressableCardStyle())
        .overlay(alignment: .topTrailing) {
            BookmarkButton(article: article, circular: true)
                .padding(AppTheme.Spacing.lg)
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ArticleCardLink(article: SampleData.articles[0])
                .padding(AppTheme.Spacing.lg)
        }
    }
    .environment(BookmarkStore())
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/Views/Components/
git commit -m "feat: add ArticleCard and BookmarkButton components"
```

---

## Task 9：文章列表（通用，ArticleList tab 與 Category 共用）

**Files:**
- Create: `FuntimeBlog/Views/ArticleList/ArticleListViewModel.swift`
- Create: `FuntimeBlog/Views/ArticleList/ArticleListView.swift`

- [ ] **Step 1: 建立 `ArticleListViewModel.swift`**

```swift
import Foundation
import Observation

@Observable
final class ArticleListViewModel {
    enum ViewState {
        case loading
        case loaded([Article])
        case failed(String)
    }

    private let service: ArticleServing
    private(set) var category: String?
    let city: String?
    let searchText: String?

    var state: ViewState = .loading
    private(set) var isLoadingMore = false

    private var articles: [Article] = []
    private var page = 0
    private var pageCount = 1

    init(service: ArticleServing = APIArticleService(),
         category: String? = nil,
         city: String? = nil,
         searchText: String? = nil) {
        self.service = service
        self.category = category
        self.city = city
        self.searchText = searchText
    }

    func load() async {
        state = .loading
        page = 0
        pageCount = 1
        articles = []
        await fetchNextPage()
    }

    func setCategory(_ newCategory: String?) async {
        guard newCategory != category else { return }
        category = newCategory
        await load()
    }

    func loadMoreIfNeeded(currentItem: Article) async {
        guard let last = articles.last, last.id == currentItem.id else { return }
        await fetchNextPage()
    }

    private func fetchNextPage() async {
        guard !isLoadingMore, page < pageCount else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let result = try await service.fetchArticles(
                page: page + 1,
                query: ArticleQuery(category: category,
                                    city: city,
                                    text: searchText)
            )
            page = result.page
            pageCount = result.pageCount
            articles += result.articles
            state = .loaded(articles)
        } catch {
            if articles.isEmpty {
                state = .failed("無法載入文章，請稍後再試。")
            }
        }
    }
}
```

- [ ] **Step 2: 建立 `ArticleListView.swift`**

```swift
import SwiftUI

struct ArticleListView: View {
    let title: String
    @State private var viewModel: ArticleListViewModel

    init(title: String = "",
         viewModel: ArticleListViewModel = ArticleListViewModel()) {
        self.title = title
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let articles):
                if articles.isEmpty {
                    ContentUnavailableView("沒有符合的文章",
                                          systemImage: "doc.text.magnifyingglass")
                        .frame(maxHeight: .infinity)
                } else {
                    articleList(articles)
                }

            case .failed(let message):
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.load() } }
                }
            }
        }
        .background(AppTheme.Color.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .task {
            if case .loading = viewModel.state { await viewModel.load() }
        }
    }

    private func articleList(_ articles: [Article]) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                ForEach(articles) { article in
                    ArticleCardLink(article: article)
                        .task { await viewModel.loadMoreIfNeeded(currentItem: article) }
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .refreshable { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        ArticleListView(
            title: "文章",
            viewModel: ArticleListViewModel(service: StaticArticleService())
        )
    }
    .environment(BookmarkStore())
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/Views/ArticleList/
git commit -m "feat: add ArticleListViewModel and ArticleListView with infinite scroll"
```

---

## Task 10：首頁（HomeView + HeroCard + PopularRow）

**Files:**
- Create: `FuntimeBlog/Views/Home/HomeViewModel.swift`
- Create: `FuntimeBlog/Views/Home/HomeView.swift`
- Create: `FuntimeBlog/Views/Home/HeroCard.swift`
- Create: `FuntimeBlog/Views/Home/PopularRow.swift`

- [ ] **Step 1: 建立 `HomeViewModel.swift`**

```swift
import Foundation
import Observation

@Observable
final class HomeViewModel {
    enum ViewState {
        case loading
        case loaded
        case failed(String)
    }

    private let service: ArticleServing
    private(set) var articles: [Article] = []
    var state: ViewState = .loading

    var heroArticles: [Article]    { Array(articles.prefix(5)) }
    var popularArticles: [Article] { Array(articles.dropFirst(5)) }

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let page = try await service.fetchArticles(page: 1, query: ArticleQuery())
            articles = page.articles
            state = page.articles.isEmpty ? .failed("目前沒有文章。") : .loaded
        } catch {
            state = .failed("無法載入首頁內容，請稍後再試。")
        }
    }
}
```

- [ ] **Step 2: 建立 `HeroCard.swift`**

```swift
import SwiftUI

struct HeroCard: View {
    let article: Article
    var topInset: CGFloat = 0

    private let baseHeight: CGFloat = 300

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: baseHeight + topInset)
            .overlay { cover }
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) { caption }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if let tag = article.tags.first {
                Text(tag.uppercased())
                    .font(AppTheme.Font.tag)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            Text(article.title)
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(.white)
                .lineLimit(3)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
            Text(article.date.formatted(.dateTime.month().day()))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var cover: some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .empty:
                ZStack { AppTheme.Gradient.primary; ProgressView().tint(.white) }
            default:
                ZStack {
                    AppTheme.Gradient.primary
                    Image(systemName: article.coverSystemImageName)
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }
}

#Preview {
    HeroCard(article: SampleData.articles[0])
        .frame(height: 300)
}
```

- [ ] **Step 3: 建立 `PopularRow.swift`**

```swift
import SwiftUI

private let popularRowFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "zh_TW")
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

struct PopularRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Color.clear
                .frame(width: 80, height: 80)
                .overlay { thumbnail }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                if let tag = article.tags.first {
                    Text(tag.uppercased())
                        .font(AppTheme.Font.tag)
                        .foregroundStyle(AppTheme.Color.accent)
                }
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.textPrimary)
                    .lineLimit(2)
                Text(popularRowFormatter.string(from: article.date))
                    .font(.caption)
                    .foregroundStyle(AppTheme.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var thumbnail: some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                AppTheme.Gradient.primary
            }
        }
    }
}

#Preview {
    PopularRow(article: SampleData.articles[0])
        .padding()
}
```

- [ ] **Step 4: 建立 `HomeView.swift`**

```swift
import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        GeometryReader { proxy in
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    content(topInset: proxy.safeAreaInsets.top)
                case .failed(let message):
                    ContentUnavailableView {
                        Label("載入失敗", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("重試") { Task { await viewModel.load() } }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Color.background)
            .ignoresSafeArea(edges: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .task {
            if case .loading = viewModel.state { await viewModel.load() }
        }
    }

    private func content(topInset: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                heroCarousel(topInset: topInset)

                if !viewModel.popularArticles.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("熱門文章")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(AppTheme.Color.textPrimary)

                        ForEach(viewModel.popularArticles) { article in
                            NavigationLink(value: article) {
                                PopularRow(article: article)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
        }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private func heroCarousel(topInset: CGFloat) -> some View {
        let heroes = viewModel.heroArticles
        if !heroes.isEmpty {
            TabView {
                ForEach(heroes) { article in
                    NavigationLink(value: article) {
                        HeroCard(article: article, topInset: topInset)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .frame(height: 300 + topInset)
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
```

- [ ] **Step 5: Commit**

```bash
git add FuntimeBlog/Views/Home/
git commit -m "feat: add HomeView with hero carousel and popular articles list"
```

---

## Task 11：文章詳細頁（ArticleHTML + ArticleWebView + ViewModel + View）

**Files:**
- Create: `FuntimeBlog/Views/Article/ArticleHTML.swift`
- Create: `FuntimeBlog/Views/Article/ArticleWebView.swift`
- Create: `FuntimeBlog/Views/Article/ArticleDetailViewModel.swift`
- Create: `FuntimeBlog/Views/Article/ArticleDetailView.swift`

- [ ] **Step 1: 建立 `ArticleHTML.swift`**（HTML 頁面組裝器，含 CSS 與視差 JS）

```swift
import Foundation

enum ArticleHTML {
    static func sanitize(_ html: String) -> String {
        html.replacingOccurrences(
            of: #"color\s*:\s*(#0{3}(?:0{3})?|black)\b"#,
            with: "color:inherit",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    static func page(title: String,
                     author: String,
                     dateText: String,
                     tags: [String],
                     coverURL: URL?,
                     contentHTML: String) -> String {
        let cover = coverURL?.absoluteString
        let bgStyle = cover.map { "background-image:url('\($0)');" } ?? ""
        let bgClass = cover == nil ? "hero__bg hero__bg--fallback" : "hero__bg"
        let tagsHTML = tags.map { "<span class=\"tag\">\($0)</span>" }.joined()
        let body = sanitize(contentHTML)

        return """
        <!doctype html>
        <html lang="zh-Hant">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
        <style>
          :root { color-scheme: light dark; --fg:#1c1c1e; --fg2:#6b6b70; --bg:#ffffff; --accent:#F58900; }
          @media (prefers-color-scheme: dark) { :root { --fg:#e9e9ec; --fg2:#9b9ba0; --bg:#121212; } }
          * { box-sizing: border-box; }
          html, body { margin:0; padding:0; background:var(--bg); }
          body {
            font-family: "PingFang TC", -apple-system, system-ui, sans-serif;
            font-size: 18px; line-height: 1.8; color: var(--fg);
            -webkit-text-size-adjust: 100%; word-break: break-word;
          }
          .hero { position: relative; width: 100%; aspect-ratio: 4/5;
                  display: flex; align-items: flex-end; overflow: hidden; }
          .hero__bg { position:absolute; inset:0; z-index:0;
                      background-size:cover; background-position:center; will-change:transform; }
          .hero__bg--fallback { background: linear-gradient(135deg,#F58900,#FFB04D); }
          .hero::after { content:""; position:absolute; inset:0; z-index:1;
                         background: linear-gradient(to bottom, transparent 35%, rgba(0,0,0,.75)); }
          .hero .meta { position:relative; z-index:2; padding:20px; color:#fff; }
          .hero h1 { font-size:26px; line-height:1.3; margin:8px 0 6px; font-weight:800; }
          .hero .byline { font-size:14px; opacity:.9; }
          .tags { display:flex; flex-wrap:wrap; gap:6px; }
          .tag { font-size:12px; font-weight:700; padding:4px 10px; border-radius:999px;
                 background:rgba(255,255,255,.22); -webkit-backdrop-filter:blur(8px); backdrop-filter:blur(8px); }
          article { padding: 20px 18px 48px; }
          article p { margin: 0 0 18px; }
          article img, article iframe, article video {
            max-width:100%; height:auto; border-radius:12px; display:block; margin:18px auto; }
          article h2 { font-size:22px; line-height:1.4; margin:28px 0 12px; font-weight:800; }
          article h3 { font-size:19px; line-height:1.4; margin:24px 0 10px; font-weight:700; }
          article a { color:var(--accent); text-decoration:none; }
          article ul, article ol { padding-left:1.3em; }
          article table { width:100%; border-collapse:collapse; display:block;
                          overflow-x:auto; -webkit-overflow-scrolling:touch; }
          article ::-webkit-scrollbar { width:0; height:0; display:none; }
          article .t2 { color:var(--fg); }
        </style>
        </head>
        <body>
          <header class="hero">
            <div class="\(bgClass)" style="\(bgStyle)"></div>
            <div class="meta">
              <div class="tags">\(tagsHTML)</div>
              <h1>\(title)</h1>
              <div class="byline">\(author) · \(dateText)</div>
            </div>
          </header>
          <article>\(body)</article>
          <script>
          window.__heroScroll = function(y) {
            var bg = document.querySelector('.hero__bg');
            var hero = document.querySelector('.hero');
            if (!bg || !hero) return;
            if (y < 0) {
              var h = hero.offsetHeight || 1;
              bg.style.transformOrigin = 'top center';
              bg.style.transform = 'translateY(' + y + 'px) scale(' + ((h - y) / h) + ')';
            } else {
              bg.style.transformOrigin = 'center';
              bg.style.transform = 'translate3d(0,' + (y * 0.5) + 'px,0)';
            }
          };
          </script>
        </body>
        </html>
        """
    }
}
```

- [ ] **Step 2: 建立 `ArticleWebView.swift`**（WKWebView wrapper）

```swift
import SwiftUI
import WebKit
import UIKit

struct ArticleReaderView: UIViewRepresentable {
    let html: String
    var onOpenLink: (URL) -> Void = { _ in }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        let data = Data(html.utf8)
        webView.load(data,
                     mimeType: "text/html",
                     characterEncodingName: "UTF-8",
                     baseURL: URL(string: "https://www.funtime.com.tw")!)
    }

    func makeCoordinator() -> Coordinator { Coordinator(onOpenLink: onOpenLink) }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var loadedHTML: String?
        let onOpenLink: (URL) -> Void
        weak var webView: WKWebView?

        init(onOpenLink: @escaping (URL) -> Void) {
            self.onOpenLink = onOpenLink
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let y = scrollView.contentOffset.y
            webView?.evaluateJavaScript("window.__heroScroll && window.__heroScroll(\(y))")
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                onOpenLink(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
```

- [ ] **Step 3: 建立 `ArticleDetailViewModel.swift`**

```swift
import Foundation
import Observation

@Observable
final class ArticleDetailViewModel {
    enum ContentState {
        case loading
        case loaded(String)
        case failed(String)
    }

    let summary: Article
    private let service: ArticleServing
    var contentState: ContentState = .loading

    init(article: Article, service: ArticleServing = APIArticleService()) {
        self.summary = article
        self.service = service
    }

    func load() async {
        if let html = summary.contentHTML, !html.isEmpty {
            contentState = .loaded(html)
            return
        }
        guard !summary.slug.isEmpty else {
            contentState = .loaded("<p>\(summary.excerpt)</p>")
            return
        }
        contentState = .loading
        do {
            let full = try await service.articleDetail(slug: summary.slug)
            contentState = .loaded(full.contentHTML ?? "<p>\(full.excerpt)</p>")
        } catch {
            contentState = .failed("無法載入文章內容，請稍後再試。")
        }
    }
}
```

- [ ] **Step 4: 建立 `ArticleDetailView.swift`**

```swift
import SwiftUI

struct ArticleDetailView: View {
    @State private var viewModel: ArticleDetailViewModel
    @Environment(\.openURL) private var openURL
    @Environment(ReadingHistoryStore.self) private var historyStore

    init(article: Article) {
        _viewModel = State(initialValue: ArticleDetailViewModel(article: article))
    }

    private var article: Article { viewModel.summary }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        Group {
            switch viewModel.contentState {
            case .loading:
                ProgressView()
            case .loaded(let html):
                ArticleReaderView(html: page(content: html),
                                  onOpenLink: { openURL($0) })
            case .failed(let message):
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.load() } }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Color.background)
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                BookmarkButton(article: article)
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: article.title)
            }
        }
        .navigationDestination(for: AuthorNavigation.self) { nav in
            AuthorView(authorSlug: nav.slug, authorName: nav.name)
        }
        .task {
            await viewModel.load()
            historyStore.record(article)
        }
    }

    private func page(content: String) -> String {
        ArticleHTML.page(
            title: article.title,
            author: article.author,
            dateText: Self.dateFormatter.string(from: article.date),
            tags: article.tags,
            coverURL: article.imageURL,
            contentHTML: content
        )
    }
}

struct AuthorNavigation: Hashable {
    let slug: String
    let name: String
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: SampleData.articles[0])
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
```

- [ ] **Step 5: Commit**

```bash
git add FuntimeBlog/Views/Article/
git commit -m "feat: add ArticleDetailView with WKWebView, bookmark, share, reading history"
```

---

## Task 12：分類瀏覽（CategoryView）

**Files:**
- Create: `FuntimeBlog/Views/Category/CategoryViewModel.swift`
- Create: `FuntimeBlog/Views/Category/CategoryView.swift`

- [ ] **Step 1: 建立 `CategoryViewModel.swift`**

```swift
import Foundation
import Observation

@Observable
final class CategoryViewModel {
    enum ViewState {
        case loading
        case loaded
        case failed(String)
    }

    private let service: ArticleServing
    private(set) var regions: [Region] = []
    var state: ViewState = .loading

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            regions = try await service.regions()
            state = regions.isEmpty ? .failed("沒有可瀏覽的分類。") : .loaded
        } catch {
            state = .failed("無法載入分類，請稍後再試。")
        }
    }
}
```

- [ ] **Step 2: 建立 `CategoryView.swift`**

```swift
import SwiftUI

struct CategoryView: View {
    @State private var viewModel = CategoryViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                regionList
            case .failed(let message):
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.load() } }
                }
            }
        }
        .background(AppTheme.Color.background)
        .navigationTitle("分類")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: CityNavigation.self) { nav in
            ArticleListView(
                title: nav.city,
                viewModel: ArticleListViewModel(city: nav.city)
            )
        }
        .task {
            if case .loading = viewModel.state { await viewModel.load() }
        }
    }

    private var regionList: some View {
        List {
            ForEach(viewModel.regions) { region in
                DisclosureGroup {
                    let columns = [GridItem(.adaptive(minimum: 92), spacing: AppTheme.Spacing.sm)]
                    LazyVGrid(columns: columns, spacing: AppTheme.Spacing.sm) {
                        ForEach(region.cities, id: \.self) { city in
                            NavigationLink(value: CityNavigation(city: city)) {
                                CityChip(name: city)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                } label: {
                    Text(region.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppTheme.Color.textPrimary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct CityChip: View {
    let name: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .font(.subheadline)
                .foregroundStyle(AppTheme.Color.primary)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(AppTheme.Color.primary.opacity(0.15), lineWidth: 1)
        }
    }
}

struct CityNavigation: Hashable {
    let city: String
}

#Preview {
    NavigationStack {
        CategoryView()
    }
    .environment(BookmarkStore())
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/Views/Category/
git commit -m "feat: add CategoryView with DisclosureGroup region/city browser"
```

---

## Task 13：搜尋（SearchView - 關鍵字搜尋 + 閱讀歷史）

**Files:**
- Create: `FuntimeBlog/Views/Search/SearchViewModel.swift`
- Create: `FuntimeBlog/Views/Search/SearchView.swift`

- [ ] **Step 1: 建立 `SearchViewModel.swift`**

```swift
import Foundation
import Observation

@Observable
final class SearchViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded([Article])
        case failed(String)
    }

    private let service: ArticleServing
    var query: String = ""
    var state: ViewState = .idle

    private var searchTask: Task<Void, Never>?

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func onQueryChanged() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await search(text: trimmed)
        }
    }

    private func search(text: String) async {
        state = .loading
        do {
            let page = try await service.fetchArticles(
                page: 1,
                query: ArticleQuery(text: text)
            )
            state = .loaded(page.articles)
        } catch {
            state = .failed("搜尋失敗，請稍後再試。")
        }
    }
}
```

- [ ] **Step 2: 建立 `SearchView.swift`**

```swift
import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(ReadingHistoryStore.self) private var historyStore

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                historySection
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let articles):
                if articles.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else {
                    resultList(articles)
                }
            case .failed(let message):
                ContentUnavailableView {
                    Label("搜尋失敗", systemImage: "exclamationmark.triangle")
                } description: { Text(message) }
            }
        }
        .background(AppTheme.Color.background)
        .navigationTitle("搜尋")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.query, prompt: "搜尋文章標題")
        .onChange(of: viewModel.query) { viewModel.onQueryChanged() }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let history = historyStore.articles
        if history.isEmpty {
            ContentUnavailableView {
                Label("還沒有閱讀紀錄", systemImage: "clock")
            } description: {
                Text("讀過的文章會顯示在這裡。")
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Text("最近閱讀")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(AppTheme.Color.textPrimary)
                        Spacer()
                        Button("清除") { historyStore.clear() }
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.Color.primary)
                    }

                    LazyVStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(history) { article in
                            NavigationLink(value: article) {
                                HistoryRow(article: article)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
        }
    }

    private func resultList(_ articles: [Article]) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                ForEach(articles) { article in
                    ArticleCardLink(article: article)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
}

private struct HistoryRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Color.clear
                .frame(width: 64, height: 64)
                .overlay {
                    AsyncImage(url: article.imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            AppTheme.Gradient.primary
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.textPrimary)
                    .lineLimit(2)
                Text(article.author)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Color.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
```

- [ ] **Step 3: Commit**

```bash
git add FuntimeBlog/Views/Search/
git commit -m "feat: add SearchView with debounced keyword search and reading history"
```

---

## Task 14：書籤頁（BookmarkView）

**Files:**
- Create: `FuntimeBlog/Views/Bookmark/BookmarkView.swift`

- [ ] **Step 1: 建立 `BookmarkView.swift`**

```swift
import SwiftUI

struct BookmarkView: View {
    @Environment(BookmarkStore.self) private var bookmarks

    var body: some View {
        let items = bookmarks.articles
        Group {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("還沒有書籤", systemImage: "bookmark")
                        .foregroundStyle(AppTheme.Color.primary)
                } description: {
                    Text("點文章上的書籤圖示，就能把文章存起來。")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.lg) {
                        ForEach(items) { article in
                            ArticleCardLink(article: article)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        bookmarks.toggle(article)
                                    } label: {
                                        Label("移除", systemImage: "bookmark.slash")
                                    }
                                }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
        }
        .background(AppTheme.Color.background)
        .navigationTitle("書籤")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }
}

#Preview {
    let store = BookmarkStore()
    store.toggle(SampleData.articles[0])
    store.toggle(SampleData.articles[1])
    return NavigationStack {
        BookmarkView()
    }
    .environment(store)
    .environment(ReadingHistoryStore())
}
```

- [ ] **Step 2: Commit**

```bash
git add FuntimeBlog/Views/Bookmark/BookmarkView.swift
git commit -m "feat: add BookmarkView with swipe-to-remove"
```

---

## Task 15：作者頁（AuthorView）

**Files:**
- Create: `FuntimeBlog/Views/Author/AuthorView.swift`

- [ ] **Step 1: 建立 `AuthorView.swift`**

```swift
import SwiftUI
import Observation

@Observable
private final class AuthorViewModel {
    enum ViewState {
        case loading
        case loaded([Article])
        case failed(String)
    }

    private let service: ArticleServing
    let authorSlug: String
    let authorName: String
    var state: ViewState = .loading

    init(authorSlug: String,
         authorName: String,
         service: ArticleServing = APIArticleService()) {
        self.authorSlug = authorSlug
        self.authorName = authorName
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let page = try await service.authorArticles(authorSlug: authorSlug, page: 1)
            state = .loaded(page.articles)
        } catch {
            state = .failed("無法載入作者文章。")
        }
    }
}

struct AuthorView: View {
    let authorSlug: String
    let authorName: String
    @State private var viewModel: AuthorViewModel

    init(authorSlug: String, authorName: String) {
        self.authorSlug = authorSlug
        self.authorName = authorName
        _viewModel = State(initialValue: AuthorViewModel(authorSlug: authorSlug,
                                                         authorName: authorName))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                authorHeader
                Divider()
                articlesSection
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Color.background)
        .navigationTitle(authorName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .task { await viewModel.load() }
    }

    private var authorHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.Gradient.primary)
                    .frame(width: 80, height: 80)
                Text(String(authorName.prefix(1)))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(authorName)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(AppTheme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.lg)
    }

    @ViewBuilder
    private var articlesSection: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .loaded(let articles):
            if articles.isEmpty {
                Text("這位作者還沒有文章。")
                    .foregroundStyle(AppTheme.Color.textSecondary)
            } else {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    ForEach(articles) { article in
                        ArticleCardLink(article: article)
                    }
                }
            }
        case .failed(let message):
            Text(message)
                .foregroundStyle(AppTheme.Color.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        AuthorView(authorSlug: "wang-xiaoming", authorName: "王小明")
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
```

- [ ] **Step 2: Commit**

```bash
git add FuntimeBlog/Views/Author/AuthorView.swift
git commit -m "feat: add AuthorView with author profile and article list"
```

---

## Task 16：Mac 上驗證（需要 Xcode）

此 Task 在拿到 Mac 後執行。

- [ ] **Step 1: git pull 取得所有檔案**

```bash
git pull origin master
```

- [ ] **Step 2: 開啟 `FuntimeBlog.xcodeproj`，將所有 Tasks 2–15 的 .swift 檔加入 Xcode target**

  在 Project Navigator 中：選取所有新增的 .swift 檔 → File Inspector → Target Membership → 勾選 FuntimeBlog。

- [ ] **Step 3: 設定 Minimum Deployment Target**

  Project Settings → Deployment Info → iOS 17.0

- [ ] **Step 4: Build（⌘B）確認無編譯錯誤**

  Verify on Mac: 預期 Build Succeeded，無 error。

- [ ] **Step 5: 在 iPhone 16 模擬器（iOS 18）執行**

  Verify on Mac:
  - 首頁 Hero 輪播正常載入
  - 分類頁 DisclosureGroup 展開
  - 搜尋：空白時顯示歷史，輸入後顯示結果
  - 書籤：加入/移除、滑動刪除
  - 文章詳細頁：WKWebView 渲染正常、封面視差效果
  - 作者頁：點文章作者名稱可導覽到作者頁

- [ ] **Step 6: Commit（如有修正）**

```bash
git add -A
git commit -m "fix: resolve Xcode build issues found during Mac verification"
```

---

## 設計決策說明

| 規格書 | 本計劃採用 | 原因 |
|--------|-----------|------|
| API: Cloudflare Worker 直連 | Proxy: `funtime.com.tw/api/proxy/` | 參考 repo 驗證可用，auth 由 proxy 處理 |
| 本地儲存: SwiftData | `UserDefaults + @Observable` | 更簡單，參考 repo 已驗證，SwiftData 需較多 boilerplate |
| Tab API: 規格未指定 | `tabItem` modifier（iOS 17 相容） | `Tab()` 為 iOS 18+ API，維持 iOS 17 最低支援 |
| 書籤圖示: `FavoritesStore` | `BookmarkStore`（bookmark.fill） | 對齊規格書命名（書籤，非愛心收藏） |
| 搜尋: 城市瀏覽 | 關鍵字文章搜尋（title contains） | 規格書明確要求關鍵字搜尋，城市瀏覽移至分類 Tab |
