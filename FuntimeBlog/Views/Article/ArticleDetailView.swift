import SwiftUI

struct ArticleDetailView: View {
    @State private var viewModel: ArticleDetailViewModel
    @Environment(FavoritesStore.self) private var favorites
    @Environment(ReadingHistoryStore.self) private var history
    @Environment(GameStore.self) private var gameStore
    @Environment(\.openURL) private var openURL
    @State private var isFavorite = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    init(article: Article) {
        _viewModel = State(initialValue: ArticleDetailViewModel(article: article))
    }

    private var article: Article { viewModel.summary }

    var body: some View {
        Group {
            switch viewModel.contentState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let html):
                ArticleReaderView(
                    html: ArticleHTML.page(
                        title: article.title,
                        author: article.author,
                        dateText: Self.dateFormatter.string(from: article.date),
                        tags: article.tags,
                        coverURL: article.imageURL,
                        contentHTML: html
                    ),
                    onOpenLink: { openURL($0) }
                )
            case .failed(let message):
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.load() } }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Color.background)
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favorites.toggle(article)
                    isFavorite = favorites.isFavorite(article)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .white)
                }
                .glassCircle()
                .sensoryFeedback(.impact(weight: .medium), trigger: isFavorite)
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: article.title)
                    .glassCircle()
            }
        }
        .task {
            isFavorite = favorites.isFavorite(article)
            await viewModel.load()
            // 只在文章成功載入後才記錄閱讀與給予 XP，避免載入失敗時無限刷分
            if case .loaded = viewModel.contentState {
                history.append(article)
                gameStore.addXPForReading()
                if let city = article.city {
                    gameStore.collectStamp(city: city)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: SampleData.articles[0])
    }
    .environment(FavoritesStore())
    .environment(ReadingHistoryStore())
    .environment(GameStore())
}
