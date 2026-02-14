import SwiftUI
import SwiftData

struct AllItemsInCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    let category: Category

    init(category: Category) {
        self.category = category
        let categoryID = category.id
        // 使用 Query 过滤出属于该分类的所有物品，这比直接访问关系数组更可靠
        _items = Query(filter: #Predicate<Item> { item in
            item.category.id == categoryID
        })
    }

    /// 排序后的物品列表：临期优先 → 无日期按最近添加
    private var sortedItems: [Item] {
        items.sorted { a, b in
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
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle("所有 \(category.name)")
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = sortedItems[index]
            if let filename = item.imageFilename {
                ImageStorage.delete(filename: filename)
            }
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
