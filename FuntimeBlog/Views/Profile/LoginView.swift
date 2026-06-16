import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var viewModel = LoginViewModel()
    @FocusState private var focusField: Field?

    enum Field { case identifier, password }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(AppTheme.Color.primary)
                    Text("FunTime")
                        .font(.largeTitle.bold())
                    Text("登入以解鎖更多功能")
                        .font(AppTheme.Font.meta)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, AppTheme.Spacing.xxl)

                VStack(spacing: AppTheme.Spacing.md) {
                    TextField("Email 或帳號", text: $viewModel.identifier)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusField, equals: .identifier)
                        .submitLabel(.next)
                        .onSubmit { focusField = .password }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.Color.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))

                    SecureField("密碼", text: $viewModel.password)
                        .textContentType(.password)
                        .focused($focusField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await viewModel.login(authStore: authStore) } }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.Color.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppTheme.Font.meta)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await viewModel.login(authStore: authStore) }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("登入")
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer()
            }
        }
        .background(AppTheme.Color.background)
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    LoginView()
        .environment(AuthStore())
}
