import SwiftUI
import SwiftData
import Charts

struct SubcategoryDashboardView: View {
    let category: Category
    @Query private var items: [Item]
    @State private var selectedSegment = 0

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
            let val = selectedSegment == 0 ? Double(item.quantity) : (item.unitPrice ?? 0) * Double(item.quantity)
            
            dict[subName, default: 0] += val
        }
        
        return dict.map { SubcategoryStat(name: $0.key, value: $0.value) }
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
        VStack {
            Picker("图表类型", selection: $selectedSegment) {
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
                                    
                                    Text(formatValue(stat.value))
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
