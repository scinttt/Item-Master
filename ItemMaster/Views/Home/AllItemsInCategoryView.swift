import SwiftUI
import SwiftData

struct AllItemsInCategoryView: View {
    @Query private var items: [Item]
    let category: Category
    
    init(category: Category) {
        self.category = category
        let categoryID = category.id
        _items = Query(filter: #Predicate<Item> { item in
            item.category.id == categoryID
        })
    }

    var body: some View {
        ItemSortableListView(
            items: items,
            title: "所有 \(category.name)",
            initialCategory: category,
            initialSubcategory: nil
        )
    }
}
