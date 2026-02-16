import SwiftUI
import SwiftData

struct UncategorizedItemsView: View {
    let category: Category
    
    private var filter: Predicate<Item> {
        let categoryID = category.id
        return #Predicate<Item> { item in
            item.category.id == categoryID && item.subcategory == nil
        }
    }

    var body: some View {
        ItemSortableListView(
            filter: filter,
            title: "未分类物品",
            initialCategory: category,
            initialSubcategory: nil
        )
    }
}
