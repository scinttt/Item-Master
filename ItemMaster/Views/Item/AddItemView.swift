import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Location.name) private var locations: [Location]

    // MARK: - Form State
    @State private var name = ""
    @State private var quantity = 1
    @State private var unitPriceString = ""
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

    // Inline creation
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var isAddingSubcategory = false
    @State private var newSubcategoryName = ""

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
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                }

                Spacer()

                Button {
                    showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera")
                }
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
                    .frame(width: 120)
            }
        }
    }

    // MARK: - Category Section
    private var categorySection: some View {
        Section("分类（必填）") {
            // 一级分类
            Picker("一级分类", selection: $selectedCategory) {
                Text("请选择").tag(nil as Category?)
                ForEach(categories) { category in
                    Text(category.name).tag(category as Category?)
                }
            }
            .onChange(of: selectedCategory) {
                selectedSubcategory = nil
            }

            // Inline add category
            if isAddingCategory {
                HStack {
                    TextField("新分类名称", text: $newCategoryName)
                        .onSubmit { saveNewCategory() }
                    Button("取消") {
                        newCategoryName = ""
                        isAddingCategory = false
                    }
                    .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    isAddingCategory = true
                } label: {
                    Label("添加分类", systemImage: "plus")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
            }

            // 二级分类
            if let category = selectedCategory, !category.subcategories.isEmpty {
                Picker("二级分类", selection: $selectedSubcategory) {
                    Text("无").tag(nil as Subcategory?)
                    ForEach(category.subcategories) { sub in
                        Text(sub.name).tag(sub as Subcategory?)
                    }
                }
            }

            // Inline add subcategory (only when a category is selected)
            if selectedCategory != nil {
                if isAddingSubcategory {
                    HStack {
                        TextField("新二级分类名称", text: $newSubcategoryName)
                            .onSubmit { saveNewSubcategory() }
                        Button("取消") {
                            newSubcategoryName = ""
                            isAddingSubcategory = false
                        }
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        isAddingSubcategory = true
                    } label: {
                        Label("添加二级分类", systemImage: "plus")
                            .font(.subheadline)
                            .foregroundStyle(.tint)
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

    private func saveNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let category = Category(name: trimmed)
            modelContext.insert(category)
            selectedCategory = category
        }
        newCategoryName = ""
        isAddingCategory = false
    }

    private func saveNewSubcategory() {
        let trimmed = newSubcategoryName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, let parent = selectedCategory {
            let subcategory = Subcategory(name: trimmed, parentCategory: parent)
            modelContext.insert(subcategory)
            parent.subcategories.append(subcategory)
            selectedSubcategory = subcategory
        }
        newSubcategoryName = ""
        isAddingSubcategory = false
    }

    private func saveItem() {
        guard let category = selectedCategory else {
            showValidationAlert = true
            return
        }

        // Save image
        var imageFilename: String?
        if let image = selectedImage {
            imageFilename = ImageStorage.save(image)
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

// MARK: - FlowLayout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews)
        -> (positions: [CGPoint], sizes: [CGSize], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, sizes, CGSize(width: maxX, height: y + rowHeight))
    }
}
