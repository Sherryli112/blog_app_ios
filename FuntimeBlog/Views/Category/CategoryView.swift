import SwiftUI

struct CategoryView: View {
    @State private var viewModel = CategoryViewModel()

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("載入失敗", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重試") { Task { await viewModel.reload() } }
                }
            case .loaded:
                regionList
            }
        }
        .navigationTitle("分類")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
    }

    private var regionList: some View {
        List {
            ForEach(viewModel.regions) { region in
                DisclosureGroup(region.name) {
                    ForEach(region.cities, id: \.self) { city in
                        NavigationLink(value: ArticleQuery(city: city)) {
                            Label(city, systemImage: "mappin.circle")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: ArticleQuery.self) { query in
            CategoryArticleListView(query: query)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryView()
    }
}
