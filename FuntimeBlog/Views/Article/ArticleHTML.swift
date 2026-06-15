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
