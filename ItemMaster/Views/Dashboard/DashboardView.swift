import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack {
                Picker("图表类型", selection: $selectedSegment) {
                    Text("物品总数").tag(0)
                    Text("物品总价").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                Text("图表占位")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("图表")
        }
    }
}
