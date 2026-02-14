import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    var searchText = ""
    var selectedSortOption: Constants.SortOption = .expiryDate
}
