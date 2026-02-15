import Foundation

struct QuantityHelper {
    /// 格式化数量显示
    /// 最多显示两位小数，如果是整数则不显示小数点和后面的0
    static func format(_ quantity: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        // 确保不会出现千分位分隔符（根据需求，通常数量不需要千分位，但如果需要可以移除下一行）
        formatter.usesGroupingSeparator = false 
        
        return formatter.string(from: NSNumber(value: quantity)) ?? "\(quantity)"
    }
}
