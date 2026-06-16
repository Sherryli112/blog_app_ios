import Foundation
import Observation

@Observable
final class LoginViewModel {
    var identifier: String = ""
    var password: String = ""
    var username: String = ""
    var email: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let authService = LocalAuthService()

    func login(authStore: AuthStore) async {
        let id = identifier.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty, !password.isEmpty else {
            errorMessage = "請輸入帳號與密碼"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let user = try authService.login(identifier: id, password: password)
            authStore.save(user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func register(authStore: AuthStore) async {
        let name = username.trimmingCharacters(in: .whitespaces)
        let mail = email.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !mail.isEmpty, !password.isEmpty else {
            errorMessage = "請填寫所有欄位"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let user = try authService.register(username: name, email: mail, password: password)
            authStore.save(user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
