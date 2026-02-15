import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Location.name) private var locations: [Location]

    // MARK: - Form State
    @State private var name = ""
    @State private var quantity = 1
    @State private var unitPriceString = ""
    @State private var selectedCurrency: Constants.Currency = .usd
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

    var body: some View {
        NavigationStack {
            Form {
                imageSection
                basicInfoSection
                categorySection
                locationSection
                dateSection
                restockSection
                tagSection
                notesSection
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
        }
    }

    // MARK: - Image Section
    private var imageSection: some View {
        Section("图片") {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("移除图片", role: .destructive) {
                    self.selectedImage = nil
                    self.photosPickerItem = nil
                }
            }

            HStack {
                PhotosPicker(selection: $photosPickerItem, matching: .images, photoLibrary: .shared()) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    checkCameraPermission()
                } label: {
                    Label("拍照", systemImage: "camera")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section("基本信息") {
            TextField("名称（留空自动生成）", text: $name)

            Stepper("数量: \(quantity)", value: $quantity, in: 0...9999)

            HStack {
                Text("单价")
                Spacer()
                TextField("可选", text: $unitPriceString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                
                Picker("币种", selection: $selectedCurrency) {
                    ForEach(Constants.Currency.allCases, id: \.self) { currency in
                        Text(currency.rawValue).tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }

    // MARK: - Category Section
    private var categorySection: some View {
        Section("分类（必填）") {
            NavigationLink {
                CategorySelectionView(selectedCategory: $selectedCategory)
            } label: {
                HStack {
                    Text("一级分类")
                    Spacer()
                    Text(selectedCategory?.name ?? "请选择")
                        .foregroundStyle(selectedCategory == nil ? .secondary : .primary)
                }
            }

            if let category = selectedCategory {
                NavigationLink {
                    SubcategorySelectionView(
                        category: category,
                        selectedSubcategory: $selectedSubcategory
                    )
                } label: {
                    HStack {
                        Text("二级分类")
                        Spacer()
                        Text(selectedSubcategory?.name ?? "可选")
                            .foregroundStyle(selectedSubcategory == nil ? .secondary : .primary)
                    }
                }
            }
        }
        .onChange(of: selectedCategory) {
            selectedSubcategory = nil
        }
    }

    // MARK: - Location Section
    private var locationSection: some View {
        Section("位置（可选）") {
            Picker("一级位置", selection: $selectedLocation) {
                Text("无").tag(nil as Location?)
                ForEach(locations) { location in
                    Text(location.name).tag(location as Location?)
                }
            }
            .onChange(of: selectedLocation) {
                selectedSublocation = nil
            }

            if let location = selectedLocation, !location.sublocations.isEmpty {
                Picker("二级位置", selection: $selectedSublocation) {
                    Text("无").tag(nil as Sublocation?)
                    ForEach(location.sublocations) { sub in
                        Text(sub.name).tag(sub as Sublocation?)
                    }
                }
            }
        }
    }

    // MARK: - Date Section
    private var dateSection: some View {
        Section("日期") {
            Toggle("获取时间", isOn: $showAcquiredDate)
            if showAcquiredDate {
                DatePicker("获取时间",
                           selection: Binding(
                               get: { acquiredDate ?? Date() },
                               set: { acquiredDate = $0 }
                           ),
                           displayedComponents: .date)
            }

            Toggle("过期时间", isOn: $showExpiryDate)
            if showExpiryDate {
                DatePicker("过期时间",
                           selection: Binding(
                               get: { expiryDate ?? Date() },
                               set: { expiryDate = $0 }
                           ),
                           displayedComponents: .date)
            }

            HStack {
                Text("保质期（天）")
                Spacer()
                TextField("可选", text: $shelfLifeDaysString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }

    // MARK: - Restock Section
    private var restockSection: some View {
        Section("补货") {
            HStack {
                Text("补货频率（天）")
                Spacer()
                TextField("可选", text: $restockIntervalDaysString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }

    // MARK: - Tag Section
    private var tagSection: some View {
        Section("标签") {
            FlowLayout(spacing: 8) {
                ForEach(tagNames, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.subheadline)
                        Button {
                            tagNames.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.fill.tertiary)
                    .clipShape(Capsule())
                }
            }

            HStack {
                TextField("输入标签", text: $tagInput)
                    .onSubmit { addTag() }
                Button("添加") { addTag() }
                    .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        Section("备注") {
            TextField("备注信息", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Actions

    private func checkCameraPermission() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCamera = true
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            showCamera = true
        case .authorized:
            showCamera = true
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
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

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tagNames.contains(trimmed) {
            tagNames.append(trimmed)
        }
        tagInput = ""
    }

    private func saveItem() {
        guard let category = selectedCategory else {
            showValidationAlert = true
            return
        }

        // Save image
        var imageFilename: String?
        if let image = selectedImage {
            imageFilename = ImageHelper.compressAndSave(image: image)
        }

        // Resolve or create tags
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

// MARK: - Category Selection View
struct CategorySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]
    @Binding var selectedCategory: Category?

    @State private var isAdding = false
    @State private var newName = ""

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    selectedCategory = category
                    dismiss()
                } label: {
                    HStack {
                        Text(category.name)
                        Spacer()
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }

            if isAdding {
                HStack {
                    TextField("新分类名称", text: $newName)
                        .onSubmit { saveNew() }
                    Button("取消") {
                        newName = ""
                        isAdding = false
                    }
                    .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    isAdding = true
                } label: {
                    Label("添加分类", systemImage: "plus")
                        .foregroundStyle(.tint)
                }
            }
        }
        .navigationTitle("选择一级分类")
    }

    private func saveNew() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let category = Category(name: trimmed)
            modelContext.insert(category)
            selectedCategory = category
            dismiss()
        }
        newName = ""
        isAdding = false
    }
}

// MARK: - Subcategory Selection View
struct SubcategorySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let category: Category
    @Binding var selectedSubcategory: Subcategory?

    @State private var isAdding = false
    @State private var newName = ""

    var body: some View {
        List {
            ForEach(category.subcategories) { subcategory in
                Button {
                    selectedSubcategory = subcategory
                    dismiss()
                } label: {
                    HStack {
                        Text(subcategory.name)
                        Spacer()
                        if selectedSubcategory?.id == subcategory.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }

            if isAdding {
                HStack {
                    TextField("新二级分类名称", text: $newName)
                        .onSubmit { saveNew() }
                    Button("取消") {
                        newName = ""
                        isAdding = false
                    }
                    .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    isAdding = true
                } label: {
                    Label("添加二级分类", systemImage: "plus")
                        .foregroundStyle(.tint)
                }
            }
        }
        .navigationTitle("选择二级分类")
    }

    private func saveNew() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let subcategory = Subcategory(name: trimmed, parentCategory: category)
            modelContext.insert(subcategory)
            category.subcategories.append(subcategory)
            selectedSubcategory = subcategory
            dismiss()
        }
        newName = ""
        isAdding = false
    }
}
