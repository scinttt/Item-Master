import Foundation
import SwiftData
import SwiftUI

@Observable
final class DashboardViewModel {
    @ObservationIgnored
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    
    @ObservationIgnored
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    
    var selectedSegment = 0
    
    /// 根据当前选中的统计维度（数量或总价）计算物品的贡献值
    func calculateValue(for item: Item) -> Double {
        if selectedSegment == 0 {
            return Double(item.quantity)
        } else {
            // 换算单价为全局显示币种
            let convertedPrice = CurrencyHelper.convert(item.unitPrice, from: item.originalCurrency, to: displayCurrency, rate: exchangeRate)
            return convertedPrice * Double(item.quantity)
        }
    }
    
    /// 格式化数值显示
    func formatValue(_ value: Double) -> String {
        if selectedSegment == 0 {
            return "\(Int(value))"
        } else {
            return CurrencyHelper.format(value, to: displayCurrency)
        }
    }
}
