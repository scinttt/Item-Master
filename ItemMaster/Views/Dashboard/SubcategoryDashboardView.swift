import SwiftUI
import SwiftData
import Charts

struct SubcategoryDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    @Query private var items: [Item]
    @State private var viewModel: DashboardViewModel

    // UI 状态
    @State private var showAddItem = false
    @State private var isAddingSubcategory = false
    @State private var newSubcategoryName = ""
    @FocusState private var isTextFieldFocused: Bool

    @State private var subcategoryToRename: Subcategory?
    @State private var renameInput = ""
    @State private var showRenameAlert = false

    @State private var subcategoryToDelete: Subcategory?
    @State private var showDeleteRestrictedAlert = false
    @State private var showDeleteConfirmAlert = false

    init(category: Category, initialSegment: Int) {
        self.category = category
        let categoryID = category.id
        _items = Query(filter: #Predicate<Item> { item in
            item.category.id == categoryID
        })

        let vm = DashboardViewModel()
        vm.selectedSegment = initialSegment
        _viewModel = State(initialValue: vm)
    }

    private struct SubcategoryStat: Identifiable {
        var id: String { subcategory?.id.uuidString ?? "uncategorized" }
        let subcategory: Subcategory?
        let name: String
        let value: Double
    }

    private var chartData: [SubcategoryStat] {
        let categoryItems = items.filter { $0.category.id == category.id }

        var dict = [String: (subcategory: Subcategory?, value: Double)]()

        for item in categoryItems {
            if let sub = item.subcategory {
                let key = sub.id.uuidString
                if let existing = dict[key] {
                    dict[key] = (sub, existing.value + viewModel.calculateValue(for: item))
                } else {
                    dict[key] = (sub, viewModel.calculateValue(for: item))
                }
            } else {
                // 未分类物品
                let key = "uncategorized"
                if let existing = dict[key] {
                    dict[key] = (nil, existing.value + viewModel.calculateValue(for: item))
                } else {
                    dict[key] = (nil, viewModel.calculateValue(for: item))
                }
            }
        }

        return dict.values.map { SubcategoryStat(subcategory: $0.subcategory, name: $0.subcategory?.name ?? "\(category.name)(未分类)", value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    private var totalValue: Double {
        chartData.reduce(0) { $0 + $1.value }
    }
    
    private var totalCount: Double {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    private var totalPrice: Double {
        items.reduce(0) { sum, item in
            let convertedPrice = CurrencyHelper.convert(item.unitPrice, from: item.originalCurrency, to: displayCurrency, rate: exchangeRate)
            return sum + (convertedPrice * Double(item.quantity))
        }
    }

    var body: some View {
        List {
            // 图表 Section
            Section {
                VStack(spacing: 16) {
                    Picker("图表类型", selection: $viewModel.selectedSegment) {
                        Text("物品总数").tag(0)
                        Text("物品总价").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if items.isEmpty {
                        ContentUnavailableView {
                            Label("该分类下暂无物品", systemImage: "tray")
                        } description: {
                            Text("在此分类下添加二级分类或物品后即可查看统计")
                        } actions: {
                            VStack(spacing: 8) {
                                Button("添加物品") {
                                    showAddItem = true
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("添加二级分类") {
                                    isAddingSubcategory = true
                                    isTextFieldFocused = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .frame(height: 200)
                    } else {
                        // 饼图
                        Chart(chartData) { stat in
                            SectorMark(
                                angle: .value("数值", stat.value),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("二级分类", stat.name))
                        }
                        .frame(height: 240)
                        .chartBackground { chartProxy in
                            GeometryReader { geometry in
                                let frame = geometry[chartProxy.plotAreaFrame]
                                // 中心点击区域：使用 NavigationLink 进行值导航
                                NavigationLink(value: CategoryItemsWrapper(category: category)) {
                                    VStack(spacing: 4) {
                                        if viewModel.selectedSegment == 0 {
                                            Text("\(Int(totalCount)) 个物品")
                                                .font(.headline)
                                                .bold()
                                                .foregroundStyle(.primary)
                                        } else {
                                            Text(CurrencyHelper.format(totalPrice, to: displayCurrency))
                                                .font(.headline)
                                                .bold()
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .frame(width: frame.width * 0.5, height: frame.height * 0.5)
                                .background(Color.black.opacity(0.001))
                                .clipShape(Circle())
                                .zIndex(1)
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // 二级分类列表 Section
            Section(header: Text("二级分类明细")) {
                // 使用 category.subcategories 来支持排序和编辑
                ForEach(category.subcategories.sorted(by: { $0.sortOrder < $1.sortOrder })) { subcategory in
                    let stat = chartData.first(where: { $0.subcategory?.id == subcategory.id })
                    let value = stat?.value ?? 0.0

                    NavigationLink(value: subcategory) {
                        HStack {
                            Text(subcategory.name)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(viewModel.formatValue(value))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if totalValue > 0 {
                                    Text(viewModel.calculatePercentage(value: value, total: totalValue))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            prepareDelete(subcategory)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        Button {
                            prepareRename(subcategory)
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
                .onMove(perform: moveSubcategories)

                // 未分类物品（如果存在）
                if !items.isEmpty, let uncategorizedStat = chartData.first(where: { $0.subcategory == nil }) {
                    NavigationLink(value: UncategorizedItemsWrapper(category: category)) {
                        HStack {
                            Text(uncategorizedStat.name)
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(viewModel.formatValue(uncategorizedStat.value))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if totalValue > 0 {
                                    Text(viewModel.calculatePercentage(value: uncategorizedStat.value, total: totalValue))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // 添加二级分类按钮
                if isAddingSubcategory {
                    TextField("二级分类名称", text: $newSubcategoryName)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            saveNewSubcategory()
                        }
                        .onChange(of: isTextFieldFocused) { _, isFocused in
                            if !isFocused && isAddingSubcategory {
                                saveNewSubcategory()
                            }
                        }
                        
                } else {
                    Button {
                        isAddingSubcategory = true
                        isTextFieldFocused = true
                    } label: {
                        Label("添加二级分类", systemImage: "plus.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
        .alert("重命名二级分类", isPresented: $showRenameAlert) {
            TextField("新名称", text: $renameInput)
            Button("取消", role: .cancel) {}
            Button("保存") {
                if let subcategory = subcategoryToRename {
                    subcategory.name = renameInput.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        .alert("无法删除", isPresented: $showDeleteRestrictedAlert) {
            Button("我知道了", role: .cancel) {}
        } message: {
            Text("该二级分类下仍有物品。请先将物品清空或移动到其他分类，然后再尝试删除。")
        }
        .alert("确认删除", isPresented: $showDeleteConfirmAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let subcategory = subcategoryToDelete {
                    modelContext.delete(subcategory)
                }
            }
        } message: {
            Text("您确定要删除这个空二级分类吗？")
        }
    }

    // MARK: - Actions
    private func saveNewSubcategory() {
        let trimmed = newSubcategoryName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let subcategory = Subcategory(name: trimmed, parentCategory: category, sortOrder: category.subcategories.count)
            modelContext.insert(subcategory)
            category.subcategories.append(subcategory)
        }
        newSubcategoryName = ""
        isAddingSubcategory = false
    }

    private func prepareRename(_ subcategory: Subcategory) {
        subcategoryToRename = subcategory
        renameInput = subcategory.name
        showRenameAlert = true
    }

    private func prepareDelete(_ subcategory: Subcategory) {
        subcategoryToDelete = subcategory
        if !subcategory.items.isEmpty {
            showDeleteRestrictedAlert = true
        } else {
            showDeleteConfirmAlert = true
        }
    }

    private func moveSubcategories(from source: IndexSet, to destination: Int) {
        var sortedSubs = category.subcategories.sorted(by: { $0.sortOrder < $1.sortOrder })
        sortedSubs.move(fromOffsets: source, toOffset: destination)
        for index in 0..<sortedSubs.count {
            sortedSubs[index].sortOrder = index
        }
    }
}

// MARK: - 未分类物品包装器（用于导航）
struct UncategorizedItemsWrapper: Hashable {
    let category: Category
}
