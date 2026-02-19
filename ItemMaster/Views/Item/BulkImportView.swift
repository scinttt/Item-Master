import SwiftUI
import SwiftData
import PhotosUI

struct BulkImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var importableItems: ImportableItems
    @State private var selectedCurrency: Constants.Currency
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    
    @Query(sort: \Category.sortOrder) private var allCategories: [Category]
    
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    private var items: [ImportableItem] {
        importableItems.items
    }
    
    init(parsedReceipts: [ParsedReceipt], categories: [Category], originalImage: UIImage? = nil) {
        let initialCurrency = UserDefaults.standard.string(forKey: "globalDisplayCurrency") ?? Constants.Currency.usd.rawValue
        _selectedCurrency = State(initialValue: Constants.Currency(rawValue: initialCurrency) ?? .usd)
        
        _importableItems = State(initialValue: ImportableItems(items: parsedReceipts.map { ImportableItem(raw: $0, contextCategories: categories) }))
    }
    
    private var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(importableItems.items) { item in
                        BulkImportItemRow(
                            item: item,
                            allCategories: allCategories,
                            selectedCurrency: $selectedCurrency
                        )
                        .padding(.horizontal)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("批量导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存 \(selectedCount) 项") {
                        saveSelectedItems()
                    }
                    .disabled(selectedCount == 0)
                }
            }
            .alert("保存失败", isPresented: $showValidationAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func saveSelectedItems() {
        let selectedItems = items.filter { $0.isSelected }
        var savedCount = 0
        var missingCategoryCount = 0
        
        for importable in selectedItems {
            guard let category = importable.selectedCategory else {
                missingCategoryCount += 1
                continue
            }
            
            var tags: [Tag] = []
            for tagName in importable.tagNames {
                let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
                if let existing = try? modelContext.fetch(descriptor).first {
                    tags.append(existing)
                } else {
                    let newTag = Tag(name: tagName)
                    modelContext.insert(newTag)
                    tags.append(newTag)
                }
            }
            
            let price = Double(importable.unitPriceString)
            let normalized = CurrencyHelper.convert(price, from: selectedCurrency.rawValue, to: Constants.Currency.usd.rawValue, rate: exchangeRate)
            
            let newItem = Item(
                name: importable.name,
                category: category,
                subcategory: importable.selectedSubcategory,
                quantity: importable.quantity,
                unit: importable.unit,
                unitPrice: price,
                originalCurrency: selectedCurrency.rawValue,
                acquiredDate: importable.showAcquiredDate ? (importable.acquiredDate ?? Date()) : nil,
                notes: importable.notes.isEmpty ? nil : importable.notes,
                tags: tags
            )
            newItem.normalizedPrice = normalized
            
            modelContext.insert(newItem)
            category.items.append(newItem)
            importable.selectedSubcategory?.items.append(newItem)
            savedCount += 1
        }
        
        if missingCategoryCount > 0 {
            validationMessage = "已保存 \(savedCount) 项，\(missingCategoryCount) 项因缺少分类未保存"
            showValidationAlert = true
        } else {
            dismiss()
        }
    }
}

struct BulkImportItemRow: View {
    let item: ImportableItem
    let allCategories: [Category]
    @Binding var selectedCurrency: Constants.Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("", isOn: Binding(
                    get: { item.isSelected },
                    set: { item.isSelected = $0 }
                ))
                    .labelsHidden()
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("物品名称", text: Binding(
                        get: { item.name },
                        set: { item.name = $0 }
                    ))
                        .font(.headline)
                    
                    HStack {
                        Text(Constants.Currency(rawValue: UserDefaults.standard.string(forKey: "globalDisplayCurrency") ?? "USD")?.symbol ?? "$")
                        TextField("价格", text: Binding(
                            get: { item.unitPriceString },
                            set: { item.unitPriceString = $0 }
                        ))
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        
                        Text("×")
                        
                        TextField("数量", value: Binding(
                            get: { item.quantity },
                            set: { item.quantity = $0 }
                        ), format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 50)
                        
                        Text(item.unit)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Picker("分类", selection: Binding(
                    get: { item.selectedCategory },
                    set: { item.selectedCategory = $0 }
                )) {
                    Text("选择分类").tag(nil as Category?)
                    ForEach(allCategories) { cat in
                        Text(cat.name).tag(cat as Category?)
                    }
                }
                .pickerStyle(.menu)
                
                if let category = item.selectedCategory, !category.subcategories.isEmpty {
                    Picker("子分类", selection: Binding(
                        get: { item.selectedSubcategory },
                        set: { item.selectedSubcategory = $0 }
                    )) {
                        Text("无").tag(nil as Subcategory?)
                        ForEach(category.subcategories) { sub in
                            Text(sub.name).tag(sub as Subcategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("标签:").font(.caption).foregroundColor(.secondary)
                
                if !item.tagNames.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(item.tagNames, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button {
                                    withAnimation {
                                        item.tagNames.removeAll { $0 == tag }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    TextField("添加标签", text: Binding(
                        get: { item.tagInput },
                        set: { item.tagInput = $0 }
                    ))
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .onSubmit {
                            addTag()
                        }
                    
                    Button {
                        addTag()
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .disabled(item.tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            
            Button {
                withAnimation { item.isExpanded.toggle() }
            } label: {
                HStack {
                    Text("更多选项")
                        .font(.caption)
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(.secondary)
            }
            
            if item.isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("单位:")
                        TextField("单位", text: Binding(
                            get: { item.unit },
                            set: { item.unit = $0 }
                        ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }
                    
                    Toggle("获取日期", isOn: Binding(
                        get: { item.showAcquiredDate },
                        set: { item.showAcquiredDate = $0 }
                    ))
                    if item.showAcquiredDate {
                        DatePicker("", selection: Binding(
                            get: { item.acquiredDate ?? Date() },
                            set: { item.acquiredDate = $0 }
                        ), displayedComponents: .date)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("备注:")
                        TextEditor(text: Binding(
                            get: { item.notes },
                            set: { item.notes = $0 }
                        ))
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3))
                            )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func addTag() {
        let trimmed = item.tagInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !item.tagNames.contains(trimmed) {
            withAnimation {
                item.tagNames.append(trimmed)
            }
        }
        item.tagInput = ""
    }
}
