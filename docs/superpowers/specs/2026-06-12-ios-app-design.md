# FunTime Blog iOS App — 設計規格

> 建立日期：2026-06-12

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
| 本地儲存 | SwiftData |
| 網路層 | URLSession + async/await |
| 文章內容渲染 | WKWebView |
| 後端 | Cloudflare Worker → Strapi（沿用現有，不動） |

---

## 架構模式：MVVM + Repository

```
SwiftUI View
    ↓
@Observable ViewModel（狀態管理）
    ↓
Repository（抽象資料來源）
    ↓
BlogService（URLSession）  ←→  SwiftData（本地）
    ↓
Cloudflare Worker → Strapi
```

每層職責：
- **View**：純 UI，只讀 ViewModel 狀態，不含商業邏輯
- **ViewModel**：管理畫面狀態，協調 Repository 呼叫
- **Repository**：決定資料來自 API 還是本地，對 ViewModel 隱藏細節
- **BlogService**：負責所有 HTTP 呼叫，解析 JSON 為 Swift struct
- **SwiftData**：書籤與閱讀歷史的本地持久化

---

## 專案結構

```
FuntimeBlog/
├── App/
│   └── FuntimeBlogApp.swift
│
├── Networking/
│   ├── APIClient.swift             # URLSession、base URL 設定
│   ├── BlogService.swift           # API 呼叫
│   └── Models/                     # API response struct
│       ├── Article.swift
│       ├── Category.swift
│       └── Author.swift
│
├── Storage/                        # SwiftData
│   ├── BookmarkEntry.swift         # @Model
│   └── ReadingHistoryEntry.swift   # @Model
│
├── Repositories/
│   ├── ArticleRepository.swift
│   ├── CategoryRepository.swift
│   ├── BookmarkRepository.swift
│   └── ReadingHistoryRepository.swift
│
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── ArticleDetailViewModel.swift
│   ├── CategoryViewModel.swift
│   ├── SearchViewModel.swift
│   └── BookmarkViewModel.swift
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ArticleCard.swift
│   ├── Article/
│   │   ├── ArticleDetailView.swift
│   │   └── ArticleWebView.swift    # WKWebView wrapper
│   ├── Category/
│   │   ├── CategoryView.swift
│   │   └── CategoryArticleListView.swift
│   ├── Search/
│   │   └── SearchView.swift
│   ├── Bookmark/
│   │   └── BookmarkView.swift
│   └── Components/
│       └── ArticleRow.swift        # 可重用文章列表 cell
│
└── worker/                         # Cloudflare Worker（與 Android repo 共用邏輯）
```

---

## 導覽結構

`TabView` 搭配各 Tab 獨立的 `NavigationStack`，切換 Tab 不影響彼此的導覽狀態。

```
TabView
├── 首頁 Tab（SF Symbol: house）
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
└── 書籤 Tab（SF Symbol: bookmark）
    └── NavigationStack
        ├── BookmarkView
        └── ArticleDetailView
```

---

## 畫面規格

### HomeView
- 大標題導覽列（`.navigationBarTitleDisplayMode(.large)`）
- Segmented Control 切換「最新」／「熱門」
- 無限捲動（距底部時自動載入下一頁）
- `.searchable()` 整合，輸入時直接顯示搜尋結果
- 文章卡片顯示：封面圖、標題、作者、日期

### ArticleDetailView
- 全螢幕 WKWebView 渲染文章 HTML 內容
- 注入自訂 CSS（字體、行距、RWD 優化）
- 導覽列右側書籤按鈕（`bookmark` / `bookmark.fill` 切換）
- 進入頁面時自動寫入閱讀歷史
- 右滑返回（系統內建）

### CategoryView
- `DisclosureGroup` 展開式清單：地區 → 主題 → 分類
- 點選分類進入 CategoryArticleListView

### SearchView
- 搜尋欄為主體
- 無輸入時顯示閱讀歷史
- 有輸入時顯示搜尋結果，支援無限捲動

### BookmarkView
- 已儲存文章列表
- `.swipeActions` 滑動刪除（iOS 原生手勢）
- 空狀態提示文字

### AuthorView
- 作者頭像、名稱、簡介
- 該作者的文章列表

---

## 後端 API

沿用現有 Cloudflare Worker，無需修改。

- **生產端點**：`https://funtime-blog-worker.funtime.workers.dev`
- **本機開發**：`http://localhost:8787`（`npx wrangler dev`）

主要 API：

| 端點 | 用途 |
|---|---|
| `GET /articles` | 文章列表（支援分頁、排序） |
| `GET /articles/slug/:slug` | 單篇文章詳細 |
| `GET /ft-regions` | 分類樹（地區／主題） |
| `GET /uploads/*` | 圖片代理 |

---

## 本地儲存（SwiftData）

### BookmarkEntry
```swift
@Model
class BookmarkEntry {
    var slug: String
    var title: String
    var coverUrl: String?
    var savedAt: Date
}
```

### ReadingHistoryEntry
```swift
@Model
class ReadingHistoryEntry {
    var slug: String
    var title: String
    var coverUrl: String?
    var readAt: Date
}
```

---

## Phase 規劃

### Phase 1（本次實作目標）
- [ ] 文章列表（最新／熱門，無限捲動）
- [ ] 文章詳細頁（WKWebView，書籤按鈕）
- [ ] 分類瀏覽（DisclosureGroup 樹狀）
- [ ] 依分類瀏覽文章
- [ ] 搜尋
- [ ] 書籤（SwiftData，滑動刪除）
- [ ] 閱讀歷史（SwiftData，顯示於搜尋頁）
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
