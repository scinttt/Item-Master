import UIKit

enum ImageHelper {
    /// 将图片最大边缩放到指定大小，保持宽高比
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
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    /// 按照规则压缩并保存图片到 Documents 目录，返回文件名
    static func compressAndSave(image: UIImage) -> String? {
        // 1. 缩放
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
