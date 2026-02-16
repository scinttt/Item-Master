import SwiftUI

/// 一个辅助组件，用于在不同的 NavigationStack 中注入通用的跳转目的地
struct NavigationDestinationHelper: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Category.self) { category in
                // 默认跳转到二级统计页，初始维度设为 0 (数量)
                SubcategoryDashboardView(category: category, initialSegment: 0)
            }
            .navigationDestination(for: Subcategory.self) { subcategory in
                SubcategoryItemsView(subcategory: subcategory)
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .navigationDestination(for: UncategorizedItemsWrapper.self) { wrapper in
                UncategorizedItemsView(category: wrapper.category)
            }
    }
}

extension View {
    func withCommonDestinations() -> some View {
        self.modifier(NavigationDestinationHelper())
    }
}
