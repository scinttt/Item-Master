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
                Button { isGridView.toggle() } label: {
                    Label(isGridView ? "列表视图" : "网格视图", systemImage: isGridView ? "list.bullet" : "square.grid.2x2")
                }
                Button { isAscending.toggle() } label: {
                    Label(isAscending ? "升序" : "降序", systemImage: isAscending ? "arrow.up" : "arrow.down")
                }
                Menu {
                    Picker("排序方式", selection: $sortOption) {
                        ForEach(Constants.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                Button { showAddItem = true } label: {
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
                    NavigationLink(destination: LazyView(ItemDetailView(item: item))) {
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
                        NavigationLink(destination: LazyView(ItemDetailView(item: item))) {
                            gridCell(for: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func gridCell(for item: Item) -> some View {
        ZStack {
            Color.gray.opacity(0.05)
                .aspectRatio(1, contentMode: .fill)
            ItemImageView(filename: item.imageFilename)
                .scaledToFill()
        }
        .contentShape(Rectangle())
        .clipped()
    }

    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { sortedItems[$0] }
        for item in itemsToDelete {
            if let filename = item.imageFilename {
                ImageStorage.delete(filename: filename)
            }
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
