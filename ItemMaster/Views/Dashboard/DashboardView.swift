import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @Query private var items: [Item]
    @State private var viewModel = DashboardViewModel()

    private struct CategoryStat: Identifiable {
        var id: UUID { category.id }
        let category: Category
        let value: Double
    }

    private var chartData: [CategoryStat] {
        var dict = [UUID: (category: Category, value: Double)]()
        
        for item in items {
            let cat = item.category
            let val = viewModel.calculateValue(for: item)
            
            if let existing = dict[cat.id] {
                dict[cat.id] = (cat, existing.value + val)
            } else {
                dict[cat.id] = (cat, val)
            }
        }
        
        return dict.values.map { CategoryStat(category: $0.category, value: $0.value) }
            .sorted { $0.value > $1.value }
    }
    
    private var totalValue: Double {
        chartData.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("图表类型", selection: $viewModel.selectedSegment) {
                    Text("物品总数").tag(0)
                    Text("物品总价").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if items.isEmpty {
                    ContentUnavailableView("暂无数据", systemImage: "chart.pie", description: Text("添加物品后即可查看统计"))
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Donut Chart
                            Chart(chartData) { stat in
                                SectorMark(
                                    angle: .value("数值", stat.value),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2.0
                                )
                                .cornerRadius(8)
                                .foregroundStyle(by: .value("分类", stat.category.name))
                            }
                            .frame(height: 280)
                            .padding()
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    let frame = geometry[chartProxy.plotAreaFrame]
                                    VStack(spacing: 4) {
                                        Text(viewModel.centerTitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(viewModel.formatValue(totalValue))
                                            .font(.title2)
                                            .bold()
                                            .multilineTextAlignment(.center)
                                    }
                                    .position(x: frame.midX, y: frame.midY)
                                }
                            }

                            // List
                            VStack(alignment: .leading, spacing: 12) {
                                Text("分类明细")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(chartData) { stat in
                                    NavigationLink(destination: SubcategoryDashboardView(category: stat.category, initialSegment: viewModel.selectedSegment)) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(Color.accentColor)
                                                .frame(width: 10, height: 10)
                                            
                                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                                Text(stat.category.name)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                Text("(\(viewModel.calculatePercentage(value: stat.value, total: totalValue)))")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(viewModel.formatValue(stat.value))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemBackground).opacity(0.6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("统计")
        }
    }
}
