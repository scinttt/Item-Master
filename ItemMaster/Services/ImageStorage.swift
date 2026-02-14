import UIKit

enum ImageStorage {
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 保存图片到 Documents 目录，返回文件名
    static func save(_ image: UIImage) -> String? {
        let filename = "\(UUID().uuidString).jpg"
        let url = documentsDirectory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    /// 从 Documents 目录加载图片
    static func load(filename: String) -> UIImage? {
        let url = documentsDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// 删除 Documents 目录中的图片文件
    static func delete(filename: String) {
        let url = documentsDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
