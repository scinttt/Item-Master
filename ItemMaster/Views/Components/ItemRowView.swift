import SwiftUI

struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .lineLimit(1)

                if let expiryDate = item.expiryDate {
                    Text("过期: \(expiryDate, format: .dateTime.year().month().day())")
                        .font(.caption)
                        .foregroundStyle(item.isExpired ? .red : item.isExpiringSoon ? .orange : .secondary)
                }
            }

            Spacer()

            Text("×\(item.quantity)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
