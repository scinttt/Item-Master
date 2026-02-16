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
            title: "\(category.name) - 全部物品",
            initialCategory: category,
            initialSubcategory: nil
        )
    }
}

/// 用于导航的包装器
struct CategoryItemsWrapper: Hashable {
    let category: Category
}
