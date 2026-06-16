import Foundation

struct APIAuthService {
    private struct LoginRequest: Encodable {
        let identifier: String
        let password: String
    }

    private struct LoginResponse: Decodable {
        let jwt: String
        let user: User
    }

    func login(identifier: String, password: String) async throws -> (token: String, user: User) {
        let body = LoginRequest(identifier: identifier, password: password)
        let url = FunTimeAPI.proxyBase.appendingPathComponent("auth/local")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badURL }
        guard (200..<300).contains(http.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AuthError.invalidCredentials(message)
            }
            throw APIError.badStatus(http.statusCode)
        }
        do {
            let result = try JSONDecoder().decode(LoginResponse.self, from: data)
            return (result.jwt, result.user)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func fetchMe(token: String) async throws -> User {
        var request = URLRequest(url: FunTimeAPI.proxyBase.appendingPathComponent("users/me"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try JSONDecoder().decode(User.self, from: data)
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials(let msg): return msg
        }
    }
}
