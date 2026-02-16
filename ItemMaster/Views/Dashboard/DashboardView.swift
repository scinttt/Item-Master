import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate

    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var viewModel = DashboardViewModel()

    // UI 状态
    @State private var searchText = ""
    @State private var showAddItem = false
    @State private var showRateAlert = false
    @State private var rateInput = ""
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @FocusState private var isTextFieldFocused: Bool

    @State private var categoryToRename: Category?
    @State private var renameInput = ""
    @State private var showRenameAlert = false

    @State private var categoryToDelete: Category?
    @State private var showDeleteRestrictedAlert = false
    @State private var showDeleteConfirmAlert = false

    private struct CategoryStat: Identifiable {
        var id: UUID { category.id }
        let category: Category
        let value: Double
    }

    private var chartData: [CategoryStat] {
        var dict = [UUID: (category: Category, value: Double)]()
        for item in items {
            let cat = item.category
            let val = viewModel.calculateValue(for: item)
            if let existing = dict[cat.id] {
                dict[cat.id] = (cat, existing.value + val)
            } else {
                dict[cat.id] = (cat, val)
            }
        }
        return dict.values.map { CategoryStat(category: $0.category, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    private var totalValue: Double {
        chartData.reduce(0) { $0 + $1.value }
    }
    
    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var searchResults: [Item] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let lowered = trimmed.lowercased()
        return items.filter { item in
            item.name.lowercased().contains(lowered)
            || item.tags.contains(where: { $0.name.lowercased().contains(lowered) })
            || item.category.name.lowercased().contains(lowered)
            || (item.subcategory?.name.lowercased().contains(lowered) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    searchResultsSection
                } else {
                    statisticsHeaderSection
                    categoryListSection
                }
            }
            .navigationTitle("统计")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索物品、标签、分类")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // 货币设置菜单
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

                        // 添加物品按钮
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
            .navigationDestination(for: Category.self) { category in
                SubcategoryDashboardView(category: category, initialSegment: viewModel.selectedSegment)
            }
            .navigationDestination(for: Subcategory.self) { subcategory in
                SubcategoryItemsView(subcategory: subcategory)
            }
            .navigationDestination(for: UncategorizedItemsWrapper.self) { wrapper in
                UncategorizedItemsView(category: wrapper.category)
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
    
    // MARK: - 搜索结果
    @ViewBuilder
    private var searchResultsSection: some View {
        if searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            Section("搜索结果") {
                ForEach(searchResults) { item in
                    NavigationLink(value: item) {
                        ItemRowView(item: item)
                    }
                }
            }
        }
    }

    // MARK: - 统计图表区域
    @ViewBuilder
    private var statisticsHeaderSection: some View {
        Section {
            VStack(spacing: 16) {
                Picker("图表类型", selection: $viewModel.selectedSegment) {
                    Text("物品总数").tag(0)
                    Text("物品总价").tag(1)
                }
                .pickerStyle(.segmented)

                if items.isEmpty {
                    ContentUnavailableView("暂无数据", systemImage: "chart.pie", description: Text("添加物品后即可查看统计"))
                        .frame(height: 200)
                } else {
                    // 饼图
                    Chart(chartData) { stat in
                        SectorMark(
                            angle: .value("数值", stat.value),
                            innerRadius: .ratio(0.65),
                            angularInset: 2.0
                        )
                        .cornerRadius(8)
                        .foregroundStyle(by: .value("分类", stat.category.name))
                    }
                    .frame(height: 240)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            let frame = geometry[chartProxy.plotAreaFrame]
                            VStack(spacing: 4) {
                                Text(viewModel.centerTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(viewModel.formatValue(totalValue))
                                    .font(.title2)
                                    .bold()
                                    .multilineTextAlignment(.center)
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    // MARK: - 分类列表区域
    @ViewBuilder
    private var categoryListSection: some View {
        Section(header: Text("分类明细")) {
            // 使用 @Query 的 categories 来支持排序和编辑
            ForEach(categories) { category in
                let stat = chartData.first(where: { $0.category.id == category.id })
                let value = stat?.value ?? 0.0

                NavigationLink(value: category) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(category.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text("(\(viewModel.calculatePercentage(value: value, total: totalValue)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(viewModel.formatValue(value))
                            .font(.subheadline)
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
            .onMove(perform: moveCategories)

            // 添加分类按钮
            addCategoryButton
        }
    }

    private var addCategoryButton: some View {
        Group {
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
                    Label("添加分类", systemImage: "plus.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    // MARK: - Actions
    private func saveNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let category = Category(name: trimmed, sortOrder: categories.count)
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

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var revisedItems = categories
        revisedItems.move(fromOffsets: source, toOffset: destination)
        for index in 0..<revisedItems.count {
            revisedItems[index].sortOrder = index
        }
    }
}
