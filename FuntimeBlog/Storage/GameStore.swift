import Foundation
import Observation

@Observable
final class GameStore {
    private static let storageKey = "gameProfile"

    private(set) var profile: GameProfile

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(GameProfile.self, from: data) {
            profile = decoded
        } else {
            profile = GameProfile(xp: 0, level: 1, streakDays: 0, lastCheckIn: nil, stamps: [])
        }
    }

    func checkIn() -> Int {
        guard profile.canCheckInToday else { return 0 }
        let bonusXP = min(profile.streakDays + 1, 7) * 10
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let isConsecutive = profile.lastCheckIn.map {
            Calendar.current.isDate($0, inSameDayAs: yesterday)
        } ?? false

        profile.lastCheckIn = Date()
        profile.streakDays = isConsecutive ? profile.streakDays + 1 : 1
        addXP(bonusXP)
        return bonusXP
    }

    func collectStamp(city: String) {
        guard !profile.stamps.contains(city) else { return }
        profile.stamps.append(city)
        addXP(50)
        persist()
    }

    func addXPForReading() {
        addXP(5)
    }

    private func addXP(_ amount: Int) {
        profile.xp += amount
        let newLevel = max(1, (profile.xp / 500) + 1)
        profile.level = newLevel
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
