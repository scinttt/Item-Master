import Foundation
import SwiftData

// MARK: - Tag
/// 用户自定义标签，用于搜索和统计
@Model
final class Tag {
    var id: UUID
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \Item.tags)
    var items: [Item]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.items = []
    }
}
