import SwiftUI
import SwiftData

struct AllItemsInCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    let category: Category
    
    @State private var sortOption: Constants.SortOption = .expiryDate
    @State private var isAscending: Bool = true
    @State private var showAddItem = false

    init(category: Category) {
        self.category = category
        let categoryID = category.id
        // 使用 Query 过滤出属于该分类的所有物品，这比直接访问关系数组更可靠
        _items = Query(filter: #Predicate<Item> { item in
            item.category.id == categoryID
        })
    }

    /// 排序逻辑：
    /// 核心逻辑计算后，根据 isAscending 决定最终顺序
    private var sortedItems: [Item] {
        items.sorted { a, b in
            let result: Bool
            switch sortOption {
            case .expiryDate:
                // 特殊处理：过期时间排序中，有日期的永远比无日期的靠前
                switch (a.expiryDate, b.expiryDate) {
                case let (dateA?, dateB?):
                    result = dateA < dateB
                case (_?, nil):
                    result = true
                case (nil, _?):
                    result = false
                case (nil, nil):
                    // 均无日期时，按创建时间降序作为后备
                    return a.createdAt > b.createdAt
                }
            case .unitPrice:
                result = (a.unitPrice ?? 0) < (b.unitPrice ?? 0)
            case .acquiredDate:
                result = (a.acquiredDate ?? .distantPast) < (b.acquiredDate ?? .distantPast)
            case .quantity:
                result = a.quantity < b.quantity
            }
            
            return isAscending ? result : !result
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                // 切换升降序按钮
                Button {
                    isAscending.toggle()
                } label: {
                    Label(isAscending ? "升序" : "降序", systemImage: isAscending ? "arrow.up" : "arrow.down")
                }
                
                // 维度选择菜单
                Menu {
                    Picker("排序方式", selection: $sortOption) {
                        ForEach(Constants.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                
                // 添加物品按钮
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView(initialCategory: category)
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
