import SwiftUI
import SwiftData

struct ItemSortableListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isGridView") private var isGridView = false
    
    let items: [Item]
    let title: String
    let initialCategory: Category?
    let initialSubcategory: Subcategory?
    
    @State private var sortOption: Constants.SortOption = .expiryDate
    @State private var isAscending: Bool = true
    @State private var showAddItem = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    /// 排序逻辑
    private var sortedItems: [Item] {
        items.sorted { a, b in
            let result: Bool
            switch sortOption {
            case .expiryDate:
                switch (a.expiryDate, b.expiryDate) {
                case let (dateA?, dateB?): result = dateA < dateB
                case (_?, nil): result = true
                case (nil, _?): result = false
                case (nil, nil): return a.createdAt > b.createdAt
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
        VStack(spacing: 0) {
            if isGridView {
                gridView
            } else {
                listView
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // 布局切换按钮
                Button {
                    isGridView.toggle()
                } label: {
                    Label(isGridView ? "列表视图" : "网格视图", systemImage: isGridView ? "list.bullet" : "square.grid.2x2")
                }

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
            AddItemView(initialCategory: initialCategory, initialSubcategory: initialSubcategory)
        }
    }

    private var listView: some View {
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
    }

    private var gridView: some View {
        ScrollView {
            if sortedItems.isEmpty {
                ContentUnavailableView("暂无物品", systemImage: "tray")
                    .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(sortedItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            gridCell(for: item)
                        }
                        .buttonStyle(.plain) // 防止 NavigationLink 的默认点击样式干扰
                    }
                }
            }
        }
    }

    private func gridCell(for item: Item) -> some View {
        ZStack {
            // 用透明颜色和 aspectRatio 撑开正方形空间，不使用 GeometryReader
            Color.clear
                .aspectRatio(1, contentMode: .fill)
            
            if let filename = item.imageFilename,
               let uiImage = ImageStorage.load(filename: filename) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 30))
                }
            }
        }
        .contentShape(Rectangle()) // 确保整个区域可点击
        .clipped()
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
