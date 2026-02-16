import SwiftUI
import SwiftData

struct UncategorizedItemsView: View {
    @Query private var items: [Item]
    let category: Category
    
    init(category: Category) {
        self.category = category
        let categoryID = category.id
        // 过滤逻辑：属于该一级分类，且 subcategory 为 nil
        _items = Query(filter: #Predicate<Item> { item in
            item.category.id == categoryID && item.subcategory == nil
        })
    }

    var body: some View {
        ItemSortableListView(
            items: items,
            title: "未分类物品",
            initialCategory: category,
            initialSubcategory: nil
        )
    }
}
