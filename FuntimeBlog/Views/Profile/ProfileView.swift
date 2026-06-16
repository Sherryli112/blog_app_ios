import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(FavoritesStore.self) private var favorites
    @Environment(ReadingHistoryStore.self) private var history
    @Environment(GameStore.self) private var gameStore

    @State private var showLogin = false

    var body: some View {
        if authStore.isLoggedIn {
            loggedInView
        } else {
            guestView
        }
    }

    private var guestView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Color.primary.opacity(0.4))
            Text("登入以使用完整功能")
                .font(.title3.bold())
            Text("簽到、收集旅遊印章、追蹤閱讀歷史")
                .font(AppTheme.Font.meta)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: AppTheme.Spacing.md) {
                Button("登入 / 註冊") { showLogin = true }
                    .primaryButtonStyle()
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Color.background)
        .navigationTitle("個人")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environment(authStore)
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
                GamificationDashboard()
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section {
                HStack {
                    statCell(count: favorites.articles.count, label: "收藏")
                    Divider()
                    statCell(count: history.articles.count, label: "閱讀")
                    Divider()
                    statCell(count: gameStore.profile.stamps.count, label: "印章")
                }
                .frame(height: 60)
                .listRowSeparator(.hidden)
            }

            Section("探索") {
                NavigationLink {
                    PassportView()
                } label: {
                    Label("旅遊護照", systemImage: "doc.text.fill")
                }
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
    .environment(GameStore())
}
