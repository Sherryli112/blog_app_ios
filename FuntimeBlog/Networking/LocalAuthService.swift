import Foundation
import CryptoKit

struct LocalAuthService {
    /// 多帳號儲存：以 email（小寫）為 key 的字典。
    private static let storeKey = "local_auth_users"
    /// 舊版單一帳號的 key，用於一次性遷移。
    private static let legacyUserKey = "local_auth_user"

    private struct LocalUser: Codable {
        let id: Int
        let username: String
        let email: String
        let passwordHash: String // SHA-256 hash，不儲存明文
    }

    func register(username: String, email: String, password: String) throws -> User {
        var users = loadUsers()
        let emailKey = email.lowercased()

        if users[emailKey] != nil {
            throw AuthError.invalidCredentials("此 Email 已被註冊")
        }
        if users.values.contains(where: { $0.username.lowercased() == username.lowercased() }) {
            throw AuthError.invalidCredentials("此使用者名稱已被使用")
        }

        let nextID = (users.values.map(\.id).max() ?? 0) + 1
        let local = LocalUser(id: nextID, username: username, email: email,
                              passwordHash: Self.hash(password))
        users[emailKey] = local
        saveUsers(users)
        return User(id: nextID, username: username, email: email, confirmed: true, blocked: false)
    }

    func login(identifier: String, password: String) throws -> User {
        let users = loadUsers()
        let id = identifier.lowercased()
        guard let local = users.values.first(where: {
            $0.email.lowercased() == id || $0.username.lowercased() == id
        }) else {
            throw AuthError.invalidCredentials("帳號或密碼錯誤")
        }
        guard local.passwordHash == Self.hash(password) else {
            throw AuthError.invalidCredentials("帳號或密碼錯誤")
        }
        return User(id: local.id, username: local.username, email: local.email,
                    confirmed: true, blocked: false)
    }

    // MARK: - Keychain 讀寫

    private func loadUsers() -> [String: LocalUser] {
        if let json = KeychainHelper.load(for: Self.storeKey),
           let data = json.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: LocalUser].self, from: data) {
            return dict
        }
        // 一次性遷移舊版單一帳號，避免既有使用者資料遺失。
        if let json = KeychainHelper.load(for: Self.legacyUserKey),
           let data = json.data(using: .utf8),
           let legacy = try? JSONDecoder().decode(LegacyLocalUser.self, from: data) {
            let migrated: [String: LocalUser] = [
                legacy.email.lowercased(): LocalUser(
                    id: 1, username: legacy.username, email: legacy.email,
                    passwordHash: Self.hash(legacy.password)  // 明文轉 hash
                )
            ]
            saveUsers(migrated)
            return migrated
        }
        return [:]
    }

    private func saveUsers(_ users: [String: LocalUser]) {
        guard let data = try? JSONEncoder().encode(users),
              let json = String(data: data, encoding: .utf8) else { return }
        KeychainHelper.save(json, for: Self.storeKey)
    }

    /// 舊版單一帳號格式（無 id，密碼以明文 "password" key 儲存），僅供遷移解碼使用。
    private struct LegacyLocalUser: Codable {
        let username: String
        let email: String
        let password: String  // 舊版 key 名稱為 "password"（明文）
    }

    private static func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
