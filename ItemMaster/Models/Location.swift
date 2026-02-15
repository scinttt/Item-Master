import Foundation
import SwiftData

// MARK: - Location
/// 一级位置，e.g. 厨房 / 客厅 / 卧室 / 浴室 / 书房
@Model
final class Location {
    var id: UUID
    var name: String
    var iconName: String? // 预留图标字段
    var coordinatesData: String? // 预留户型图坐标数据 (JSON)
    var isDefault: Bool

    @Relationship(deleteRule: .cascade)
    var sublocations: [Sublocation]

    @Relationship(deleteRule: .nullify)
    var items: [Item]

    init(name: String, iconName: String? = nil, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.isDefault = isDefault
        self.sublocations = []
        self.items = []
    }
}

// MARK: - Sublocation
/// 二级位置，e.g. 厨房 → 冰箱 / 橱柜
/// 不允许三级
@Model
final class Sublocation {
    var id: UUID
    var name: String
    var iconName: String? // 预留图标字段
    var coordinatesData: String? // 预留户型图坐标数据 (JSON)

    var parentLocation: Location?

    @Relationship(deleteRule: .nullify)
    var items: [Item]

    init(name: String, iconName: String? = nil, parentLocation: Location? = nil) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.parentLocation = parentLocation
        self.items = []
    }
}
