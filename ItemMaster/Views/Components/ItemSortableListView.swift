import SwiftUI
import SwiftData

struct ItemSortableListView: View {
    let filter: Predicate<Item>
    let title: String
    let initialCategory: Category?
    let initialSubcategory: Subcategory?
    
    @State private var sortOption: Constants.SortOption = .expiryDate
    @State private var isAscending: Bool = true
    @AppStorage("isGridView") private var isGridView = false

    var body: some View {
        ItemSortableListInnerView(
            filter: filter,
            sortOption: $sortOption,
            isAscending: $isAscending,
            isGridView: $isGridView,
            title: title,
            initialCategory: initialCategory,
            initialSubcategory: initialSubcategory
        )
    }
}

private struct ItemSortableListInnerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @Binding var sortOption: Constants.SortOption
    @Binding var isAscending: Bool
    @Binding var isGridView: Bool
    
    let title: String
    let initialCategory: Category?
    let initialSubcategory: Subcategory?
    
    @State private var showAddItem = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    init(
        filter: Predicate<Item>,
        sortOption: Binding<Constants.SortOption>,
        isAscending: Binding<Bool>,
        isGridView: Binding<Bool>,
        title: String,
        initialCategory: Category?,
        initialSubcategory: Subcategory?
    ) {
        self._sortOption = sortOption
        self._isAscending = isAscending
        self._isGridView = isGridView
        self.title = title
        self.initialCategory = initialCategory
        self.initialSubcategory = initialSubcategory
        
        let order: SortOrder = isAscending.wrappedValue ? .forward : .reverse
        let descriptors: [SortDescriptor<Item>]
        switch sortOption.wrappedValue {
        case .expiryDate:
            // 数据库排序：nil 值的处理取决于数据库。通常 nil 在 forward 时排在最前或最后。
            // 之前的内存排序逻辑是将 nil 放在最后（ascending时）。
            descriptors = [SortDescriptor(\Item.expiryDate, order: order), SortDescriptor(\Item.createdAt, order: .reverse)]
        case .unitPrice:
            descriptors = [SortDescriptor(\Item.normalizedPrice, order: order)]
        case .acquiredDate:
            descriptors = [SortDescriptor(\Item.acquiredDate, order: order)]
        case .quantity:
            descriptors = [SortDescriptor(\Item.quantity, order: order)]
        }
        
        _items = Query(filter: filter, sort: descriptors)
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
            if items.isEmpty {
                ContentUnavailableView("暂无物品", systemImage: "tray")
            } else {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        ItemRowView(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
    }

    private var gridView: some View {
        ScrollView {
            if items.isEmpty {
                ContentUnavailableView("暂无物品", systemImage: "tray")
                    .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            gridCell(for: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func gridCell(for item: Item) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                ItemImageView(filename: item.imageFilename)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
    }

    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { items[$0] }
        for item in itemsToDelete {
            if let filename = item.imageFilename {
                ImageStorage.delete(filename: filename)
            }
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
