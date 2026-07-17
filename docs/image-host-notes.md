# 圖片主機：務必用 upd-api，不要用 mgmt

## 背景

2026-07-17 把 `reading-only` 分支上到 TestFlight 後，測試者回報**文章圖片完全載不出來**（列表卡片、內頁大圖都空白，文字內容正常）。但在**模擬器**和**公司網路**下圖片都正常，只有**外部測試者用行動網路/家用網路**才會壞——這種「內部看起來好、外部才現形」的特性讓它一開始很難查。

## 結論：`mgmt` 是內網管理主機，外網會被 Cloudflare 擋 403

App 用 `FunTimeAPI.mediaHost` 組圖片網址。原本設成：

```
mgmt.funtime.com.tw   ← 管理用主機
```

API 回傳的 `cover.url` 是相對路徑（例如 `/uploads/xxx.jpeg`），全部被組成 `https://mgmt.funtime.com.tw/uploads/...`。

實測 DNS/連線行為：

| 環境 | mgmt 解析到 | 圖片 |
|---|---|---|
| 公司內網 / 模擬器 | 內部直連 origin（`61.220.198.130`） | ✅ 正常 |
| 外部網路（行動網路等） | Cloudflare | ❌ **403 Forbidden** |

`mgmt`（management）不是給外部公開取圖的主機，Cloudflare 對它有防護，外部 IP 一律 403。正式站 `www.funtime.com.tw` 對外送圖用的是 **`upd-api.funtime.com.tw`**（實測行動網路正常取圖），這才是公開圖片主機。

## 修法

`FuntimeBlog/Networking/FunTimeAPI.swift`：

```swift
// 錯：只有公司內網連得到，外網 403
// static let mediaHost = "https://mgmt.funtime.com.tw"

// 對：正式站對外實際使用的公開主機
static let mediaHost = "https://upd-api.funtime.com.tw"
```

（commit `7e86380`。兩個主機後面的 `/uploads/...` 路徑完全相同，只是主機不同。）

## 驗證方法（判斷是不是又踩到這個雷）

拿任一張圖片路徑，在**手機 Safari + 行動網路（關掉公司 WiFi）** 開：

- `https://mgmt.funtime.com.tw/uploads/<任一檔名>.jpeg` → **403** = 中雷
- `https://upd-api.funtime.com.tw/uploads/<同一檔名>.jpeg` → 正常顯示 = 應該用這個

## 教訓

**圖片/外部資源這類問題，一定要用「實機 + 行動網路（關掉公司 WiFi）+ TestFlight」驗收。** 模擬器和公司網路都走內網直連，圖看起來正常，會誤判成沒問題；只有離開公司網路的真實環境才會現形。

## 相關

- 排序的類似「內部與官網不一致」問題見 [`article-sort-order-notes.md`](article-sort-order-notes.md)。
- 上架/測試流程與其他踩坑見 [`testflight-checklist.md`](testflight-checklist.md) 的「★ 實測紀錄 坑三」。
