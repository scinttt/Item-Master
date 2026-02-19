import Foundation

enum EnvHelper {
    static var openAIAPIKey: String {
        // 1. Check environment variable first (for CI/CD)
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            return key
        }
        
        // 2. Check Secrets.plist in bundle
        if let key = loadFromPlist()["OPENAI_API_KEY"], !key.isEmpty {
            return key
        }
        
        fatalError("""
        OPENAI_API_KEY not found.
        
        Setup instructions:
        1. Copy ItemMaster/Resources/Secrets.example.plist to Secrets.plist
        2. Replace YOUR_OPENAI_API_KEY_HERE with your actual API key
        3. Add Secrets.plist to Xcode project (Copy Bundle Resources)
        
        Or set OPENAI_API_KEY environment variable.
        """)
    }
    
    private static func loadFromPlist() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist") else {
            return [:]
        }
        
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] else {
            return [:]
        }
        
        return plist
    }
}
