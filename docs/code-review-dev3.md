# Code Review — dev3 分支

> 審查日期：2026-06-17
> 審查範圍：`master...origin/dev3`（Phase 1 + Phase 2 + Phase 3 實作）

---

## 總覽

| # | 嚴重程度 | 類型 | 檔案 | 問題摘要 |
|---|---------|------|------|---------|
| 1 | 🔴 高 | 功能錯誤 | `ArticleDetailView.swift` | 旅遊護照印章永遠無法透過讀文章收集 |
| 2 | 🔴 高 | 邏輯錯誤 | `GameStore.swift` | 連續簽到中斷後拿到過高 XP（最多 7 倍） |
| 3 | 🔴 高 | 資料損毀 | `LocalAuthService.swift` | 第二個使用者註冊後，第一個使用者帳號永久消失 |
| 4 | 🔴 高 | 邏輯錯誤 | `ArticleDetailView.swift` | 文章未讀成功仍可無限刷 XP |
| 5 | 🟠 中 | UX 缺陷 | `SearchViewModel.swift` | 搜尋失敗時畫面空白，使用者無法辨別原因 |
| 6 | 🟠 中 | 資安 | `LocalAuthService.swift` | 密碼以明文 JSON 儲存在 Keychain |
| 7 | 🟡 低 | 待確認 | `HomeViewModel.swift` | `hot_rank:asc` 排序方向待確認 |
| 8 | 🟡 低 | 規格違反 | 所有 Storage 檔案 | 所有本地儲存用 UserDefaults，違反規格要求的 SwiftData |

---

## 詳細說明

### 1. 🔴 旅遊護照印章永遠無法透過讀文章收集

**檔案**：`FuntimeBlog/Views/Article/ArticleDetailView.swift` 約第 70 行

**問題**：`tags` 陣列的組成順序是 `[theme, city]`（見 `APIArticleService.ArticleSummaryDTO.toArticle()`），`article.tags.first` 拿到的是主題名（如「美食」「文化」），傳給 `gameStore.collectStamp(city:)`。`PassportView.allCities` 中只有城市名稱，主題名永遠不會命中，印章功能對所有 theme 非 nil 的文章完全失效。

```swift
// 問題程式碼
if let city = article.tags.first {      // tags[0] 是 theme，不是城市
    gameStore.collectStamp(city: city)
}

// APIArticleService.swift — tags 組成順序
tags: [theme?.displayName, city?.displayName].compactMap { $0 }
//     ↑ index 0                ↑ index 1
```

**修正**：改用 `article.tags.last`，或在 `Article` model 加獨立的 `city: String?` 屬性。

---

### 2. 🔴 連續簽到中斷後拿到過高 XP（最多 7 倍）

**檔案**：`FuntimeBlog/Storage/GameStore.swift` 約第 17 行

**問題**：`bonusXP` 在 `streakDays` 重置之前計算。連續 6 天後中斷一天再簽到，`isConsecutive = false`，但 `bonusXP = min(6+1, 7) × 10 = 70 XP`，之後才執行 `streakDays = 1`。正確應得 `min(1, 7) × 10 = 10 XP`。

```swift
// 問題程式碼
let bonusXP = min(profile.streakDays + 1, 7) * 10   // ← 用舊值計算

profile.lastCheckIn = Date()
profile.streakDays = isConsecutive ? profile.streakDays + 1 : 1  // ← 才重置

addXP(bonusXP)  // 已用錯值

// 修正：先更新 streakDays，再計算 bonusXP
profile.streakDays = isConsecutive ? profile.streakDays + 1 : 1
let bonusXP = min(profile.streakDays, 7) * 10
```

---

### 3. 🔴 第二個使用者註冊後，第一個使用者帳號永久消失

**檔案**：`FuntimeBlog/Networking/LocalAuthService.swift` 約第 14 行

**問題**：固定使用單一 Keychain key `"local_auth_user"`，`register()` 只檢查 email/username 是否與現有帳號相同，若不同則通過並覆寫。使用者 A（a@x.com）已存在時，使用者 B（b@x.com）可成功覆蓋，使用者 A 之後以正確密碼仍無法登入。

```swift
// 問題程式碼
KeychainHelper.save(json, for: Self.userKey)  // 固定 key，無條件覆寫
```

**修正**：以 email 作為 Keychain key，或明確標示為「單裝置單帳號」並在 UI 層說明限制。

---

### 4. 🔴 文章未讀成功仍可無限刷 XP

**檔案**：`FuntimeBlog/Views/Article/ArticleDetailView.swift` 約第 62 行

**問題**：`.task` 先同步執行 `history.append()` 和 `addXPForReading()`，之後才 `await viewModel.load()`。網路失敗時文章從未顯示，但 XP 已加、閱讀記錄已寫入。每次重新進入頁面都再得 +5 XP，可無限刷。

```swift
// 問題程式碼
.task {
    history.append(article)        // ← 先寫入
    gameStore.addXPForReading()    // ← 先加 XP
    await viewModel.load()         // ← 失敗也沒差，XP 已加
}

// 修正：成功載入後才給 XP
.task {
    await viewModel.load()
    if case .loaded = viewModel.contentState {
        history.append(article)
        gameStore.addXPForReading()
    }
}
```

---

### 5. 🟠 搜尋失敗時畫面空白，使用者無法辨別原因

**檔案**：`FuntimeBlog/ViewModels/SearchViewModel.swift` 約第 64 行

**問題**：`fetchPage()` 的 `catch` 只有一行註解，`SearchViewModel` 沒有任何錯誤狀態屬性。API 斷線時，`isSearching = false`、`results = []`、`noResults = false`，UI 顯示空畫面，使用者不知道是「真的沒有結果」還是「網路出錯」，也無重試入口。

```swift
// 問題程式碼
} catch {
    // silently ignore search errors   ← 吞掉所有錯誤
}

// 修正：加入錯誤狀態
var searchError: String?

} catch {
    searchError = error.localizedDescription
}
```

---

### 6. 🟠 密碼以明文 JSON 儲存在 Keychain

**檔案**：`FuntimeBlog/Networking/LocalAuthService.swift` 約第 10 行

**問題**：`LocalUser` struct 含 `password: String`，整體被 `JSONEncoder` 序列化後存入 Keychain。Keychain 雖有加密保護，但越獄裝置或備份解密後密碼直接以明文暴露。`login()` 也用 `==` 直接比對原始字串。

```swift
// 問題程式碼
private struct LocalUser: Codable {
    let username: String
    let email: String
    let password: String   // ← 明文密碼被序列化存入 Keychain
}

// 修正：存 hash，比對 hash
import CryptoKit
let hashed = SHA256.hash(data: Data(password.utf8))
    .compactMap { String(format: "%02x", $0) }.joined()
```

---

### 7. 🟡 `hot_rank:asc` 排序方向待確認

**檔案**：`FuntimeBlog/ViewModels/HomeViewModel.swift` 約第 58 行

**問題**：若後端 `hot_rank` 是「熱門分數」（數字越高越熱門），`asc` 會讓最冷門文章排最前，熱門 tab 功能完全相反。若是「名次排名」（1 = 第一名），asc 才正確。需對照 Cloudflare Worker 實作確認。

```swift
let sort = sortMode == .hot ? "hot_rank:asc" : "publishedAt:desc"
//                                       ↑ 若 hot_rank 是分數應改為 :desc
```

**行動**：確認 Worker 端 `hot_rank` 欄位語意；若是分數改為 `"hot_rank:desc"`。

---

### 8. 🟡 所有本地儲存用 UserDefaults，違反規格要求的 SwiftData

**檔案**：`FuntimeBlog/Storage/FavoritesStore.swift`、`ReadingHistoryStore.swift`、`GameStore.swift`、`AuthStore.swift`

**問題**：設計規格明確規定「本地儲存：SwiftData（`@Model`）」，四個 Store 全部改用 `UserDefaults + JSONEncoder` 手動序列化。UserDefaults 無自動遷移機制（新增欄位時舊資料無法處理）、無查詢能力，且系統低儲存空間時可能被清除。

**修正**：以 `@Model` class + `ModelContainer` 替換，書籤（`FavoritesStore`）和閱讀歷史（`ReadingHistoryStore`）優先，因為這兩個是規格 Phase 1 明確要求的項目。

---

## 次要建議（不影響正確性）

| 項目 | 說明 |
|------|------|
| `APIAuthService` 是死碼 | `LoginViewModel` 硬編碼使用 `LocalAuthService`，`APIAuthService` 完整實作卻從未被呼叫，未來切換真實 JWT 時容易遺漏 |
| `collectStamp()` 雙重 persist | `addXP()` 內已呼叫 `persist()`，`collectStamp()` 再呼叫一次，造成 UserDefaults 重複寫入 |
| `FavoritesStore` 雙重資料結構 | `articles: [Article]` 和 `ids: Set<String>` 必須手動同步，可改為只維護一個 |
| Pagination 邏輯重複 | `HomeViewModel` 和 `SearchViewModel` 各自實作相同的分頁狀態與 `loadMore` 邏輯，可抽成共用 |
| `CheckInView.checkInDone` 冗餘 | `canCheckInToday` 已是真正的 guard，`checkInDone` 只在同一個 View 生命周期內有效，View 重建後狀態重置 |
| Tab 圖示與規格不符 | 首頁用 `flame.fill`（規格要求 `house`），收藏用 `heart.fill`（規格要求 `bookmark`） |
