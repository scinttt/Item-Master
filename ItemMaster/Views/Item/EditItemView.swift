import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct EditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Location.name) private var locations: [Location]
    
    let item: Item
    
    // MARK: - Form State
    @State private var name: String
    @State private var quantity: Int
    @State private var unitPriceString: String
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
    @State private var currentImageFilename: String?
    @State private var imageDeleted = false
    
    // Date toggles
    @State private var showAcquiredDate: Bool
    @State private var showExpiryDate: Bool
    
    // Validation
    @State private var showValidationAlert = false
    
    init(item: Item) {
        self.item = item
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity)
        _unitPriceString = State(initialValue: item.unitPrice.map { "\($0)" } ?? "")
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
        
        _currentImageFilename = State(initialValue: item.imageFilename)
        _showAcquiredDate = State(initialValue: item.acquiredDate != nil)
        _showExpiryDate = State(initialValue: item.expiryDate != nil)
        
        // Load initial image if exists
        if let filename = item.imageFilename {
            _selectedImage = State(initialValue: ImageStorage.load(filename: filename))
        }
    }
    
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
            .navigationTitle("编辑物品")
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
                    imageDeleted = false
                }
            }
            .onChange(of: photosPickerItem) {
                loadPhoto()
            }
        }
    }
    
    // MARK: - Sections
    
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
                    self.imageDeleted = true
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
    
    private var basicInfoSection: some View {
        Section("基本信息") {
            TextField("名称", text: $name)
            
            Stepper("数量: \(quantity)", value: $quantity, in: 0...9999)
            
            HStack {
                Text("单价")
                Spacer()
                TextField("可选", text: $unitPriceString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }
    
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
            if selectedCategory?.id != item.category.id {
                selectedSubcategory = nil
            }
        }
    }
    
    private var locationSection: some View {
        Section("位置（可选）") {
            Picker("一级位置", selection: $selectedLocation) {
                Text("无").tag(nil as Location?)
                ForEach(locations) { location in
                    Text(location.name).tag(location as Location?)
                }
            }
            .onChange(of: selectedLocation) {
                if selectedLocation?.id != item.location?.id {
                    selectedSublocation = nil
                }
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
                imageDeleted = false
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
        
        // Handle image
        var finalImageFilename = item.imageFilename
        
        if imageDeleted {
            if let oldFilename = item.imageFilename {
                ImageStorage.delete(filename: oldFilename)
            }
            finalImageFilename = nil
        }
        
        if let newImage = selectedImage, newImage != ImageStorage.load(filename: item.imageFilename ?? "") {
            // If there's a new image (different from current one)
            if let oldFilename = item.imageFilename {
                ImageStorage.delete(filename: oldFilename)
            }
            finalImageFilename = ImageHelper.compressAndSave(image: newImage)
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
        
        // Update item fields
        item.name = name.isEmpty ? item.id.uuidString : name
        item.category = category
        item.subcategory = selectedSubcategory
        item.location = selectedLocation
        item.sublocation = selectedSublocation
        item.quantity = quantity
        item.unitPrice = Double(unitPriceString)
        item.acquiredDate = showAcquiredDate ? (acquiredDate ?? Date()) : nil
        item.expiryDate = showExpiryDate ? (expiryDate ?? Date()) : nil
        item.shelfLifeDays = Int(shelfLifeDaysString)
        item.restockIntervalDays = Int(restockIntervalDaysString)
        item.imageFilename = finalImageFilename
        item.notes = notes.isEmpty ? nil : notes
        item.tags = tags
        item.updatedAt = Date()
        
        dismiss()
    }
}
