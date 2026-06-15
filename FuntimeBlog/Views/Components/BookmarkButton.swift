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
