import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("globalDisplayCurrency") var displayCurrency: String = Constants.Currency.usd.rawValue
    @AppStorage("usdToCnyRate") var exchangeRate: Double = Constants.usdToCnyRate
    
    let item: Item
    
    @State private var showDeleteConfirmation = false
    @State private var showEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image Header
                headerImage
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Tags
                    titleSection
                    
                    // Main Info Grid/List
                    infoSection
                    
                    // Notes Section
                    if let notes = item.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    
                    // Delete Button
                    deleteButton
                }
                .padding()
            }
        }
        .navigationTitle("物品详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") {
                    showEditView = true
                }
            }
        }
        .sheet(isPresented: $showEditView) {
            EditItemView(item: item)
        }
        .confirmationDialog("确定删除该物品吗？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                deleteItem()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后将无法恢复，且对应的图片也将被永久删除。")
        }
    }
    
    // MARK: - View Components
    
    private var headerImage: some View {
        ItemImageView(filename: item.imageFilename)
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.title)
                .bold()
            
            if !item.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(item.tags) { tag in
                        Text(tag.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                let categoryValue = item.category.name + (item.subcategory.map { " > \($0.name)" } ?? "")
                detailRow(label: "分类", value: categoryValue)
                detailRow(label: "数量", value: QuantityHelper.format(item.quantity))
                
                if let location = item.location {
                    let locationValue = location.name + (item.sublocation.map { " > \($0.name)" } ?? "")
                    detailRow(label: "位置", value: locationValue)
                }
                
                if let price = item.unitPrice {
                    let convertedPrice = CurrencyHelper.convert(price, from: item.originalCurrency, to: displayCurrency, rate: exchangeRate)
                    let formattedPrice = CurrencyHelper.format(convertedPrice, to: displayCurrency)
                    detailRow(label: "单价", value: formattedPrice)
                }
            }
            
            Divider().padding(.vertical, 4)
            
            Group {
                if let acquiredDate = item.acquiredDate {
                    detailRow(label: "获取时间", value: acquiredDate.formatted(date: .long, time: .omitted))
                }
                
                if let expiryDate = item.expiryDate {
                    detailRow(label: "过期时间", value: expiryDate.formatted(date: .long, time: .omitted))
                }
                
                if let shelfLife = item.shelfLifeDays {
                    detailRow(label: "保质期", value: "\(shelfLife) 天")
                }
                
                if let restock = item.restockIntervalDays {
                    detailRow(label: "补货频率", value: "每 \(restock) 天")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.headline)
            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("删除物品")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 20)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
    
    // MARK: - Actions
    
    private func deleteItem() {
        let filename = item.imageFilename
        modelContext.delete(item)
        try? modelContext.save()
        if let filename = filename {
            ImageStorage.delete(filename: filename)
        }
        dismiss()
    }
}
