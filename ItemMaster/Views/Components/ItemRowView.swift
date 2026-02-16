import SwiftUI

struct ItemRowView: View {
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ItemImageView(filename: item.imageFilename)
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))

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

            VStack(alignment: .trailing, spacing: 4) {
                Text("×\(QuantityHelper.format(item.quantity))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let price = item.unitPrice {
                    let convertedPrice = CurrencyHelper.convert(price, from: item.originalCurrency, to: displayCurrency, rate: exchangeRate)
                    Text(CurrencyHelper.format(convertedPrice, to: displayCurrency))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
