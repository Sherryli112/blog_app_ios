import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(ReadingHistoryStore.self) private var history

    var body: some View {
        List {
            if viewModel.keyword.trimmingCharacters(in: .whitespaces).isEmpty {
                historySection
            } else if viewModel.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if let error = viewModel.searchError {
                ContentUnavailableView {
                    Label("搜尋失敗", systemImage: "wifi.slash")
                } description: {
                    Text(error)
                } actions: {
                    Button("重試") { Task { await viewModel.performSearch() } }
                }
                .listRowSeparator(.hidden)
            } else if viewModel.noResults {
                ContentUnavailableView.search(text: viewModel.keyword)
                    .listRowSeparator(.hidden)
            } else {
                resultsSection
            }
        }
        .listStyle(.plain)
        .navigationTitle("搜尋")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.keyword, prompt: "搜尋文章")
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.keyword) { _, _ in viewModel.onKeywordChange() }
        .onDisappear { viewModel.cancelPendingSearch() }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }

    @ViewBuilder
    private var historySection: some View {
        if !history.articles.isEmpty {
            Section {
                ForEach(history.articles.prefix(20)) { article in
                    NavigationLink(value: article) {
                        ArticleRow(article: article)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                HStack {
                    Text("最近閱讀")
                        .font(AppTheme.Font.sectionHeader)
                    Spacer()
                    Button("清除") { history.clear() }
                        .font(AppTheme.Font.meta)
                        .foregroundStyle(AppTheme.Color.primary)
                }
            }
        }
    }

    private var resultsSection: some View {
        Section {
            ForEach(viewModel.results) { article in
                NavigationLink(value: article) {
                    ArticleRow(article: article)
                }
                .buttonStyle(.plain)
                .onAppear {
                    if article.id == viewModel.results.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environment(FavoritesStore())
    .environment(ReadingHistoryStore())
}
