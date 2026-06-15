import Foundation

enum FunTimeAPI {
    static let proxyBase = URL(string: "https://www.funtime.com.tw/api/proxy/")!
    static let mediaHost = "https://mgmt.funtime.com.tw"

    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: mediaHost + path)
    }

    static func date(_ string: String?) -> Date {
        guard let string else { return Date() }
        return isoWithFraction.date(from: string)
            ?? isoPlain.date(from: string)
            ?? Date()
    }

    private static let isoWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain = ISO8601DateFormatter()

    static func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(
            url: proxyBase.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.badURL
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw APIError.badURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

enum APIError: LocalizedError {
    case badURL
    case badStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:           return "網址錯誤"
        case .badStatus(let c): return "伺服器回應錯誤（\(c)）"
        case .decoding:         return "資料格式解析失敗"
        }
    }
}
