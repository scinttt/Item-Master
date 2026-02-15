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
                    // 打印 Documents 文件夹的本地物理路径
                    print("📁 沙盒路径: \(URL.documentsDirectory.path())")
                }
        }
        .modelContainer(sharedModelContainer)
    }

    /// 首次启动时，检查数据库是否为空，若为空则写入默认分类和位置
    private func seedDefaultDataIfNeeded() {
        let context = sharedModelContainer.mainContext

        // 1. 基础分类与位置初始化 (如果表为空则注入)
        let categoryDescriptor = FetchDescriptor<Category>()
        let existingCategories = (try? context.fetch(categoryDescriptor)) ?? []
        
        if existingCategories.isEmpty {
            for name in Constants.defaultCategories {
                context.insert(Category(name: name, isDefault: true))
            }
        }

        let locationDescriptor = FetchDescriptor<Location>()
        let existingLocations = (try? context.fetch(locationDescriptor)) ?? []

        if existingLocations.isEmpty {
            for name in Constants.defaultLocations {
                context.insert(Location(name: name, isDefault: true))
            }
        }
        
        // 强制保存一次，确保后续能查到这些分类
        try? context.save()

        // 2. 注入测试示例物品 (仅在首次启动标记为 false 时执行)
        let sampleSeedKey = "didSeedSampleItems_v1"
        if !UserDefaults.standard.bool(forKey: sampleSeedKey) {
            seedSamples(context: context)
            UserDefaults.standard.set(true, forKey: sampleSeedKey)
            try? context.save()
        }
    }
    
    /// 注入具体的测试示例数据
    private func seedSamples(context: ModelContext) {
        // 获取刚创建的分类和位置
        let cats = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let locs = (try? context.fetch(FetchDescriptor<Location>())) ?? []
        
        guard let foodCat = cats.first(where: { $0.name == "食物" }),
              let techCat = cats.first(where: { $0.name == "电子产品" }),
              let dailyCat = cats.first(where: { $0.name == "日用品" }),
              let kitchenLoc = locs.first(where: { $0.name == "厨房" }),
              let studyLoc = locs.first(where: { $0.name == "书房" }) else { return }
        
        // 添加二级分类
        let snacks = Subcategory(name: "零食", parentCategory: foodCat)
        foodCat.subcategories.append(snacks)
        
        // 添加二级位置
        let fridge = Sublocation(name: "冰箱", parentLocation: kitchenLoc)
        kitchenLoc.sublocations.append(fridge)
        
        let calendar = Calendar.current
        
        // 示例 1: 临期食物
        context.insert(Item(
            name: "全脂鲜牛奶",
            category: foodCat,
            location: kitchenLoc,
            sublocation: fridge,
            quantity: 2.0,
            unit: "盒",
            unitPrice: 12.5,
            originalCurrency: "CNY",
            expiryDate: calendar.date(byAdding: .day, value: 3, to: Date()), // 3天后过期
            notes: "测试临期提醒"
        ))
        
        // 示例 2: 昂贵电子产品
        context.insert(Item(
            name: "iPhone 15 Pro",
            category: techCat,
            location: studyLoc,
            quantity: 1.0,
            unit: "台",
            unitPrice: 999.0,
            originalCurrency: "USD",
            acquiredDate: calendar.date(byAdding: .month, value: -3, to: Date()),
            notes: "测试美元换算和图表价值"
        ))
        
        // 示例 3: 低库存日用品
        context.insert(Item(
            name: "抽纸",
            category: dailyCat,
            location: studyLoc,
            quantity: 1.0,
            unit: "包",
            minQuantity: 5.0, // 触发补货
            unitPrice: 2.0,
            originalCurrency: "CNY"
        ))
    }
}
