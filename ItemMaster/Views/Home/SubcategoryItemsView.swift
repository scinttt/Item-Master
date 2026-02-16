import SwiftUI
import SwiftData

struct SubcategoryItemsView: View {
    let subcategory: Subcategory
    
    private var filter: Predicate<Item> {
        let subcategoryID = subcategory.id
        return #Predicate<Item> { item in
            item.subcategory?.id == subcategoryID
        }
    }

    var body: some View {
        ItemSortableListView(
            filter: filter,
            title: subcategory.name,
            initialCategory: subcategory.parentCategory,
            initialSubcategory: subcategory
        )
    }
}
