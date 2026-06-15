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
            slug: "chatuchak-market-guide",
            excerpt: "號稱全球最大週末市集，15,000 個攤位讓人逛到腿軟，但掌握幾個技巧就能買到精品卻不超支。"
        )
    ]
}
