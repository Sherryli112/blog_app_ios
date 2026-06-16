import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(FavoritesStore.self) private var favorites
    @Environment(ReadingHistoryStore.self) private var history

    var body: some View {
        if authStore.isLoggedIn {
            loggedInView
        } else {
            LoginView()
                .navigationTitle("個人")
                .navigationBarTitleDisplayMode(.large)
        }
    }

    private var loggedInView: some View {
        List {
            Section {
                HStack(spacing: AppTheme.Spacing.lg) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppTheme.Color.primary)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(authStore.user?.username ?? "")
                            .font(.title2.bold())
                        Text(authStore.user?.email ?? "")
                            .font(AppTheme.Font.meta)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .listRowSeparator(.hidden)
            }

            Section {
                HStack {
                    statCell(count: favorites.articles.count, label: "收藏")
                    Divider()
                    statCell(count: history.articles.count, label: "閱讀")
                }
                .frame(height: 60)
                .listRowSeparator(.hidden)
            }

            Section("帳號") {
                Button(role: .destructive) {
                    authStore.logout()
                } label: {
                    Label("登出", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("個人")
        .navigationBarTitleDisplayMode(.large)
    }

    private func statCell(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.Color.primary)
            Text(label)
                .font(AppTheme.Font.meta)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthStore())
    .environment(FavoritesStore())
    .environment(ReadingHistoryStore())
}
