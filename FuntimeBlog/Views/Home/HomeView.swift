import SwiftUI

struct HomeView: View {
    let scrollToTopTrigger: Int
    @State private var viewModel = HomeViewModel()

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading where viewModel.articles.isEmpty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message) where viewModel.articles.isEmpty:
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.reload() } }
                }
            default:
                articleList
            }
        }
        .navigationTitle("FunTime")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Picker("排序", selection: $viewModel.sortMode) {
                    ForEach(HomeViewModel.SortMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.sortMode) { _, _ in
            Task { await viewModel.onSortModeChange() }
        }
    }

    private var articleList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    ForEach(viewModel.articles) { article in
                        NavigationLink(value: article) {
                            ArticleCard(article: article)
                        }
                        .buttonStyle(PressableCardStyle())
                        .id(article.id)
                        .onAppear {
                            if article.id == viewModel.articles.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                    if viewModel.isLoadingMore {
                        ProgressView().padding()
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await viewModel.reload() }
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                if let first = viewModel.articles.first {
                    withAnimation { proxy.scrollTo(first.id, anchor: .top) }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(scrollToTopTrigger: 0)
    }
    .environment(FavoritesStore())
    .environment(ReadingHistoryStore())
}
