import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Item.createdAt, order: .reverse) private var allItems: [Item]
    @State private var searchText = ""
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var showAddItem = false
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var showRateAlert = false
    @State private var rateInput = ""
    
    // Rename and Delete state
    @State private var categoryToRename: Category?
    @State private var renameInput = ""
    @State private var showRenameAlert = false
    
    @State private var categoryToDelete: Category?
    @State private var showDeleteRestrictedAlert = false
    @State private var showDeleteConfirmAlert = false

    private var searchResults: [Item] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let lowered = trimmed.lowercased()
        return allItems.filter { item in
            item.name.lowercased().contains(lowered)
            || item.tags.contains(where: { $0.name.lowercased().contains(lowered) })
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    if searchResults.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ForEach(searchResults) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ItemRowView(item: item)
                            }
                        }
                    }
                } else {
                    ForEach(categories) { category in
                        NavigationLink(destination: CategoryDetailView(category: category)) {
                            HStack {
                                Text(category.name)
                                Spacer()
                                Text("\(category.items.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                prepareDelete(category)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            Button {
                                prepareRename(category)
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }

                    // Inline add category
                    if isAddingCategory {
                        TextField("分类名称", text: $newCategoryName)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                saveNewCategory()
                            }
                            .onChange(of: isTextFieldFocused) { _, isFocused in
                                if !isFocused && isAddingCategory {
                                    saveNewCategory()
                                }
                            }
                    } else {
                        Button {
                            isAddingCategory = true
                            isTextFieldFocused = true
                        } label: {
                            Label("添加分类", systemImage: "plus")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("分类")
            .searchable(text: $searchText, prompt: "搜索物品名称 / 标签")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Picker("币种", selection: $displayCurrency) {
                                ForEach(Constants.Currency.allCases, id: \.self) { currency in
                                    Text(currency.symbol).tag(currency.rawValue)
                                }
                            }
                            
                            Button {
                                rateInput = String(format: "%.2f", exchangeRate)
                                showRateAlert = true
                            } label: {
                                Label("修改汇率 (\(String(format: "%.2f", exchangeRate)))", systemImage: "arrow.left.and.right.circle")
                            }
                        } label: {
                            Image(systemName: "dollarsign.circle")
                        }

                        Button {
                            showAddItem = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView()
            }
            .alert("修改汇率", isPresented: $showRateAlert) {
                TextField("1 USD = ? CNY", text: $rateInput)
                    .keyboardType(.decimalPad)
                Button("取消", role: .cancel) {}
                Button("确定") {
                    if let newRate = Double(rateInput), newRate > 0 {
                        exchangeRate = newRate
                    }
                }
            } message: {
                Text("请输入 1 美元兑换人民币的汇率。")
            }
            .alert("重命名分类", isPresented: $showRenameAlert) {
                TextField("新名称", text: $renameInput)
                Button("取消", role: .cancel) {}
                Button("保存") {
                    if let category = categoryToRename {
                        category.name = renameInput.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
            .alert("无法删除", isPresented: $showDeleteRestrictedAlert) {
                Button("我知道了", role: .cancel) {}
            } message: {
                Text("该分类下仍有物品。请先将物品清空，然后再尝试删除。")
            }
            .alert("确认删除", isPresented: $showDeleteConfirmAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    if let category = categoryToDelete {
                        modelContext.delete(category)
                    }
                }
            } message: {
                Text("您确定要删除这个空分类吗？")
            }
        }
    }

    private func saveNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let category = Category(name: trimmed)
            modelContext.insert(category)
        }
        newCategoryName = ""
        isAddingCategory = false
    }
    
    private func prepareRename(_ category: Category) {
        categoryToRename = category
        renameInput = category.name
        showRenameAlert = true
    }
    
    private func prepareDelete(_ category: Category) {
        categoryToDelete = category
        if !category.items.isEmpty {
            showDeleteRestrictedAlert = true
        } else {
            showDeleteConfirmAlert = true
        }
    }
}
