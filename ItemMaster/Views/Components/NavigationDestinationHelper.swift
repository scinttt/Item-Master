import SwiftUI

/// 一个辅助组件，用于在不同的 NavigationStack 中注入通用的跳转目的地
/// 目前已将路由逻辑上收到 DashboardView 等顶层 View，此处保留为空以待将来扩展或移除。
struct NavigationDestinationHelper: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func withCommonDestinations() -> some View {
        self.modifier(NavigationDestinationHelper())
    }
}
