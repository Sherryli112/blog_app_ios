# App Store / TestFlight 內部測試檢查清單

> 對應 Android 的 `notes/play-store-checklist.md`。這份清單是給 **`reading-only`** 分支用的（純閱覽版，無登入/遊戲化，對標 Android 的 `pre-gamification`）。
>
> ⚠️ **前提限制**：iOS 的建置、簽署、上傳都只能在 macOS 上執行（Xcode、`xcodebuild`、Transporter 都沒有 Windows/Linux 版本），跟 Android 的 Gradle 可跨平台建置不同。這份清單假設你已經有 macOS 環境可用（自己的 Mac、租用的雲端 Mac、或借用的 Mac），沒有 Mac 的話這些步驟都無法執行。
>
> 目前專案狀態（2026-07-14 更新）：
> - Bundle ID：`com.funtime.FuntimeBlog`
> - `CODE_SIGN_STYLE = Automatic`（已設定自動簽署，正常情況下不需要手動管理憑證）
> - `DEVELOPMENT_TEAM`：**尚未設定（空）**——需在 Xcode 手動選 Team，見「四、簽署設定」
> - `MARKETING_VERSION = 1.0`、`CURRENT_PROJECT_VERSION = 1`（版本字串／build 號，還未曾上傳過任何版本）
> - App icon：**已放入**（1024×1024，不透明無 alpha，符合 App Store 規範）
> - Privacy Manifest：**已放入** `FuntimeBlog/PrivacyInfo.xcprivacy`（宣告 UserDefaults 用途 `CA92.1`；無追蹤、無資料蒐集、無第三方 SDK）
> - Apple Developer Program 會員資格：**已確認擁有**

## 零、快速路徑：把 build 送進 TestFlight 內部測試

1. [ ] 在 Xcode 用公司的 Apple ID 登入（Xcode → Settings → Accounts）
2. [ ] 打開 `FuntimeBlog.xcodeproj`（`reading-only` 分支），Signing & Capabilities 分頁確認 Team 選到正確的公司帳號
3. [ ] App Store Connect 建立這個 App 的記錄（見下方「三」，若還沒建立過）
4. [ ] 裝置選單選 **Any iOS Device (arm64)**（模擬器無法 Archive）
5. [ ] Xcode → Product → Archive
6. [ ] Archive 完成後，Organizer 視窗 → Distribute App → App Store Connect → Upload
7. [ ] 回到 App Store Connect → 這個 App → TestFlight 分頁，等 build 從「處理中」變成可用（通常 10–30 分鐘，會收到 email）
8. [ ] 第一次上傳會被問「輸出合規（Export Compliance）」，這個 App 只用系統標準 HTTPS，選「否／符合豁免規定」即可
9. [ ] 確認測試人員的 Apple ID 已加進這個 App 的內部測試名單（見下方「七」）
10. [ ] TestFlight → 內部測試群組 → 把這個 build 加進去分派

## 一、Apple Developer Program 帳號

- [x] 已確認公司有會員資格 ✅ 2026-07-13

## 二、App ID 註冊（如果還沒註冊過）

- [ ] developer.apple.com → Certificates, IDs & Profiles → Identifiers → 新增 App ID
- [ ] 選 **App**（不是 App Clip／其他）
- [ ] Bundle ID 選 **Explicit**，填 `com.funtime.FuntimeBlog`
- [ ] Capabilities：目前這個乾淨版本沒有用到推播、iCloud 等額外能力，維持預設不勾選即可

## 三、App Store Connect 建立 App 記錄

- [ ] App Store Connect（appstoreconnect.apple.com）→ 我的 App → ➕ → 新增 App
- [ ] 平台：iOS
- [ ] 名稱：例如「FunTime部落格」——注意 App Store 的名稱是全球唯一，若被佔用需要調整（跟 Play Console 不同，Play 的 App 名稱不要求全域唯一）
- [ ] 主要語言：繁體中文
- [ ] Bundle ID：選前面註冊好的 `com.funtime.FuntimeBlog`
- [ ] SKU：自訂唯一識別碼（例如 `funtimeblog-ios`），純內部使用，使用者看不到
- [ ] 使用者存取權限：完整存取即可

## 四、簽署設定

- [ ] 專案已經是 `CODE_SIGN_STYLE = Automatic`，不需要手動建立憑證/描述檔
- [ ] **先登入 Apple ID（最常被漏）**：Xcode 選單 → Settings…（`⌘ ,`）→ **Accounts** 分頁 → 左下角 **`+`** → **Apple ID** → 用公司 Apple ID 登入。**沒登入的話後面的 Team 下拉會是空的，看起來像「沒有那個按鈕」。**
- [ ] 找到 Team 下拉的路徑：
  1. 左側 Project Navigator（`⌘1`）最上面點**藍色專案圖示「FuntimeBlog」**
  2. 中間清單分 **PROJECT** 與 **TARGETS**，點 **TARGETS 下的「FuntimeBlog」**（別點到 PROJECT，兩者同名易混）
  3. 上方分頁點 **Signing & Capabilities**（在 General 右邊）
  4. 確認 **Automatically manage signing 已打勾**，其正下方即 **Team** 下拉 → 選公司帳號
  - 若分頁列看不到，多半是視窗太窄被收進「»」選單，把視窗拉寬即可
- [ ] 若跳出「Failed to register bundle identifier」或類似錯誤，通常是 Apple ID 還沒登入 Xcode，或帳號沒有該 Team 的權限，回上面第一步確認登入狀態

## 五、版本號

- [ ] 目前 `MARKETING_VERSION = 1.0`、`CURRENT_PROJECT_VERSION = 1`，這是第一次上傳，可以直接沿用不用改
- [ ] ⚠️ 跟 Android 的 versionCode 邏輯一樣：**同一個 build number 不能重複上傳**，如果上傳後想改東西重傳，`CURRENT_PROJECT_VERSION` 要往上遞增（例如 1 → 2），`MARKETING_VERSION` 不用每次都改，等真的要對外發版時再決定語意化版本號

## 六、建置與上傳

- [ ] Xcode 上方裝置選單，選 **Any iOS Device (arm64)**（如果選到模擬器，Product → Archive 會反白點不了）
- [ ] Product → Archive，等建置完成（會需要幾分鐘）
- [ ] 建置完成後自動跳出 Organizer 視窗，選剛剛的 Archive → **Distribute App**
- [ ] 選 **App Store Connect** → **Upload**
- [ ] 簽署選項選 **Automatically manage signing**
- [ ] 一路下一步到完成，上傳時間視網路速度，通常幾分鐘到十幾分鐘

## 七、TestFlight 內部測試設定

- [ ] App Store Connect → 這個 App → **TestFlight** 分頁
- [ ] 等剛上傳的 build 狀態從「處理中」變成可用（通常 10–30 分鐘，會收到 Apple 的 email 通知）
- [ ] 第一次會被要求填**輸出合規資訊（Export Compliance）**：問這個 App 是否使用加密。這個 App 只用標準 HTTPS（系統內建），選「否，這個 App 符合美國出口法規的豁免規定」（或類似選項）即可，不需要額外文件
- [ ] 確認測試人員都已經是這個 App 在 App Store Connect 的**團隊成員**：App Store Connect → 使用者與存取權限 → 加入他們的 Apple ID（角色不拘，只要在團隊裡就能收到內部測試邀請，**內部測試最多 100 人**，且不需要 Apple 的 Beta App Review）
- [ ] TestFlight 分頁 → 內部測試群組 → 把剛上傳的 build 加進去、勾選要分派的測試人員
- [ ] 測試人員手機需要先在 App Store 安裝「TestFlight」這個官方 App，登入自己的 Apple ID 後就會看到邀請通知，點下去即可安裝

## 八、（之後才做）外部測試 / 正式上架

- [ ] 外部測試（Public Link 或 email 邀請，最多 10,000 人）需要先通過 Apple 的 **Beta App Review**（通常 24–48 小時），且需要補填「測試資訊」（App 說明、這次要測什麼、聯絡方式）
- [ ] 正式上架需要完整的商店資料：
  - [x] App 圖示（1024×1024，無圓角無透明）✅ 已放入
  - [x] Privacy Manifest（`PrivacyInfo.xcprivacy`）✅ 已放入
  - [ ] 至少一組裝置尺寸的截圖
  - [ ] App 說明
  - [ ] 隱私權政策 URL
  - [ ] App Privacy（資料蒐集）問卷 → 這個 App 不蒐集任何資料，照實填「未蒐集資料（Data Not Collected）」即可（注意：此問卷在 App Store Connect 網站上填，跟專案裡的 `PrivacyInfo.xcprivacy` 是兩件事）
  - [ ] 內容分級問卷
- [ ] 內部測試跑通、確認核心功能正常後，再回來補齊這些項目

---

最後更新：2026-07-14（對應 `reading-only` 分支。已有 macOS 環境，可直接執行建置與上傳。本次補充：app icon 與 Privacy Manifest 已放入、修正 icon alpha、補上 Team 選取的詳細路徑。尚待手動操作：在 Xcode 登入 Apple ID 並選 Team，然後 Archive 上傳。）
