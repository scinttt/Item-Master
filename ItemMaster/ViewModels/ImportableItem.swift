import SwiftUI
import SwiftData

@Observable
class ImportableItem: Identifiable {
    let id = UUID()
    var isSelected: Bool = true
    
    // Form properties (matching AddItemView fields)
    var name: String = ""
    var unitPriceString: String = ""
    var quantity: Double = 1.0
    var unit: String = "个"
    var selectedCategory: Category?
    var selectedSubcategory: Subcategory?
    var notes: String = ""
    var tagNames: [String] = []
    var tagInput: String = ""
    
    // Extra fields if needed for display
    var brand: String?
    
    // Dates
    var acquiredDate: Date?
    var showAcquiredDate: Bool = false
    
    // UI State
    var isExpanded: Bool = false
    
    init(raw: ParsedReceipt, contextCategories: [Category]) {
        // 1. Basic Fields
        if let rawName = raw.name, !rawName.isEmpty {
            self.name = rawName
        }
        
        if let rawPrice = raw.unitPriceString {
            self.unitPriceString = rawPrice
        }
        
        if let rawQty = raw.quantity {
            self.quantity = rawQty
        }
        
        if let rawTags = raw.tagNames {
            self.tagNames = rawTags
        }
        
        if let rawNotes = raw.notes {
            self.notes = rawNotes
        }
        
        self.brand = raw.brand
        
        // 2. Date Parsing
        if let dateString = raw.acquiredDateString {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                self.acquiredDate = date
                self.showAcquiredDate = true
            }
        }
        
        // 3. Category Matching
        if let catName = raw.matchedCategoryName {
            if let match = contextCategories.first(where: { $0.name == catName }) {
                self.selectedCategory = match
                
                if let subName = raw.matchedSubcategoryName {
                    self.selectedSubcategory = match.subcategories.first(where: { $0.name == subName })
                }
            }
        }
    }
}

// Wrapper class to make the items array observable
@Observable
class ImportableItems {
    var items: [ImportableItem]
    
    init(items: [ImportableItem]) {
        self.items = items
    }
}
