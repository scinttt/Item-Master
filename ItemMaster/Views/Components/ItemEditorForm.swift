import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

// MARK: - Sub-components to isolate state and improve performance

struct ImageSectionView: View {
    @Binding var selectedImage: UIImage?
    @Binding var photosPickerItem: PhotosPickerItem?
    var onCheckCamera: () -> Void
    
    var body: some View {
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
                    onCheckCamera()
                } label: {
                    Label("拍照", systemImage: "camera")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TagSectionView: View {
    @Binding var tagNames: [String]
    @Binding var tagInput: String
    @FocusState.Binding var isInputActive: Bool
    
    var body: some View {
        Section("标签") {
            if !tagNames.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tagNames, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.subheadline)
                            Button {
                                withAnimation {
                                    tagNames.removeAll { $0 == tag }
                                }
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
            }

            HStack {
                TextField("输入标签", text: $tagInput)
                    .onSubmit { addTag() }
                    .focused($isInputActive)
                
                Button("添加") {
                    addTag()
                }
                .buttonStyle(.borderless)
                .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tagNames.contains(trimmed) {
            withAnimation {
                tagNames.append(trimmed)
            }
        }
        tagInput = ""
    }
}

// MARK: - Main Form

struct ItemEditorForm: View {
    @Query(sort: \Location.name) private var locations: [Location]

    // MARK: - Bindings
    @Binding var name: String
    @Binding var quantity: Double
    @Binding var unit: String
    @Binding var unitPriceString: String
    @Binding var selectedCurrency: Constants.Currency
    
    @Binding var selectedCategory: Category?
    @Binding var selectedSubcategory: Subcategory?
    
    @Binding var selectedLocation: Location?
    @Binding var selectedSublocation: Sublocation?
    
    @Binding var showAcquiredDate: Bool
    @Binding var acquiredDate: Date?
    @Binding var showExpiryDate: Bool
    @Binding var expiryDate: Date?
    @Binding var shelfLifeDaysString: String
    @Binding var restockIntervalDaysString: String
    
    @Binding var tagNames: [String]
    @Binding var tagInput: String
    @Binding var notes: String
    
    @Binding var selectedImage: UIImage?
    @Binding var photosPickerItem: PhotosPickerItem?
    @Binding var showCamera: Bool
    @Binding var showPermissionAlert: Bool
    
    // Calculator State
    @Binding var showCalculator: Bool
    
    // Focus State
    @FocusState.Binding var isInputActive: Bool
    
    // State for selection sheets
    @State private var showCategorySelection = false
    @State private var showSubcategorySelection = false

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

    var body: some View {
        Group {
            ImageSectionView(
                selectedImage: $selectedImage,
                photosPickerItem: $photosPickerItem,
                onCheckCamera: checkCameraPermission
            )
            
            basicInfoSection
            categorySection
            locationSection
            dateSection
            restockSection
            
            TagSectionView(
                tagNames: $tagNames,
                tagInput: $tagInput,
                isInputActive: $isInputActive
            )
            
            notesSection
        }
    }

    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section("基本信息") {
            TextField("名称（留空自动生成）", text: $name)
                .focused($isInputActive)

            HStack {
                Text("数量")
                Spacer()
                TextField("", value: $quantity, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .focused($isInputActive)
                Stepper("", value: $quantity, in: 0...9999, step: 1)
                    .labelsHidden()
            }

            VStack(spacing: 0) {
                HStack {
                    Text("单价")
                    Spacer()
                    PriceCalculatorField(text: $unitPriceString, isCalculatorPresented: $showCalculator)
                    
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
    }

    // MARK: - Category Section
    private var categorySection: some View {
        Section("分类（必填）") {
            Button {
                showCategorySelection = true
            } label: {
                HStack {
                    Text("一级分类")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(selectedCategory?.name ?? "请选择")
                        .foregroundStyle(selectedCategory == nil ? .secondary : .primary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .sheet(isPresented: $showCategorySelection) {
                NavigationStack {
                    CategorySelectionView(selectedCategory: $selectedCategory)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("关闭") { showCategorySelection = false }
                            }
                        }
                }
            }

            if let category = selectedCategory {
                Button {
                    showSubcategorySelection = true
                } label: {
                    HStack {
                        Text("二级分类")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedSubcategory?.name ?? "可选")
                            .foregroundStyle(selectedSubcategory == nil ? .secondary : .primary)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .sheet(isPresented: $showSubcategorySelection) {
                    NavigationStack {
                        SubcategorySelectionView(
                            category: category,
                            selectedSubcategory: $selectedSubcategory
                        )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("关闭") { showSubcategorySelection = false }
                            }
                        }
                    }
                }
            }
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

    // MARK: - Notes Section
    private var notesSection: some View {
        Section("备注") {
            TextField("备注信息", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .focused($isInputActive)
        }
    }
}
