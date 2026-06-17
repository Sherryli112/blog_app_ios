import Foundation
import Observation
import SwiftData

@Observable
final class GameStore {
    private let context: ModelContext
    /// 目前資料範圍：登入者 email（小寫），訪客為空字串。
    private var owner: String = ""

    private(set) var profile: GameProfile = GameProfile(
        xp: 0, level: 1, streakDays: 0, lastCheckIn: nil, stamps: []
    )

    init(context: ModelContext) {
        self.context = context
        loadProfile()
    }

    /// Preview 用：獨立的記憶體內儲存。
    convenience init() {
        self.init(context: PersistenceContainer.makeInMemoryContext())
    }

    /// 測試用：以已知 profile 初始化，不觸碰磁碟。
    convenience init(profile: GameProfile) {
        self.init(context: PersistenceContainer.makeInMemoryContext())
        self.profile = profile
        persist()
    }

    /// 切換目前使用者（登入/登出時呼叫），並載入該使用者的遊戲檔。
    func setOwner(_ email: String?) {
        owner = email?.lowercased() ?? ""
        loadProfile()
    }

    func checkIn() -> Int {
        guard profile.canCheckInToday else { return 0 }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let isConsecutive = profile.lastCheckIn.map {
            Calendar.current.isDate($0, inSameDayAs: yesterday)
        } ?? false

        profile.lastCheckIn = Date()
        profile.streakDays = isConsecutive ? profile.streakDays + 1 : 1
        // 在更新 streakDays 後才計算 bonusXP，確保中斷時正確重置
        let bonusXP = min(profile.streakDays, 7) * 10
        addXP(bonusXP)
        return bonusXP
    }

    func collectStamp(city: String) {
        guard !profile.stamps.contains(city) else { return }
        profile.stamps.append(city)
        addXP(50) // addXP 內部已呼叫 persist()，不重複呼叫
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

    /// 載入目前 owner 的遊戲檔；不存在則建立一筆。
    private func loadProfile() {
        if let entity = fetchEntity() {
            profile = entity.profile
        } else {
            let initial = GameProfile(xp: 0, level: 1, streakDays: 0, lastCheckIn: nil, stamps: [])
            profile = initial
            context.insert(GameProfileEntity(profile: initial, ownerEmail: owner))
            try? context.save()
        }
    }

    private func persist() {
        if let entity = fetchEntity() {
            entity.apply(profile)
        } else {
            context.insert(GameProfileEntity(profile: profile, ownerEmail: owner))
        }
        try? context.save()
    }

    private func fetchEntity() -> GameProfileEntity? {
        let o = owner
        var descriptor = FetchDescriptor<GameProfileEntity>(
            predicate: #Predicate { $0.ownerEmail == o }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
