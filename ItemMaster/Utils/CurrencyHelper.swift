import Foundation

struct CurrencyHelper {
    /// 换算金额
    /// - Parameters:
    ///   - amount: 原始金额
    ///   - fromCurrency: 原始币种 (USD/CNY)
    ///   - toCurrency: 目标币种 (USD/CNY)
    ///   - rate: 汇率 (1 USD = ? CNY)，如果不传则使用 Constants 中的默认值
    /// - Returns: 换算后的金额
    static func convert(_ amount: Double?, from fromCurrency: String, to toCurrency: String, rate: Double? = nil) -> Double {
        guard let amount = amount else { return 0.0 }
        if fromCurrency == toCurrency { return amount }
        
        let currentRate = rate ?? Constants.usdToCnyRate
        
        if fromCurrency == Constants.Currency.usd.rawValue && toCurrency == Constants.Currency.cny.rawValue {
            return amount * currentRate
        } else if fromCurrency == Constants.Currency.cny.rawValue && toCurrency == Constants.Currency.usd.rawValue {
            return amount / currentRate
        }
        
        return amount
    }
    
    /// 格式化金额字符串
    /// - Parameters:
    ///   - amount: 金额
    ///   - currencyCode: 币种代码 (USD/CNY)
    /// - Returns: 格式化后的字符串，如 "$100.00" 或 "¥700.00"
    static func format(_ amount: Double, to currencyCode: String) -> String {
        let symbol = Constants.Currency(rawValue: currencyCode)?.symbol ?? "$"
        return String(format: "%@%.2f", symbol, amount)
    }
}
