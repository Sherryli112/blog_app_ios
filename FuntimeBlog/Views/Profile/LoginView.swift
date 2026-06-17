import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LoginViewModel()
    @State private var isRegistering = false
    @FocusState private var focusField: Field?

    enum Field { case identifier, username, email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(AppTheme.Color.primary)
                        Text("FunTime")
                            .font(.largeTitle.bold())
                        Text(isRegistering ? "建立你的帳號" : "歡迎回來")
                            .font(AppTheme.Font.meta)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, AppTheme.Spacing.xl)

                    // Form
                    VStack(spacing: AppTheme.Spacing.md) {
                        if isRegistering {
                            inputField("使用者名稱", text: $viewModel.username,
                                       contentType: .username, field: .username, next: .email)
                            inputField("Email", text: $viewModel.email,
                                       contentType: .emailAddress, field: .email, next: .password,
                                       keyboard: .emailAddress)
                        } else {
                            inputField("Email 或帳號", text: $viewModel.identifier,
                                       contentType: .emailAddress, field: .identifier, next: .password,
                                       keyboard: .emailAddress)
                        }

                        SecureField("密碼", text: $viewModel.password)
                            .textContentType(.password)
                            .focused($focusField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { submit() }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Color.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppTheme.Font.meta)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button { submit() } label: {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isRegistering ? "註冊" : "登入")
                            }
                        }
                        .primaryButtonStyle()
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    // Toggle login / register
                    Button {
                        isRegistering.toggle()
                        viewModel.errorMessage = nil
                        viewModel.identifier = ""
                        viewModel.password = ""
                        viewModel.username = ""
                        viewModel.email = ""
                        focusField = nil
                    } label: {
                        Text(isRegistering ? "已有帳號？登入" : "還沒有帳號？免費註冊")
                            .font(AppTheme.Font.meta)
                            .foregroundStyle(AppTheme.Color.primary)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.Color.background)
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func inputField(_ placeholder: String, text: Binding<String>,
                             contentType: UITextContentType, field: Field, next: Field,
                             keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focusField, equals: field)
            .submitLabel(.next)
            .onSubmit { focusField = next }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
    }

    private func submit() {
        Task {
            if isRegistering {
                await viewModel.register(authStore: authStore)
            } else {
                await viewModel.login(authStore: authStore)
            }
            if authStore.isLoggedIn { dismiss() }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthStore())
}
