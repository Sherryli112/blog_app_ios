import Foundation

struct GameProfile: Codable {
    var xp: Int
    var level: Int
    var streakDays: Int
    var lastCheckIn: Date?
    var stamps: [String]

    static func levelTitle(for level: Int) -> String {
        switch level {
        case 1: return "旅行新手"
        case 2: return "背包客"
        case 3: return "城市探索者"
        case 4: return "文化獵人"
        case 5: return "旅遊達人"
        default: return level < 1 ? "旅行新手" : "傳奇旅人"
        }
    }

    static func xpForNextLevel(current level: Int) -> Int {
        level * 500
    }

    var xpInCurrentLevel: Int {
        let base = (level - 1) * 500
        return max(0, xp - base)
    }

    var xpForThisLevel: Int {
        Self.xpForNextLevel(current: level)
    }

    var levelProgress: Double {
        Double(xpInCurrentLevel) / Double(xpForThisLevel)
    }

    var canCheckInToday: Bool {
        guard let last = lastCheckIn else { return true }
        return !Calendar.current.isDateInToday(last)
    }
}
