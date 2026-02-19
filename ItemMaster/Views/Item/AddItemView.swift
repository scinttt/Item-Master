import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Data
    @Query(sort: \Category.sortOrder) private var allCategories: [Category]

    // MARK: - Form State
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    @State private var name = ""
    @State private var quantity: Double = 1.0
    @State private var unit = "个"
    @State private var unitPriceString = ""
    @State private var selectedCurrency: Constants.Currency
    @State private var acquiredDate: Date?
    @State private var expiryDate: Date?
    @State private var shelfLifeDaysString = ""
    @State private var restockIntervalDaysString = ""
    @State private var notes = ""
    @State private var tagInput = ""
    @State private var tagNames: [String] = []

    // Category
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?

    // Location
    @State private var selectedLocation: Location?
    @State private var selectedSublocation: Sublocation?

    // Image
    @State private var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPermissionAlert = false
    
    // Receipt Scanning
    @State private var receiptPickerItem: PhotosPickerItem?
    @State private var isAnalyzingReceipt = false
    @State private var showScanError = false
    @State private var scanErrorMessage = ""
    @State private var showBulkImport = false
    @State private var parsedReceipts: [ParsedReceipt] = []
    @State private var scannedImage: UIImage?

    // Date toggles
    @State private var showAcquiredDate = false
    @State private var showExpiryDate = false

    // Validation
    @State private var showValidationAlert = false
    
    // Focus State
    @FocusState private var isInputActive: Bool

    init(initialCategory: Category? = nil, initialSubcategory: Subcategory? = nil) {
        let initialCurrency = UserDefaults.standard.string(forKey: "globalDisplayCurrency") ?? Constants.Currency.usd.rawValue
        _selectedCurrency = State(initialValue: Constants.Currency(rawValue: initialCurrency) ?? .usd)
        
        _selectedCategory = State(initialValue: initialCategory)
        _selectedSubcategory = State(initialValue: initialSubcategory)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section {
                        PhotosPicker(selection: $receiptPickerItem, matching: .images) {
                            HStack {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.title2)
                                Text("智能扫描订单提取信息")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundColor(.accentColor)
                        }
                    }

                    ItemEditorForm(
                    name: $name,
                    quantity: $quantity,
                    unit: $unit,
                    unitPriceString: $unitPriceString,
                    selectedCurrency: $selectedCurrency,
                    selectedCategory: $selectedCategory,
                    selectedSubcategory: $selectedSubcategory,
                    selectedLocation: $selectedLocation,
                    selectedSublocation: $selectedSublocation,
                    showAcquiredDate: $showAcquiredDate,
                    acquiredDate: $acquiredDate,
                    showExpiryDate: $showExpiryDate,
                    expiryDate: $expiryDate,
                    shelfLifeDaysString: $shelfLifeDaysString,
                    restockIntervalDaysString: $restockIntervalDaysString,
                    tagNames: $tagNames,
                    tagInput: $tagInput,
                    notes: $notes,
                    selectedImage: $selectedImage,
                    photosPickerItem: $photosPickerItem,
                    showCamera: $showCamera,
                    showPermissionAlert: $showPermissionAlert,
                    isInputActive: $isInputActive
                )
            }
            .disabled(isAnalyzingReceipt)
            
            if isAnalyzingReceipt {
                 Color.black.opacity(0.4)
                     .ignoresSafeArea()
                 VStack(spacing: 20) {
                     ProgressView()
                         .scaleEffect(1.5)
                         .tint(.white)
                     Text("AI 正在解析订单并匹配分类...")
                         .font(.headline)
                         .foregroundColor(.white)
                 }
                 .padding()
                 .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray).opacity(0.9)))
            }
        }
        .navigationTitle("添加物品")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveItem() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isInputActive = false
                    }
                }
            }
            .alert("请选择分类", isPresented: $showValidationAlert) {
                Button("好的", role: .cancel) {}
            }
            .alert("需要相机权限", isPresented: $showPermissionAlert) {
                Button("取消", role: .cancel) {}
                Button("去设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("您之前拒绝了相机访问。请前往系统设置开启权限，以便为物品拍摄照片。")
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    selectedImage = image
                }
            }
            .onChange(of: photosPickerItem) {
                loadPhoto()
            }
            .onChange(of: selectedCategory) {
                selectedSubcategory = nil
            }
            .onChange(of: receiptPickerItem) {
                processReceipt()
            }
            .alert("识别失败", isPresented: $showScanError) {
                Button("好", role: .cancel) { }
            } message: {
                Text(scanErrorMessage)
            }
            .sheet(isPresented: $showBulkImport) {
                BulkImportView(
                    parsedReceipts: parsedReceipts,
                    categories: allCategories,
                    originalImage: scannedImage
                )
            }
        }
    }
    
    // MARK: - Receipt Scanning Logic
    private func processReceipt() {
        guard let item = receiptPickerItem else { return }
        isAnalyzingReceipt = true
        
        let contextString = allCategories.map { category in
            let subNames = category.subcategories.map { $0.name }.joined(separator: ", ")
            return "\(category.name) (Subcategories: [\(subNames)])"
        }.joined(separator: "; ")
        
        Task {
            do {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw ReceiptScannerError.imageProcessingFailed
                }
                
                let parsedItems = try await ReceiptScannerService.shared.parseReceipt(image: image, categoryContext: contextString)
                
                await MainActor.run {
                    withAnimation {
                        isAnalyzingReceipt = false
                        receiptPickerItem = nil
                        
                        if parsedItems.count == 1 {
                            populateForm(with: parsedItems[0])
                        } else if parsedItems.count > 1 {
                            parsedReceipts = parsedItems
                            scannedImage = image
                            showBulkImport = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isAnalyzingReceipt = false
                    scanErrorMessage = error.localizedDescription
                    showScanError = true
                    receiptPickerItem = nil
                }
            }
        }
    }
    
    private func populateForm(with parsed: ParsedReceipt) {
        if let name = parsed.name, !name.isEmpty { self.name = name }
        if let price = parsed.unitPriceString { self.unitPriceString = price }
        if let qty = parsed.quantity { self.quantity = qty }
        if let tags = parsed.tagNames { self.tagNames = tags }
        if let notes = parsed.notes { self.notes = notes }
        
        if let dateString = parsed.acquiredDateString {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                self.acquiredDate = date
                self.showAcquiredDate = true
            }
        }
        
        if let catName = parsed.matchedCategoryName {
            if let match = allCategories.first(where: { $0.name == catName }) {
                self.selectedCategory = match
                
                if let subName = parsed.matchedSubcategoryName {
                    self.selectedSubcategory = match.subcategories.first(where: { $0.name == subName })
                }
            }
        }
    }

    private func loadPhoto() {
        guard let item = photosPickerItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        }
    }

    private func saveItem() {
        guard let category = selectedCategory else {
            showValidationAlert = true
            return
        }

        var imageFilename: String?
        if let image = selectedImage {
            imageFilename = ImageHelper.compressAndSave(image: image)
        }

        var tags: [Tag] = []
        for tagName in tagNames {
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
            if let existing = try? modelContext.fetch(descriptor).first {
                tags.append(existing)
            } else {
                let newTag = Tag(name: tagName)
                modelContext.insert(newTag)
                tags.append(newTag)
            }
        }
        
        let price = Double(unitPriceString)
        let normalized = CurrencyHelper.convert(price, from: selectedCurrency.rawValue, to: Constants.Currency.usd.rawValue, rate: exchangeRate)

        let item = Item(
            name: name,
            category: category,
            subcategory: selectedSubcategory,
            location: selectedLocation,
            sublocation: selectedSublocation,
            quantity: quantity,
            unit: unit,
            unitPrice: price,
            originalCurrency: selectedCurrency.rawValue,
            acquiredDate: showAcquiredDate ? (acquiredDate ?? Date()) : nil,
            expiryDate: showExpiryDate ? (expiryDate ?? Date()) : nil,
            shelfLifeDays: Int(shelfLifeDaysString),
            restockIntervalDays: Int(restockIntervalDaysString),
            imageFilename: imageFilename,
            notes: notes.isEmpty ? nil : notes,
            tags: tags
        )
        item.normalizedPrice = normalized

        modelContext.insert(item)
        category.items.append(item)
        selectedSubcategory?.items.append(item)
        dismiss()
    }
}
