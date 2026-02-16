import SwiftUI

struct ItemImageView: View {
    let filename: String?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var currentTask: Task<Void, Never>?
    
    private static let cache = NSCache<NSString, UIImage>()
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ZStack {
                    Color.gray.opacity(0.05)
                    ProgressView()
                        .controlSize(.small)
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            // 视图消失时取消未完成的任务，防止后台任务堆积
            currentTask?.cancel()
        }
        .onChange(of: filename) { _, _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let filename = filename, !filename.isEmpty else {
            self.image = nil
            return
        }
        
        if let cachedImage = Self.cache.object(forKey: filename as NSString) {
            self.image = cachedImage
            return
        }
        
        currentTask?.cancel()
        isLoading = true
        
        currentTask = Task(priority: .medium) {
            // 模拟微小的延迟，避免在快速滚动时触发密集的磁盘读取
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            if Task.isCancelled { return }
            
            if let loadedImage = ImageStorage.load(filename: filename) {
                Self.cache.setObject(loadedImage, forKey: filename as NSString)
                if !Task.isCancelled {
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                }
            } else {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
