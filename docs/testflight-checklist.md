# App Store / TestFlight 內部測試檢查清單

> 對應 Android 的 `notes/play-store-checklist.md`。這份清單是給 **`reading-only`** 分支用的（純閱覽版，無登入/遊戲化，對標 Android 的 `pre-gamification`）。
>
> ⚠️ **前提限制**：iOS 的建置、簽署、上傳都只能在 macOS 上執行（Xcode、`xcodebuild`、Transporter 都沒有 Windows/Linux 版本），跟 Android 的 Gradle 可跨平台建置不同。這份清單假設你已經有 macOS 環境可用（自己的 Mac、租用的雲端 Mac、或借用的 Mac），沒有 Mac 的話這些步驟都無法執行。
>
> 目前專案狀態（2026-07-17 更新）：
> - Bundle ID：`com.funtime.FuntimeBlog`
> - **✅ 已上傳並測通 build `1.0 (2)` TestFlight**（2026-07-17，手動簽署；(1) 有圖片載不出的 bug，(2) 已修，見「★ 實測紀錄 坑三」。內部＋外部通道皆實測圖片正常）
> - Team：`FUNTIME TECHNOLOGIES CO., LTD.`（Team ID `84BKQS2RVM`）
> - App ID `com.funtime.FuntimeBlog`：**已註冊**
> - Distribution 憑證 + App Store 描述檔「FuntimeBlog App Store」：**已建立**（存於操作用的 Mac）
> - `MARKETING_VERSION = 1.0`、`CURRENT_PROJECT_VERSION = 1`（下次重傳要把 build 號 +1）
> - App icon：**已放入**（1024×1024，不透明無 alpha）
> - Privacy Manifest：**已放入** `FuntimeBlog/PrivacyInfo.xcprivacy`（UserDefaults 用途 `CA92.1`；無追蹤、無資料蒐集、無第三方 SDK）
> - Apple Developer Program 會員資格：**已確認擁有**

## ★ 實測紀錄（2026-07-17 首次成功上傳，務必先讀）

這次實際跑一遍，踩到兩個大坑，`Automatic` 自動簽署在本團隊環境下**跑不通**，最後是靠**手動簽署**成功。若下次還是這台 Mac、同一個 App，憑證/描述檔都還在效期內，直接跳到「六、建置與上傳（手動簽署）」即可。

### 坑一：必須是 Admin 角色（Developer / App 管理都不行）
- 註冊 App ID、建立 Distribution 憑證，只有 **Admin（管理）/ 帳號持有人** 能做。**Developer（開發者）和 App Manager（App 管理）都不行**（App 管理很容易被誤選，中文「管理」才是 Admin）。
- 確認/調整角色：App Store Connect → 使用者與存取權限 → 點你的名字 → 角色。
- 本公司可協助升權限的人：**廖偉帆 `p988744@gmail.com`（管理）**、**`dev@bitpod.cc`（管理）**、**帳號持有人 ShenJengjie `funtime.mapp@gmail.com`**。
- 用完可以請對方把你改回 App 管理；日常重傳新版(憑證/描述檔還在)不需要 Admin，但憑證/描述檔到期(約一年)或要開新 App/新能力時要再借一次 Admin。

### 坑二：自動簽署會卡「Communication with Apple failed / no devices」
- 症狀：Signing & Capabilities 一直紅字 `Your team has no devices from which to generate a provisioning profile` + `No profiles for '...' were found`，`Try Again` 無效，換網路、重登、升 Admin 都沒用。
- 原因：自動簽署會想先建一張**開發用(Development)描述檔**，而開發描述檔一定要團隊至少註冊 1 台裝置；本團隊 0 台裝置 → 造不出來 → 整個卡住。**跟網路/協議無關。**
- 解法：**不要用自動簽署，改用手動簽署 + App Store 描述檔**（App Store 描述檔不需要任何裝置）。

### 坑三：圖片主機用了 `mgmt`（內網），外部網路 403 → 圖片載不出來
- 症狀：模擬器、公司網路（WiFi）下圖片正常；但測試者用**行動網路 / 自家 WiFi** 開 App，**圖片全部載不出來**（空白／漸層底），文字內容正常。
- 原因：`FunTimeAPI.mediaHost` 原本是 `https://mgmt.funtime.com.tw`（**管理用主機，只有公司內網連得到**）。API 回傳的 cover 是相對路徑，全被組成 mgmt 網址；外部網路經 Cloudflare 會回 **403 Forbidden**。
- 驗證方法：拿圖片網址（例如 `https://mgmt.funtime.com.tw/uploads/xxx.jpeg`）在手機 **Safari + 行動網路**開 → 403 就中了；換 `upd-api.funtime.com.tw` 同一路徑 → 正常。
- 解法：`mediaHost` 改成正式站對外實際使用的 **`https://upd-api.funtime.com.tw`**（commit `7e86380`）。實測行動網路 + 外部測試通道圖片正常。
- ⚠️ 教訓：**模擬器和公司網路都走內網直連，圖看起來正常，只有「外部網路的實機」才會現形。所以驗收一定要用實機 + 關掉公司 WiFi（走行動網路）+ 走 TestFlight 測。**

### 這次成功的完整路徑
1. （Admin）developer.apple.com → Identifiers → `+` → 註冊 App ID `com.funtime.FuntimeBlog`。
2. （Admin）Xcode → Settings → Accounts → 選團隊 → **Manage Certificates → `+` → Apple Distribution**（Xcode 自動產生發佈憑證，免手動 CSR）。
3. （Admin）developer.apple.com → Profiles → `+` → **App Store Connect** → 選該 App ID + 該 Distribution 憑證 → 命名 `FuntimeBlog App Store` → Download → 對檔案點兩下安裝。
4. **手動簽署 Archive**（見「六」），用命令列指定該憑證+描述檔，一次成功。
5. 把 `.xcarchive` 丟進 Xcode Organizer → Distribute App → App Store Connect → Upload。
6. 上傳成功後在 TestFlight：填**出口合規**(加密問題選第 4 個「未使用上方提及的任一種演算法」)、填**測試資訊**(外部測試必填，且**取消「需要登入」**因為本 App 無登入)、把 build 指派到內部/外部群組。內部測試免審即時可裝；外部測試要過 Beta App Review(約 1–2 天)。

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

## 二、App ID 註冊（✅ 已完成；需 Admin 角色才做得到）

> ⚠️ 這步需要 **Admin**（見「★ 實測紀錄 坑一」）。Developer/App 管理沒有「+」按鈕、建不了。
> 本專案的 `com.funtime.FuntimeBlog` 已於 2026-07-17 註冊完成，下次不用重做。

- [x] developer.apple.com → Certificates, IDs & Profiles → Identifiers → 新增 App ID ✅
- [ ]（若日後要新開 App 才需要）以下為當時步驟：
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

> ⚠️ **實測：本團隊環境下自動簽署跑不通**（no devices，見「★ 實測紀錄 坑二」），最後是用**手動簽署**成功。專案裡雖然是 `Automatic`，但實際 Archive 時用命令列覆寫成 Manual（見「六」）。
> Distribution 憑證與 App Store 描述檔 `FuntimeBlog App Store` 已於 2026-07-17 建立完成（存於操作用的 Mac）。下方自動簽署說明保留備查，但目前不適用。

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

## 六、建置與上傳（手動簽署，這次實際成功的做法）

> ⚠️ 自動簽署在本團隊環境會卡「no devices」（見「★ 實測紀錄 坑二」）。以下用手動簽署，前提是「二、App ID」「四、Distribution 憑證 + App Store 描述檔」都已備妥。

**用命令列 Archive（實測一次成功）：**
```bash
cd <專案目錄>
xcodebuild -project FuntimeBlog.xcodeproj -scheme FuntimeBlog \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/FuntimeBlog.xcarchive \
  archive \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=84BKQS2RVM \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  PROVISIONING_PROFILE_SPECIFIER="FuntimeBlog App Store"
```
- [ ] 出現 `** ARCHIVE SUCCEEDED **` 即成功。
- [ ] 把封存檔複製到 Organizer 看得到的位置：`cp -R /tmp/FuntimeBlog.xcarchive ~/Library/Developer/Xcode/Archives/<今天日期>/`
- [ ] Xcode → Window → **Organizer** → 選該 Archive → **Distribute App** → **App Store Connect** → **Upload**（簽署選手動、選 `FuntimeBlog App Store` 描述檔最保險）→ 完成。

**（替代）在 Xcode 圖形介面手動簽署：** Signing & Capabilities → **取消**「Automatically manage signing」→ Release 設定選 Team + 描述檔 `FuntimeBlog App Store` + 憑證 Apple Distribution → 裝置選 **Any iOS Device (arm64)** → Product → Archive。

> 註：`-allowProvisioningUpdates` 的自動簽署命令列版本一樣會卡 no devices，不要用；手動簽署因為不跟 Apple 即時要描述檔，才過得了。

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

最後更新：2026-07-17（對應 `reading-only` 分支。**build 1.0 (2) 已上傳並在內部＋外部通道實測圖片正常**。「★ 實測紀錄」記錄三個坑：(坑一)需 Admin 角色、(坑二)自動簽署卡 no devices 需改手動簽署、(坑三)圖片主機 mgmt 在外網 403 需改 upd-api。附可協助升權限的公司 Admin 名單、命令列手動簽署 Archive 指令。重點教訓:圖片這類問題只有「實機 + 行動網路 + TestFlight」才驗得出來,公司網路/模擬器會誤判正常。）
