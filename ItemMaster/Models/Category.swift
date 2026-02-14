import Foundation
import SwiftData

// MARK: - Category
/// 一级分类，e.g. 食物 / 日用品 / 服饰 / 电子产品
/// 支持用户自定义添加
@Model
final class Category {
    var id: UUID
    var name: String
    var isDefault: Bool

    @Relationship(deleteRule: .cascade)
    var subcategories: [Subcategory]

    @Relationship(deleteRule: .nullify)
    var items: [Item]

    init(name: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isDefault = isDefault
        self.subcategories = []
        self.items = []
    }
}

// MARK: - Subcategory
/// 二级分类，e.g. 食物 → 零食 / 蔬菜 / 肉类
/// 不允许三级
@Model
final class Subcategory {
    var id: UUID
    var name: String

    var parentCategory: Category?

    @Relationship(deleteRule: .nullify)
    var items: [Item]

    init(name: String, parentCategory: Category? = nil) {
        self.id = UUID()
        self.name = name
        self.parentCategory = parentCategory
        self.items = []
    }
}
