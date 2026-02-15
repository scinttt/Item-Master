import Foundation
import SwiftData

// MARK: - Item
@Model
final class Item {
    var id: UUID
    var name: String

    // 必填
    var category: Category
    var subcategory: Subcategory?

    // 位置（可选）
    var location: Location?
    var sublocation: Sublocation?

    // 数量相关
    var quantity: Int

    // 价格
    var unitPrice: Double?
    var originalCurrency: String

    // 日期
    var acquiredDate: Date?
    var expiryDate: Date?
    var shelfLifeDays: Int?

    // 补货通知
    var restockIntervalDays: Int?
    var lastRestockedDate: Date?
    var isRestockNotified: Bool

    // 标签（多对多）
    var tags: [Tag]

    // 图片
    var imageFilename: String?

    // 描述
    var notes: String?

    // 元数据
    var createdAt: Date
    var updatedAt: Date

    // MARK: - 计算属性（不持久化）

    /// 是否即将过期（7天内）
    @Transient
    var isExpiringSoon: Bool {
        guard let expiry = expiryDate else { return false }
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        return daysLeft >= 0 && daysLeft <= 7
    }

    /// 是否已过期
    @Transient
    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }

    /// 是否需要补货（库存为0，或超过补货间隔天数）
    @Transient
    var needsRestock: Bool {
        if quantity == 0 { return true }
        guard let days = restockIntervalDays,
              let lastDate = lastRestockedDate else { return false }
        let daysSinceRestock = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceRestock >= days
    }

    init(
        name: String = "",
        category: Category,
        subcategory: Subcategory? = nil,
        location: Location? = nil,
        sublocation: Sublocation? = nil,
        quantity: Int = 1,
        unitPrice: Double? = nil,
        originalCurrency: String = "USD",
        acquiredDate: Date? = nil,
        expiryDate: Date? = nil,
        shelfLifeDays: Int? = nil,
        restockIntervalDays: Int? = nil,
        imageFilename: String? = nil,
        notes: String? = nil,
        tags: [Tag] = []
    ) {
        let newId = UUID()
        self.id = newId
        // name 为空时默认用 UUID
        self.name = name.isEmpty ? newId.uuidString : name
        self.category = category
        self.subcategory = subcategory
        self.location = location
        self.sublocation = sublocation
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.originalCurrency = originalCurrency
        self.acquiredDate = acquiredDate
        self.expiryDate = expiryDate
        self.shelfLifeDays = shelfLifeDays
        self.restockIntervalDays = restockIntervalDays
        self.lastRestockedDate = Date()
        self.isRestockNotified = false
        self.imageFilename = imageFilename
        self.notes = notes
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
