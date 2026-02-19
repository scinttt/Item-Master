import SwiftUI
import Foundation
import UIKit

// MARK: - ParsedReceipt Model
struct ParsedReceipt: Codable {
    let name: String?
    let unitPriceString: String?
    let quantity: Double?
    let matchedCategoryName: String?
    let matchedSubcategoryName: String?
    var tagNames: [String]?
    let notes: String?
    let acquiredDateString: String? // Format: YYYY-MM-DD
    let brand: String?
}

// MARK: - ReceiptScannerService
final class ReceiptScannerService {
    static let shared = ReceiptScannerService()
    
    private init() {}
    
    /// Main entry point to parse a receipt image
    /// - Parameters:
    ///   - image: The image to scan
    ///   - categoryContext: A string describing the existing category structure for the AI to match against.
    func parseReceipt(image: UIImage, categoryContext: String) async throws -> [ParsedReceipt] {
        // 1. Prepare Image
        guard let jpegData = image.jpegData(compressionQuality: 0.6) else {
            throw ReceiptScannerError.imageProcessingFailed
        }
        let base64Image = jpegData.base64EncodedString()
        
        // 2. Prepare Prompt
        let systemPrompt = """
        你是一个专业的账单解析专家。请分析图片中包含的**所有**独立商品。
        请严格输出一个 JSON 对象，包含一个名为 `items` 的数组。数组中每个元素代表一个商品。
        如果只发现一个商品，也请放入数组中。
        
        每个商品对象的 key 必须是：name, brand, unitPriceString, quantity, matchedCategoryName, matchedSubcategoryName, tagNames, notes, acquiredDateString。
        
        解析规则：
        1. **名称 (name)**: 请提取完整的商品名称。不包含品牌。
        2. **品牌 (brand)**: 请分析商品名称或图片可视信息，提取品牌名称（如 Nike, Apple, Lululemon 等）。如果无法确定，返回 null。
        3. **日期 (acquiredDateString)**: 提取订单日期或送达日期，格式严格为 YYYY-MM-DD。如果图片中只显示一个总日期，则所有商品使用该日期。
        4. **来源/平台**: 如果图片包含明显的电商平台名称（如 eBay, Amazon, Taobao, Temu），请将其添加到 `tagNames` 数组中。
        5. **分类匹配**: 参考以下现有的分类树：[\(categoryContext)]。请尽量从这些已有分类中挑选最合适的填入 matchedCategoryName 和 matchedSubcategoryName。如果没有合适的，严格返回 null。
        6. **金额**: 提取纯数字字符串（单价）。
        7. **数量**: 提取为数字。
        """
        
        // 4. Build Request Payload
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "response_format": ["type": "json_object"],
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_completion_tokens": 1500
        ]
        
        // 5. Build URL Request
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ReceiptScannerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(EnvHelper.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // 6. Execute Request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Try to read error message if possible
            if let errorText = String(data: data, encoding: .utf8) {
                print("OpenAI API Error: \(errorText)")
            }
            throw ReceiptScannerError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        // 7. Decode Response
        // Define internal structures for decoding OpenAI's format
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        // Wrapper for the items array
        struct ParsedReceiptsWrapper: Decodable {
            let items: [ParsedReceipt]
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = openAIResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw ReceiptScannerError.invalidResponseFormat
        }
        
        let wrapper = try JSONDecoder().decode(ParsedReceiptsWrapper.self, from: contentData)
        
        var finalItems: [ParsedReceipt] = []
        for var item in wrapper.items {
            // Post-processing: Add extracted brand to tags if present
            if let brand = item.brand, !brand.isEmpty {
                var tags = item.tagNames ?? []
                // Avoid duplicates
                if !tags.contains(where: { $0.caseInsensitiveCompare(brand) == .orderedSame }) {
                    tags.append(brand)
                }
                item.tagNames = tags
            }
            finalItems.append(item)
        }
        
        return finalItems
    }
}

enum ReceiptScannerError: Error, LocalizedError {
    case imageProcessingFailed
    case invalidURL
    case apiError(statusCode: Int)
    case invalidResponseFormat
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: return "无法处理图片"
        case .invalidURL: return "无效的 API URL"
        case .apiError(let code): return "API 请求失败，错误码: \(code)"
        case .invalidResponseFormat: return "无法解析服务器返回的数据"
        }
    }
}
