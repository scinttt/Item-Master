import SwiftUI

/// 一个辅助组件，用于在不同的 NavigationStack 中注入通用的跳转目的地
struct NavigationDestinationHelper: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Category.self) { category in
                CategoryDetailView(category: category)
            }
            .navigationDestination(for: Subcategory.self) { subcategory in
                SubcategoryItemsView(subcategory: subcategory)
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
    }
}

extension View {
    func withCommonDestinations() -> some View {
        self.modifier(NavigationDestinationHelper())
    }
}
