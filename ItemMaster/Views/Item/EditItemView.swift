import SwiftUI
import SwiftData
import PhotosUI

struct EditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let item: Item
    
    // MARK: - Form State
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    @State private var name: String
    @State private var quantity: Double
    @State private var unit: String
    @State private var unitPriceString: String
    @State private var selectedCurrency: Constants.Currency
    @State private var acquiredDate: Date?
    @State private var expiryDate: Date?
    @State private var shelfLifeDaysString: String
    @State private var restockIntervalDaysString: String
    @State private var notes: String
    @State private var tagInput = ""
    @State private var tagNames: [String]
    
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
    @State private var imageDeleted = false
    
    // Date toggles
    @State private var showAcquiredDate: Bool
    @State private var showExpiryDate: Bool
    
    // Validation
    @State private var showValidationAlert = false
    
    // Focus State
    @FocusState private var isInputActive: Bool
    
    init(item: Item) {
        self.item = item
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity)
        _unit = State(initialValue: item.unit)
        _unitPriceString = State(initialValue: item.unitPrice.map { "\($0)" } ?? "")
        
        let initialCurrencyString = item.originalCurrency.isEmpty ? 
            (UserDefaults.standard.string(forKey: "globalDisplayCurrency") ?? Constants.Currency.usd.rawValue) : 
            item.originalCurrency
        
        _selectedCurrency = State(initialValue: Constants.Currency(rawValue: initialCurrencyString) ?? .usd)
        
        _acquiredDate = State(initialValue: item.acquiredDate)
        _expiryDate = State(initialValue: item.expiryDate)
        _shelfLifeDaysString = State(initialValue: item.shelfLifeDays.map { "\($0)" } ?? "")
        _restockIntervalDaysString = State(initialValue: item.restockIntervalDays.map { "\($0)" } ?? "")
        _notes = State(initialValue: item.notes ?? "")
        _tagNames = State(initialValue: item.tags.map { $0.name })
        
        _selectedCategory = State(initialValue: item.category)
        _selectedSubcategory = State(initialValue: item.subcategory)
        _selectedLocation = State(initialValue: item.location)
        _selectedSublocation = State(initialValue: item.sublocation)
        
        _showAcquiredDate = State(initialValue: item.acquiredDate != nil)
        _showExpiryDate = State(initialValue: item.expiryDate != nil)
        
        if let filename = item.imageFilename {
            _selectedImage = State(initialValue: ImageStorage.load(filename: filename))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
            .navigationTitle("编辑物品")
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
                    imageDeleted = false
                }
            }
            .onChange(of: photosPickerItem) {
                loadPhoto()
            }
            .onChange(of: selectedCategory) {
                if selectedCategory?.id != item.category.id {
                    selectedSubcategory = nil
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
                imageDeleted = false
            }
        }
    }
    
    private func saveItem() {
        guard let category = selectedCategory else {
            showValidationAlert = true
            return
        }
        
        var finalImageFilename = item.imageFilename
        
        if imageDeleted {
            if let oldFilename = item.imageFilename {
                ImageStorage.delete(filename: oldFilename)
            }
            finalImageFilename = nil
        }
        
        if let newImage = selectedImage, newImage != ImageStorage.load(filename: item.imageFilename ?? "") {
            if let oldFilename = item.imageFilename {
                ImageStorage.delete(filename: oldFilename)
            }
            finalImageFilename = ImageHelper.compressAndSave(image: newImage)
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
        
        // Track old values to update collections and trigger UI refresh
        let oldCategory = item.category
        let oldSubcategory = item.subcategory
        
        item.name = name.isEmpty ? item.id.uuidString : name
        
        // Update Category relationship and collections
        if oldCategory.id != category.id {
            item.category = category
            oldCategory.items.removeAll { $0.id == item.id }
            if !category.items.contains(where: { $0.id == item.id }) {
                category.items.append(item)
            }
        }
        
        // Update Subcategory relationship and collections
        if oldSubcategory?.id != selectedSubcategory?.id {
            item.subcategory = selectedSubcategory
            oldSubcategory?.items.removeAll { $0.id == item.id }
            if let newSub = selectedSubcategory {
                if !newSub.items.contains(where: { $0.id == item.id }) {
                    newSub.items.append(item)
                }
            }
        }
        
        item.location = selectedLocation
        item.sublocation = selectedSublocation
        item.quantity = quantity
        item.unit = unit
        item.unitPrice = Double(unitPriceString)
        item.originalCurrency = selectedCurrency.rawValue
        
        // Calculate and save normalized price
        let price = Double(unitPriceString)
        let normalized = CurrencyHelper.convert(price, from: selectedCurrency.rawValue, to: Constants.Currency.usd.rawValue, rate: exchangeRate)
        item.normalizedPrice = normalized
        
        item.acquiredDate = showAcquiredDate ? (acquiredDate ?? Date()) : nil
        item.expiryDate = showExpiryDate ? (expiryDate ?? Date()) : nil
        item.shelfLifeDays = Int(shelfLifeDaysString)
        item.restockIntervalDays = Int(restockIntervalDaysString)
        item.imageFilename = finalImageFilename
        item.notes = notes.isEmpty ? nil : notes
        item.tags = tags
        item.updatedAt = Date()
        
        try? modelContext.save()
        dismiss()
    }
}
