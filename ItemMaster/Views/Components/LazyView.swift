import SwiftUI

/// 一个简单的包装器，用于延迟实例化目标视图
/// 只有当 NavigationLink 被点击且视图显示时，才会初始化内部的视图
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}
