import Foundation

enum Constants {

    // MARK: Default Categories（默认一级分类）
    static let defaultCategories: [String] = [
        "食物",
        "日用品",
        "服饰",
        "电子产品"
    ]

    // MARK: Default Locations（默认一级位置）
    static let defaultLocations: [String] = [
        "厨房",
        "客厅",
        "卧室",
        "浴室",
        "书房"
    ]

    // MARK: Expiry Warning
    /// 临期提醒阈值（天），距过期日期在此天数内视为临期
    static let expiryWarningDays: Int = 7

    // MARK: Sorting Options
    enum SortOption: String, CaseIterable, Identifiable {
        case expiryDate   = "过期时间"
        case unitPrice    = "购买价格"
        case acquiredDate = "获取时间"
        case quantity     = "数量"

        var id: String { rawValue }
    }

    // MARK: Currency
    enum Currency: String, Codable, CaseIterable {
        case usd = "USD"
        case cny = "CNY"

        var symbol: String {
            self == .usd ? "$" : "¥"
        }
    }

    static let usdToCnyRate: Double = 7.0
}
