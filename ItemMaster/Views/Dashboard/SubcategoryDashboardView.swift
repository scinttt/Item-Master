import SwiftUI
import SwiftData
import Charts

struct SubcategoryDashboardView: View {
    let category: Category
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @Query private var items: [Item]
    @State private var viewModel: DashboardViewModel

    init(category: Category, initialSegment: Int) {
        self.category = category
        let categoryID = category.id
        _items = Query(filter: #Predicate<Item> { item in
            item.category.id == categoryID
        })
        
        let vm = DashboardViewModel()
        vm.selectedSegment = initialSegment
        _viewModel = State(initialValue: vm)
    }

    private struct SubcategoryStat: Identifiable {
        var id: String { name }
        let name: String
        let value: Double
    }

    private var chartData: [SubcategoryStat] {
        // 过滤出属于当前一级分类的物品
        let categoryItems = items.filter { $0.category.id == category.id }
        
        var dict = [String: Double]()
        
        for item in categoryItems {
            let subName = item.subcategory?.name ?? "未分类"
            let val = viewModel.calculateValue(for: item)
            
            dict[subName, default: 0] += val
        }
        
        return dict.map { SubcategoryStat(name: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }
    
    private var totalValue: Double {
        chartData.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        VStack {
            Picker("图表类型", selection: $viewModel.selectedSegment) {
                Text("物品总数").tag(0)
                Text("物品总价").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if chartData.isEmpty {
                ContentUnavailableView("暂无数据", systemImage: "chart.pie")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Pie Chart
                        Chart(chartData) { stat in
                            SectorMark(
                                angle: .value("数值", stat.value),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("二级分类", stat.name))
                        }
                        .frame(height: 250)
                        .padding()
                        .chartBackground { chartProxy in
                            GeometryReader { geometry in
                                let frame = geometry[chartProxy.plotAreaFrame]
                                VStack(spacing: 0) {
                                    Text(viewModel.selectedSegment == 0 ? "总量" : "总价")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(viewModel.formatValue(totalValue))
                                        .font(.headline)
                                        .bold()
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }

                        // List
                        VStack(alignment: .leading, spacing: 0) {
                            Text("二级分类明细")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)

                            ForEach(chartData) { stat in
                                HStack {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(stat.name)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Text(viewModel.formatValue(stat.value))
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
