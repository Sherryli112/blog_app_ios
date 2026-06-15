import SwiftUI

struct CityNavigation: Hashable {
    let city: String
}

struct CategoryView: View {
    @State private var viewModel = CategoryViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                regionList
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
        .background(AppTheme.Color.background)
        .navigationTitle("分類")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: CityNavigation.self) { nav in
            ArticleListView(
                title: nav.city,
                viewModel: ArticleListViewModel(city: nav.city)
            )
        }
        .task {
            if case .loading = viewModel.state { await viewModel.load() }
        }
    }

    private var regionList: some View {
        List {
            ForEach(viewModel.regions) { region in
                DisclosureGroup {
                    let columns = [GridItem(.adaptive(minimum: 92), spacing: AppTheme.Spacing.sm)]
                    LazyVGrid(columns: columns, spacing: AppTheme.Spacing.sm) {
                        ForEach(region.cities, id: \.self) { city in
                            NavigationLink(value: CityNavigation(city: city)) {
                                CityChip(name: city)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                } label: {
                    Text(region.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppTheme.Color.textPrimary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct CityChip: View {
    let name: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .font(.subheadline)
                .foregroundStyle(AppTheme.Color.primary)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(AppTheme.Color.primary.opacity(0.15), lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryView()
    }
    .environment(BookmarkStore())
}
