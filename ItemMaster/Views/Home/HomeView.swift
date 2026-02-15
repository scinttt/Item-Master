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
    
    @State private var showRateAlert = false
    @State private var rateInput = ""

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
                    }

                    // Inline add category
                    if isAddingCategory {
                        TextField("分类名称", text: $newCategoryName)
                            .onSubmit {
                                saveNewCategory()
                            }
                    } else {
                        Button {
                            isAddingCategory = true
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
}
