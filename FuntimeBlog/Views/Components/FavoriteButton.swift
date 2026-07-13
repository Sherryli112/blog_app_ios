import SwiftUI

struct FavoriteButton: View {
    let article: Article
    var circular: Bool = false
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let isMarked = favorites.isFavorite(article)
        Button {
            favorites.toggle(article)
        } label: {
            if circular {
                Image(systemName: isMarked ? "heart.fill" : "heart")
                    .foregroundStyle(isMarked ? .red : .secondary)
                    .glassCircle()
            } else {
                Image(systemName: isMarked ? "heart.fill" : "heart")
                    .foregroundStyle(isMarked ? .red : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isMarked ? "取消收藏" : "加入收藏")
    }
}

#Preview {
    FavoriteButton(article: SampleData.articles[0], circular: true)
        .padding()
        .environment(FavoritesStore())
}
