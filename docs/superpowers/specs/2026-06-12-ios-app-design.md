# FunTime Blog iOS App — 設計規格

> 建立日期：2026-06-12
> 最後更新：2026-06-16（iOS HIG 細節補強）

---

## 專案目標

將 FunTime 網站的部落格功能做成 iOS 原生 App。iOS 版與 Android 版在功能上大致一致，但各自遵循所在平台的系統特性與 UI 框架慣例，不刻意對標彼此的實作細節。

---

## 技術棧

| 項目 | 決定 |
|---|---|
| 語言 | Swift 5.9+ |
| UI 框架 | SwiftUI |
| 最低支援 iOS | iOS 17 |
| 狀態管理 | `@Observable`（iOS 17 原生） |
| 本地儲存 | UserDefaults + Codable（書籤、閱讀歷史） |
| 網路層 | URLSession + async/await |
| 文章內容渲染 | WKWebView |
| 後端 | `https://www.funtime.com.tw/api/proxy/`（token 由 proxy 管，前端不帶授權 header） |

> **為何用 UserDefaults 而非 SwiftData**：書籤與閱讀歷史筆數不多、不需複雜查詢，`UserDefaults + JSONEncoder` 更輕量，也不需要 `ModelContainer` 注入，SwiftUI Preview 設置更容易。待 Phase 2 有複雜資料需求再評估引入 SwiftData。

---

## 架構模式：MVVM + Repository

```
SwiftUI View
    ↓
@Observable ViewModel（狀態管理）
    ↓
Repository（抽象資料來源）
    ↓
ArticleServing protocol
    ├── APIArticleService（真實 API）
    │       ↓ DTO → Domain Model 轉換
    │   FunTimeAPI（URLSession、URL 組裝、JSON 解碼）
    └── StaticArticleService（假資料，供 Preview 使用）
```

每層職責：
- **View**：純 UI，只讀 ViewModel 狀態，不含商業邏輯
- **ViewModel**：管理畫面狀態，協調 Repository 呼叫
- **Repository**：決定資料來自 API 還是本地，對 ViewModel 隱藏細節
- **ArticleServing**：定義資料來源 protocol，讓真實 API 與假資料可互換
- **APIArticleService**：實作 `ArticleServing`；內部 DTO → domain model 轉換，API 格式變動只需改這裡
- **StaticArticleService**：假資料實作，供 SwiftUI Preview 與開發初期使用
- **FunTimeAPI**：URLSession 底層、URL 組裝（含 proxy base）、JSON 解碼、圖片 URL 轉換

---

## 專案結構

```
FuntimeBlog/
├── App/
│   └── FuntimeBlogApp.swift
│
├── Networking/
│   ├── FunTimeAPI.swift            # URLSession、proxy base URL、imageURL 輔助、ISO8601 日期解析
│   ├── BlogService.swift           # ArticleServing protocol + StaticArticleService
│   ├── APIArticleService.swift     # 真實 API 實作（含 DTO 定義與轉換）
│   └── Models/                     # Domain model（非 DTO）
│       ├── Article.swift           # Article、ArticlePage、ArticleQuery
│       ├── Region.swift            # Region（地區／城市清單）
│       └── Author.swift
│
├── Storage/                        # UserDefaults + Codable
│   ├── FavoritesStore.swift        # @Observable，書籤持久化
│   └── ReadingHistoryStore.swift   # @Observable，閱讀歷史持久化
│
├── Theme/
│   ├── AppTheme.swift              # Color、Gradient、Font、Spacing、Radius 命名空間
│   ├── Color+Theme.swift           # Color(hex:) 與 Color(light:dark:) 擴充
│   └── ViewModifiers.swift         # CardStyle、GlassCircle、PressableCardStyle
│
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── ArticleDetailViewModel.swift
│   ├── CategoryViewModel.swift
│   ├── SearchViewModel.swift
│   └── FavoritesViewModel.swift
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ArticleCard.swift
│   ├── Article/
│   │   ├── ArticleDetailView.swift
│   │   ├── ArticleReaderView.swift  # WKWebView UIViewRepresentable（視差、深色模式）
│   │   └── ArticleHTML.swift        # HTML 頁面組裝與 CSS（含 sanitize）
│   ├── Category/
│   │   ├── CategoryView.swift
│   │   └── CategoryArticleListView.swift
│   ├── Search/
│   │   └── SearchView.swift
│   ├── Favorites/
│   │   └── FavoritesView.swift
│   └── Components/
│       └── ArticleRow.swift        # 可重用文章列表 cell
│
└── worker/                         # Cloudflare Worker（與 Android repo 共用邏輯）
```

---

## 導覽結構

`TabView` 搭配各 Tab 獨立的 `NavigationStack`，切換 Tab 不影響彼此的導覽狀態。`.tint(AppTheme.Color.primary)` 套用品牌橘色於整個 TabView。`.fontDesign(.rounded)` 套用於整個 TabView，讓字體有圓潤感。

**點已選 Tab 回頂部**：再次點擊已在的 Tab 時捲回列表頂部（與 Safari、App Store 行為一致）。需在各 Tab 的根 View 監聽 Tab 選取狀態，偵測到重複點擊時呼叫 `ScrollViewProxy.scrollTo`。

```
TabView
├── 首頁 Tab（SF Symbol: flame.fill）
│   └── NavigationStack
│       ├── HomeView
│       │   └── .searchable()       ← 搜尋整合於導覽列
│       └── ArticleDetailView
│           └── AuthorView
│
├── 分類 Tab（SF Symbol: square.grid.2x2）
│   └── NavigationStack
│       ├── CategoryView
│       └── CategoryArticleListView
│           └── ArticleDetailView
│
├── 搜尋 Tab（SF Symbol: magnifyingglass）
│   └── NavigationStack
│       └── SearchView
│           └── ArticleDetailView
│
└── 收藏 Tab（SF Symbol: heart.fill）
    └── NavigationStack
        ├── FavoritesView
        └── ArticleDetailView
```

---

## 畫面規格

### HomeView
- 大標題導覽列（`.navigationBarTitleDisplayMode(.large)`）
- Segmented Control 切換「最新」／「熱門」
- 無限捲動（距底部時自動載入下一頁）
- `.refreshable()` 下拉更新（重新載入第一頁）
- `.searchable()` 整合，輸入時直接顯示搜尋結果
- `.scrollDismissesKeyboard(.interactively)` 滾動時鍵盤跟手收起
- 文章卡片顯示：封面圖（`AsyncImage` + 佔位色塊）、標題、作者、日期
- 載入中：卡片骨架（`redacted(.placeholder)`）或 `ProgressView`
- 載入失敗：`ContentUnavailableView` + 重試按鈕

### ArticleDetailView
- 全螢幕 `ArticleReaderView`（WKWebView）渲染文章 HTML
- **視差滾動**：`scrollViewDidScroll` 把原生 `contentOffset.y` 餵給 JS，封面以半速位移
- **下拉回彈放大**：`y < 0` 時封面以 `scale()` 放大填滿，產生彈性 header 效果
- **深色模式**：CSS `color-scheme: light dark` + CSS 變數 `--fg`/`--bg`，無需額外偵測
- **HTML 消毒**：移除 CMS 硬編的 `color:#000000`，防止深色模式文字不可見
- **強制 UTF-8**：用 `load(_:mimeType:characterEncodingName:baseURL:)` 避免中文亂碼
- **封面 Hero**：4/5 aspect ratio，底部漸層遮罩，標題／作者／tag 浮在上方
- 透明導覽列（`.toolbarBackground(.hidden)`），右側書籤（`heart`/`heart.fill`）與分享按鈕
- 書籤切換時觸發觸覺回饋：`.sensoryFeedback(.impact(weight: .medium), trigger: isFavorite)`
- 進入頁面時自動寫入閱讀歷史
- 右滑返回（系統內建）

### CategoryView
- `DisclosureGroup` 展開式清單：地區 → 城市（主題）
- 點選城市進入 `CategoryArticleListView`（傳入 `ArticleQuery`）
- 載入中：`ProgressView` 置中；載入失敗：`ContentUnavailableView` + 重試

### SearchView
- 搜尋欄為主體
- `.scrollDismissesKeyboard(.interactively)` 滾動時鍵盤跟手收起
- 無輸入時顯示閱讀歷史（含清除全部按鈕）
- 有輸入時顯示搜尋結果，支援無限捲動
- 無結果時：`ContentUnavailableView("找不到相關文章", systemImage: "magnifyingglass")`

### FavoritesView
- 已收藏文章列表（最新收藏在前）
- `.swipeActions` 滑動刪除（iOS 原生手勢）；刪除時觸發觸覺回饋
- 空狀態：`ContentUnavailableView("尚無收藏", systemImage: "heart")`

### CategoryArticleListView
- 大標題顯示城市名稱
- 文章列表（`ArticleRow`），無限捲動
- `.refreshable()` 下拉更新
- 空狀態：`ContentUnavailableView("此分類尚無文章", systemImage: "tray")`

### AuthorView
- 作者頭像、名稱、簡介
- 該作者的文章列表

---

## 圖片載入

封面圖使用 `AsyncImage`，搭配佔位色塊避免版面跳動：

```swift
AsyncImage(url: article.imageURL) { phase in
    switch phase {
    case .success(let image):
        image.resizable().scaledToFill()
    case .failure, .empty:
        AppTheme.Color.cardSurface  // 佔位色塊
    @unknown default:
        AppTheme.Color.cardSurface
    }
}
```

> **Phase 1 使用 `AsyncImage`**：內建快取（`URLCache`）在同一 session 內有效，對部落格閱讀場景夠用。若未來滑動效能不理想，再引入 Kingfisher 或 Nuke。

---

## Dynamic Type（無障礙字體）

- SwiftUI 原生元件（`Text`、`Label`）使用 `AppTheme.Font` 定義的語意字體（`.title3`、`.body` 等），系統自動跟隨 Dynamic Type。
- WKWebView 內文 CSS 使用 `font-size: clamp(16px, 4.5vw, 20px)`，在小螢幕和大字體設定下都能保持可讀性，但 WKWebView 本身不跟隨 Dynamic Type，屬已知限制。

---

## Theme 系統

統一使用 `AppTheme` 命名空間，避免 magic number 散落各處：

```swift
AppTheme.Color.primary       // #F58900 品牌橘，深淺模式固定
AppTheme.Color.accent        // #009E8E 品牌青
AppTheme.Color.background    // 自動深淺（淺：#F2F2F7 / 深：#121212）
AppTheme.Color.cardSurface   // 自動深淺（淺：white / 深：#1C1C1E）

AppTheme.Spacing.lg          // 16pt（常用卡片內距）
AppTheme.Radius.card         // 22pt（卡片圓角）
```

可重用 ViewModifier：
- `.cardStyle()`：卡片底色 + 圓角 + 陰影
- `.primaryButtonStyle()`：橘底白字膠囊按鈕
- `.glassCircle()`：毛玻璃圓形背景（封面浮層圖示鈕）
- `PressableCardStyle`：按壓微縮彈性回饋（取代 `.plain`）

---

## 後端 API

透過 proxy 存取，token 由後端管理：

- **Proxy 端點**：`https://www.funtime.com.tw/api/proxy/`
- **圖片媒體主機**：`https://mgmt.funtime.com.tw`（cover.url 為相對路徑 `/uploads/...`，需補主機）
- **本機開發**：`http://localhost:8787`（`npx wrangler dev`）

主要 API：

| 端點 | 用途 |
|---|---|
| `GET /articles` | 文章列表（分頁、排序、多條件過濾） |
| `GET /articles/slug/:slug` | 單篇文章詳細（含 HTML content） |
| `GET /ft-regions` | 地區／城市清單 |
| `GET /uploads/*` | 圖片代理 |

### ArticleQuery 過濾參數

```swift
struct ArticleQuery: Equatable {
    var category: String?   // → filters[ft_category][display_name][$eq]
    var city: String?       // → filters[ft_theme][display_name][$eq]
    var tag: String?        // → filters[tags][name][$eq]
}
```

### 日期解析

Strapi 日期格式不一致（有時帶毫秒、有時不帶），需兩個 ISO8601DateFormatter 依序 fallback：
1. `.withInternetDateTime` + `.withFractionalSeconds`
2. 標準 `ISO8601DateFormatter()`

---

## 本地儲存（UserDefaults + Codable）

### FavoritesStore
```swift
@Observable
final class FavoritesStore {
    private(set) var articles: [Article]   // 最新收藏在前
    func isFavorite(_ article: Article) -> Bool
    func toggle(_ article: Article)        // 加入或移除
}
```
持久化：`UserDefaults` key `"favoriteArticles"`，`JSONEncoder/Decoder`。

### ReadingHistoryStore
```swift
@Observable
final class ReadingHistoryStore {
    private(set) var articles: [Article]   // 最近閱讀在前
    func append(_ article: Article)        // 進入 ArticleDetailView 時呼叫
    func clear()
}
```
持久化：`UserDefaults` key `"readingHistory"`，`JSONEncoder/Decoder`。

---

## DTO 設計原則

`APIArticleService` 內部定義 `private struct` DTO，只在該檔案內可見：

```
ListResponseDTO          → ArticlePage
ArticleSummaryDTO        → Article（列表，不含 contentHTML）
ArticleDetailDTO         → Article（單篇，含 contentHTML）
RegionDTO / ThemeDTO     → Region
```

API 欄位變動只需修改對應 DTO 的 `toXxx()` 方法，domain model 與 ViewModel 不受影響。

---

## Phase 規劃

### Phase 1（本次實作目標）
- [ ] 文章列表（最新／熱門，無限捲動）
- [ ] 文章詳細頁（WKWebView，視差，深色模式，書籤按鈕）
- [ ] 分類瀏覽（DisclosureGroup 樹狀）
- [ ] 依分類瀏覽文章
- [ ] 搜尋
- [ ] 收藏（UserDefaults，滑動刪除）
- [ ] 閱讀歷史（UserDefaults，顯示於搜尋頁）
- [ ] 作者頁

### Phase 2（會員系統）
- [ ] 登入／登出（Strapi JWT）
- [ ] Keychain 儲存 token
- [ ] 個人頁面

### Phase 3（遊戲化）
- [ ] 每日簽到、XP、等級系統
- [ ] 旅遊護照
- [ ] 推播通知（APNs）

---

## 開發環境

- **撰寫程式碼**：任一電腦（Xcode 或 VS Code + Swift extension）
- **Build／模擬器測試**：Mac + Xcode（必要）
- **模擬器目標**：iPhone 16 / iOS 18
- **不需要** Apple Developer 帳號（不上架 App Store）
