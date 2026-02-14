import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: Item

    var body: some View {
        Form {
            Section("基本信息") {
                LabeledContent("名称", value: item.name)
                LabeledContent("数量", value: "\(item.quantity)")
            }
        }
        .navigationTitle(item.name)
    }
}
