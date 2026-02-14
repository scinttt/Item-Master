import SwiftUI
import SwiftData

struct SubcategoryItemsView: View {
    let subcategory: Subcategory

    /// 排序后的物品列表：临期优先 → 无日期按最近添加
    private var sortedItems: [Item] {
        subcategory.items.sorted { a, b in
            switch (a.expiryDate, b.expiryDate) {
            case let (dateA?, dateB?):
                return dateA < dateB
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return a.createdAt > b.createdAt
            }
        }
    }

    var body: some View {
        List {
            if sortedItems.isEmpty {
                ContentUnavailableView("暂无物品", systemImage: "tray")
            } else {
                ForEach(sortedItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemRowView(item: item)
                    }
                }
            }
        }
        .navigationTitle(subcategory.name)
    }
}
