import SwiftUI
import SwiftData

struct SubcategoryItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    let subcategory: Subcategory

    init(subcategory: Subcategory) {
        self.subcategory = subcategory
        let subcategoryID = subcategory.id
        _items = Query(filter: #Predicate<Item> { item in
            item.subcategory?.id == subcategoryID
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
        .navigationTitle(subcategory.name)
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
