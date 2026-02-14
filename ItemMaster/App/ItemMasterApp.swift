import SwiftUI
import SwiftData

@main
struct ItemMasterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Category.self,
            Subcategory.self,
            Location.self,
            Sublocation.self,
            Tag.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    seedDefaultDataIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    /// 首次启动时，检查数据库是否为空，若为空则写入默认分类和位置
    private func seedDefaultDataIfNeeded() {
        let context = sharedModelContainer.mainContext

        // 检查是否已有分类数据
        let categoryDescriptor = FetchDescriptor<Category>()
        let existingCategories = (try? context.fetchCount(categoryDescriptor)) ?? 0

        if existingCategories == 0 {
            for name in Constants.defaultCategories {
                let category = Category(name: name, isDefault: true)
                context.insert(category)
            }
        }

        // 检查是否已有位置数据
        let locationDescriptor = FetchDescriptor<Location>()
        let existingLocations = (try? context.fetchCount(locationDescriptor)) ?? 0

        if existingLocations == 0 {
            for name in Constants.defaultLocations {
                let location = Location(name: name, isDefault: true)
                context.insert(location)
            }
        }

        try? context.save()
    }
}
