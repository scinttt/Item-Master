import SwiftUI
import SwiftData

struct EditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let item: Item

    var body: some View {
        Form {
            Text("编辑物品: \(item.name)")
        }
        .navigationTitle("编辑物品")
    }
}
