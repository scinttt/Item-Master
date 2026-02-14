import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("分类", systemImage: "square.grid.2x2")
                }

            DashboardView()
                .tabItem {
                    Label("统计", systemImage: "chart.pie")
                }
        }
    }
}
