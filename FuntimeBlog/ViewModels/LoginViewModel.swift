import Foundation
import Observation

@Observable
final class LoginViewModel {
    var identifier: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let authService = APIAuthService()

    func login(authStore: AuthStore) async {
        let id = identifier.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty, !password.isEmpty else {
            errorMessage = "請輸入帳號與密碼"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let (token, user) = try await authService.login(identifier: id, password: password)
            authStore.save(token: token, user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
