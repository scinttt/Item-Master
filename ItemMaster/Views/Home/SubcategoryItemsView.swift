import SwiftUI
import SwiftData

struct SubcategoryItemsView: View {
    @Query private var items: [Item]
    let subcategory: Subcategory
    
    init(subcategory: Subcategory) {
        self.subcategory = subcategory
        let subcategoryID = subcategory.id
        _items = Query(filter: #Predicate<Item> { item in
            item.subcategory?.id == subcategoryID
        })
    }

    var body: some View {
        ItemSortableListView(
            items: items,
            title: subcategory.name,
            initialCategory: subcategory.parentCategory,
            initialSubcategory: subcategory
        )
    }
}
