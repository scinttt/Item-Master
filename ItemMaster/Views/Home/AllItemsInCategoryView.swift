import SwiftUI
import SwiftData

struct AllItemsInCategoryView: View {
    let category: Category
    
    private var filter: Predicate<Item> {
        let categoryID = category.id
        return #Predicate<Item> { item in
            item.category.id == categoryID
        }
    }

    var body: some View {
        ItemSortableListView(
            filter: filter,
            title: "所有 \(category.name)",
            initialCategory: category,
            initialSubcategory: nil
        )
    }
}
