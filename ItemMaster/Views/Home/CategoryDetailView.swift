import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category
    @State private var isAddingSubcategory = false
    @State private var newSubcategoryName = ""

    var body: some View {
        List {
            if !category.subcategories.isEmpty {
                Section {
                    ForEach(category.subcategories) { subcategory in
                        NavigationLink(destination: SubcategoryItemsView(subcategory: subcategory)) {
                            HStack {
                                Text(subcategory.name)
                                Spacer()
                                Text("\(subcategory.items.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Inline add subcategory
            Section {
                if isAddingSubcategory {
                    TextField("二级分类名称", text: $newSubcategoryName)
                        .onSubmit {
                            saveNewSubcategory()
                        }
                } else {
                    Button {
                        isAddingSubcategory = true
                    } label: {
                        Label("添加二级分类", systemImage: "plus")
                            .foregroundStyle(.tint)
                    }
                }
            }

            Section {
                NavigationLink(destination: AllItemsInCategoryView(category: category)) {
                    Text("显示所有 \(category.name)")
                        .foregroundStyle(.tint)
                }
            }
        }
        .navigationTitle(category.name)
    }

    private func saveNewSubcategory() {
        let trimmed = newSubcategoryName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let subcategory = Subcategory(name: trimmed, parentCategory: category)
            modelContext.insert(subcategory)
            category.subcategories.append(subcategory)
        }
        newSubcategoryName = ""
        isAddingSubcategory = false
    }
}
