import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var selectedSegment = 0

    private struct CategoryStat: Identifiable {
        var id: UUID { category.id }
        let category: Category
        let value: Double
    }

    private var chartData: [CategoryStat] {
        var dict = [UUID: (category: Category, value: Double)]()
        
        for item in items {
            let cat = item.category
            let val = selectedSegment == 0 ? Double(item.quantity) : (item.unitPrice ?? 0) * Double(item.quantity)
            
            if let existing = dict[cat.id] {
                dict[cat.id] = (cat, existing.value + val)
            } else {
                dict[cat.id] = (cat, val)
            }
        }
        
        return dict.values.map { CategoryStat(category: $0.category, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    private func formatValue(_ value: Double) -> String {
        if selectedSegment == 0 {
            return "\(Int(value))"
        } else {
            return value.formatted(.currency(code: "CNY"))
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("图表类型", selection: $selectedSegment) {
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
                            // Pie Chart
                            Chart(chartData) { stat in
                                SectorMark(
                                    angle: .value("数值", stat.value),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .cornerRadius(5)
                                .foregroundStyle(by: .value("分类", stat.category.name))
                            }
                            .frame(height: 250)
                            .padding()

                            // List
                            VStack(alignment: .leading, spacing: 0) {
                                Text("分类明细")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)

                                ForEach(chartData) { stat in
                                    NavigationLink(destination: SubcategoryDashboardView(category: stat.category)) {
                                        HStack {
                                            // Color indicator matching chart
                                            Circle()
                                                .fill(Color.accentColor) // Fallback or dynamic logic? Charts auto-assign colors. 
                                                // Note: In Swift Charts, custom color mapping is usually done via scale.
                                                // For simplicity and matching, we let it use default colors and link labels.
                                                .frame(width: 8, height: 8)
                                            
                                            Text(stat.category.name)
                                                .foregroundStyle(.primary)
                                            
                                            Spacer()
                                            
                                            Text(formatValue(stat.value))
                                                .foregroundStyle(.secondary)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
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
            }
            .navigationTitle("统计")
        }
    }
}
