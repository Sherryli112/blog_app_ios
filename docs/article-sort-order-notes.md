# 文章排序與官網的已知差異

## 背景

2026-07-13 在 Mac 上實機測試 `reading-only` 分支，發現 App 首頁「最新」「熱門」排序跟官網不一樣，追查後發現這比想像中複雜，記錄下來避免以後重複踩坑。

## 結論：官網 `/blog` 的真正排序資料 App 拿不到

`www.funtime.com.tw/blog` 這個網址在正式環境**永遠強制導向舊系統 WordPress**（見 `funtime_website/frontend/docs/old_system/overview.md` 的「強制走舊系統」清單），不論有沒有帶 `?sort=` 參數。`frontend/src/app/blog/page.tsx`（Next.js 新系統的對應頁面）在正式環境的這個網址底下**實際上完全打不到**，是還沒真正切換上線的程式碼。

真正的排序邏輯在舊系統 `blog/wp-content/themes/funtimemobile/functions.php` 的 `get_blog_index_list()`：

```php
SELECT `{$sort_col}`,`post_id`,`slug`,...
FROM `blog_index_list` l
INNER JOIN `blog_content_mapping` m
  ON l.`{$sort_col}` = m.post_id OR l.`{$sort_col}` = m.`new_id`
WHERE 1
ORDER BY `l`.`id`
```

`$sort_col` 是 `sort_new` 或 `sort_hot`——這是舊系統 MySQL `blog` 資料庫裡**一張人工維護的排序表**，每一列依 `blog_index_list.id` 排序、指定該順位要顯示哪篇文章。`index.php` 裡雖然也宣告了 `$sort_strapi = "hot_rank:asc"` / `"publishedAt:desc"`，但這兩個變數**完全沒被實際使用**（是死程式碼，可能是早期規劃過、後來沒接上的殘留）。

也就是說：**App 不管用 Strapi 的 `hot_rank`、`custom_published_at`、`weekly_views`、`search_rank` 哪個欄位排序，都不可能跟官網逐字一致**，因為官網真正的順序是這張只存在舊系統 MySQL、沒有對外 API 的人工表決定的。

## 目前採用的做法（2026-07-13 使用者確認接受）

`HomeViewModel.fetchPage()` 用 Strapi 既有欄位近似：

- 「最新」→ `custom_published_at:desc`（Strapi article schema 裡編輯可手動覆寫的「顯示用發佈時間」，比 Strapi 內建的 `publishedAt` 更貼近實際「這篇該被當作最新」的編輯意圖，但仍不等於官網的人工排序表）
- 「熱門」→ `hot_rank:asc`（人工標記的熱門分數，數字越小越熱門；但實測發現大部分文章這個欄位是空值，排序結果看起來會不夠直覺）

已知限制：App 顯示順序**不會**跟官網逐字一致，尤其「熱門」分頁差異可能較明顯。這是經過使用者確認可以接受的近似值，不是 bug。

## 如果之後想要做到完全一致

需要以下其中一種後端工作（目前都還沒做）：
1. 在舊系統 `api/` 資料夾新增一支端點，把 `blog_index_list`/`blog_content_mapping` 的排序結果轉成 JSON 給 App 打
2. 或把 `blog_index_list` 這張表的資料同步/遷移進 Strapi，變成一個可以正常用 `sort` 參數查詢的欄位

兩種都需要額外的後端開發與部署，目前不在範圍內。
