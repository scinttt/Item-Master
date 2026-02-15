import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
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

    // Date toggles
    @State private var showAcquiredDate = false
    @State private var showExpiryDate = false

    // Validation
    @State private var showValidationAlert = false

    init(initialCategory: Category? = nil, initialSubcategory: Subcategory? = nil) {
        let initialCurrency = UserDefaults.standard.string(forKey: "globalDisplayCurrency") ?? Constants.Currency.usd.rawValue
        _selectedCurrency = State(initialValue: Constants.Currency(rawValue: initialCurrency) ?? .usd)
        
        _selectedCategory = State(initialValue: initialCategory)
        _selectedSubcategory = State(initialValue: initialSubcategory)
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
                    showPermissionAlert: $showPermissionAlert
                )
            }
            .navigationTitle("添加物品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveItem() }
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

        let item = Item(
            name: name,
            category: category,
            subcategory: selectedSubcategory,
            location: selectedLocation,
            sublocation: selectedSublocation,
            quantity: quantity,
            unit: unit,
            unitPrice: Double(unitPriceString),
            originalCurrency: selectedCurrency.rawValue,
            acquiredDate: showAcquiredDate ? (acquiredDate ?? Date()) : nil,
            expiryDate: showExpiryDate ? (expiryDate ?? Date()) : nil,
            shelfLifeDays: Int(shelfLifeDaysString),
            restockIntervalDays: Int(restockIntervalDaysString),
            imageFilename: imageFilename,
            notes: notes.isEmpty ? nil : notes,
            tags: tags
        )

        modelContext.insert(item)
        category.items.append(item)
        selectedSubcategory?.items.append(item)
        dismiss()
    }
}
