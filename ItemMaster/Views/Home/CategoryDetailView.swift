import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: Category

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

            Section {
                NavigationLink(destination: AllItemsInCategoryView(category: category)) {
                    Text("显示所有 \(category.name)")
                        .foregroundStyle(.tint)
                }
            }
        }
        .navigationTitle(category.name)
    }
}
