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
    var quantity: Double // 改为 Double 以支持重量、体积等
    var unit: String     // 单位，如 "个", "件", "kg", "ml"
    var minQuantity: Double // 安全库存阈值，低于此值提醒补货

    // 价格
    var unitPrice: Double?
    var originalCurrency: String

    // 预留元数据
    var brand: String?   // 品牌
    var barcode: String? // 条形码
    var url: String?     // 购买链接或说明书链接
    var isArchived: Bool // 是否已归档（软删除）
    var isFavorite: Bool // 是否收藏
    var sourceType: String // 记录来源：manual (手动) / ai (识别)

    // 日期
    var acquiredDate: Date?
    var expiryDate: Date?
    var warrantyExpiryDate: Date? // 保修截止日期（针对电子产品）
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

    /// 是否需要补货（低于安全库存，或超过补货间隔天数）
    @Transient
    var needsRestock: Bool {
        if quantity <= minQuantity { return true }
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
        quantity: Double = 1.0,
        unit: String = "个",
        minQuantity: Double = 0.0,
        unitPrice: Double? = nil,
        originalCurrency: String = "USD",
        brand: String? = nil,
        barcode: String? = nil,
        url: String? = nil,
        sourceType: String = "manual",
        acquiredDate: Date? = nil,
        expiryDate: Date? = nil,
        warrantyExpiryDate: Date? = nil,
        shelfLifeDays: Int? = nil,
        restockIntervalDays: Int? = nil,
        imageFilename: String? = nil,
        notes: String? = nil,
        tags: [Tag] = []
    ) {
        let newId = UUID()
        self.id = newId
        self.name = name.isEmpty ? newId.uuidString : name
        self.category = category
        self.subcategory = subcategory
        self.location = location
        self.sublocation = sublocation
        self.quantity = quantity
        self.unit = unit
        self.minQuantity = minQuantity
        self.unitPrice = unitPrice
        self.originalCurrency = originalCurrency
        self.brand = brand
        self.barcode = barcode
        self.url = url
        self.sourceType = sourceType
        self.isArchived = false
        self.isFavorite = false
        self.acquiredDate = acquiredDate
        self.expiryDate = expiryDate
        self.warrantyExpiryDate = warrantyExpiryDate
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
