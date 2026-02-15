import SwiftUI
import SwiftData

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
