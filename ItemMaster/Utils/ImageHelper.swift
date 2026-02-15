import UIKit

enum ImageHelper {
    /// 将图片最大边缩放到指定大小，保持宽高比，并处理旋转方向
    static func resize(image: UIImage, maxSide: CGFloat = 1200) -> UIImage {
        let size = image.size
        
        let widthRatio  = maxSide / size.width
        let heightRatio = maxSide / size.height
        
        // 如果图片本身就很小，则不需要缩放
        if widthRatio >= 1 && heightRatio >= 1 {
            return image
        }
        
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // 使用 UIGraphicsImageRenderer 替代旧的 Context API，它会自动处理图片方向
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0 // 保持原始像素比，不进行额外的屏幕缩放
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    /// 按照规则压缩并保存图片到 Documents 目录，返回文件名
    static func compressAndSave(image: UIImage) -> String? {
        // 1. 缩放（包含方向修复）
        let resizedImage = resize(image: image, maxSide: 1200)
        
        // 2. 压缩并保存
        let filename = "\(UUID().uuidString).jpg"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory.appendingPathComponent(filename)
        
        // JPEG 质量 0.7
        guard let data = resizedImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        do {
            try data.write(to: url)
            return filename
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
}
