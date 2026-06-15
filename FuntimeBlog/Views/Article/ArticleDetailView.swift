import SwiftUI

struct AuthorNavigation: Hashable {
    let slug: String
    let name: String
}

struct ArticleDetailView: View {
    @State private var viewModel: ArticleDetailViewModel
    @Environment(\.openURL) private var openURL
    @Environment(ReadingHistoryStore.self) private var historyStore

    init(article: Article) {
        _viewModel = State(initialValue: ArticleDetailViewModel(article: article))
    }

    private var article: Article { viewModel.summary }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        Group {
            switch viewModel.contentState {
            case .loading:
                ProgressView()
            case .loaded(let html):
                ArticleReaderView(html: page(content: html),
                                  onOpenLink: { openURL($0) })
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
                BookmarkButton(article: article)
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: article.title)
            }
        }
        .navigationDestination(for: AuthorNavigation.self) { nav in
            AuthorView(authorSlug: nav.slug, authorName: nav.name)
        }
        .task {
            await viewModel.load()
            historyStore.record(article)
        }
    }

    private func page(content: String) -> String {
        ArticleHTML.page(
            title: article.title,
            author: article.author,
            dateText: Self.dateFormatter.string(from: article.date),
            tags: article.tags,
            coverURL: article.imageURL,
            contentHTML: content
        )
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: SampleData.articles[0])
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
