import SwiftUI
import SwiftData

struct AllItemsInCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    let category: Category
    
    @State private var sortOption: Constants.SortOption = .expiryDate

    init(category: Category) {
        self.category = category
        let categoryID = category.id
        // 使用 Query 过滤出属于该分类的所有物品，这比直接访问关系数组更可靠
        _items = Query(filter: #Predicate<Item> { item in
            item.category.id == categoryID
        })
    }

    /// 排序逻辑：
    /// 默认(expiryDate): 临期优先 -> 无日期按最近添加
    /// 其他: 按选定维度降序
    private var sortedItems: [Item] {
        items.sorted { a, b in
            switch sortOption {
            case .expiryDate:
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
            case .unitPrice:
                return (a.unitPrice ?? 0) > (b.unitPrice ?? 0)
            case .acquiredDate:
                return (a.acquiredDate ?? .distantPast) > (b.acquiredDate ?? .distantPast)
            case .quantity:
                return a.quantity > b.quantity
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("排序方式", selection: $sortOption) {
                        ForEach(Constants.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down")
                }
            }
        }
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
