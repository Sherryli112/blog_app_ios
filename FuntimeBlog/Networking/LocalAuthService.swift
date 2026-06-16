import Foundation

struct LocalAuthService {
    private static let userKey = "local_auth_user"

    private struct LocalUser: Codable {
        let username: String
        let email: String
        let password: String
    }

    func register(username: String, email: String, password: String) throws -> User {
        if let existing = loadUser() {
            if existing.email.lowercased() == email.lowercased() {
                throw AuthError.invalidCredentials("此 Email 已被註冊")
            }
            if existing.username.lowercased() == username.lowercased() {
                throw AuthError.invalidCredentials("此使用者名稱已被使用")
            }
        }
        let local = LocalUser(username: username, email: email, password: password)
        guard let data = try? JSONEncoder().encode(local),
              let json = String(data: data, encoding: .utf8) else {
            throw AuthError.invalidCredentials("儲存失敗，請再試一次")
        }
        KeychainHelper.save(json, for: Self.userKey)
        return User(id: 1, username: username, email: email, confirmed: true, blocked: false)
    }

    func login(identifier: String, password: String) throws -> User {
        guard let local = loadUser() else {
            throw AuthError.invalidCredentials("帳號不存在，請先註冊")
        }
        let identifierMatch = local.email.lowercased() == identifier.lowercased()
            || local.username.lowercased() == identifier.lowercased()
        guard identifierMatch, local.password == password else {
            throw AuthError.invalidCredentials("帳號或密碼錯誤")
        }
        return User(id: 1, username: local.username, email: local.email, confirmed: true, blocked: false)
    }

    private func loadUser() -> LocalUser? {
        guard let json = KeychainHelper.load(for: Self.userKey),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(LocalUser.self, from: data)
    }
}
