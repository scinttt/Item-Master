import SwiftUI
import SwiftData

struct SubcategoryItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    let subcategory: Subcategory
    
    @State private var sortOption: Constants.SortOption = .expiryDate

    init(subcategory: Subcategory) {
        self.subcategory = subcategory
        let subcategoryID = subcategory.id
        _items = Query(filter: #Predicate<Item> { item in
            item.subcategory?.id == subcategoryID
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
        .navigationTitle(subcategory.name)
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
