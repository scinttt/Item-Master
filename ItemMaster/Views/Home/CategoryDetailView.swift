import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category
    @State private var isAddingSubcategory = false
    @State private var newSubcategoryName = ""
    @State private var showAddItem = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Rename and Delete state
    @State private var subcategoryToRename: Subcategory?
    @State private var renameInput = ""
    @State private var showRenameAlert = false
    
    @State private var subcategoryToDelete: Subcategory?
    @State private var showDeleteRestrictedAlert = false
    @State private var showDeleteConfirmAlert = false

    var body: some View {
        List {
            if !category.subcategories.isEmpty {
                Section {
                    ForEach(category.subcategories.sorted(by: { $0.sortOrder < $1.sortOrder })) { subcategory in
                        NavigationLink(destination: SubcategoryItemsView(subcategory: subcategory)) {
                            HStack {
                                Text(subcategory.name)
                                Spacer()
                                Text("\(subcategory.items.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                prepareDelete(subcategory)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            Button {
                                prepareRename(subcategory)
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                    .onMove(perform: moveSubcategories)
                }
            }

            // Inline add subcategory
            Section {
                if isAddingSubcategory {
                    TextField("二级分类名称", text: $newSubcategoryName)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            saveNewSubcategory()
                        }
                        .onChange(of: isTextFieldFocused) { _, isFocused in
                            if !isFocused && isAddingSubcategory {
                                saveNewSubcategory()
                            }
                        }
                } else {
                    Button {
                        isAddingSubcategory = true
                        isTextFieldFocused = true
                    } label: {
                        Label("添加二级分类", systemImage: "plus")
                            .foregroundStyle(.tint)
                    }
                }
            }

            Section {
                NavigationLink(destination: AllItemsInCategoryView(category: category)) {
                    Text("显示所有 \(category.name)")
                        .foregroundStyle(.tint)
                }
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView(initialCategory: category)
        }
        .alert("重命名二级分类", isPresented: $showRenameAlert) {
            TextField("新名称", text: $renameInput)
            Button("取消", role: .cancel) {}
            Button("保存") {
                if let subcategory = subcategoryToRename {
                    subcategory.name = renameInput.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        .alert("无法删除", isPresented: $showDeleteRestrictedAlert) {
            Button("我知道了", role: .cancel) {}
        } message: {
            Text("该分类下仍有物品。请先将物品清空，然后再尝试删除。")
        }
        .alert("确认删除", isPresented: $showDeleteConfirmAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let subcategory = subcategoryToDelete {
                    // 显式从父分类的数组中移除，确保 UI 立即刷新
                    category.subcategories.removeAll { $0.id == subcategory.id }
                    modelContext.delete(subcategory)
                    try? modelContext.save()
                }
            }
        } message: {
            Text("您确定要删除这个空分类吗？")
        }
    }

    private func saveNewSubcategory() {
        let trimmed = newSubcategoryName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let subcategory = Subcategory(name: trimmed, parentCategory: category, sortOrder: category.subcategories.count)
            modelContext.insert(subcategory)
            category.subcategories.append(subcategory)
        }
        newSubcategoryName = ""
        isAddingSubcategory = false
    }
    
    private func prepareRename(_ subcategory: Subcategory) {
        subcategoryToRename = subcategory
        renameInput = subcategory.name
        showRenameAlert = true
    }
    
    private func prepareDelete(_ subcategory: Subcategory) {
        subcategoryToDelete = subcategory
        if !subcategory.items.isEmpty {
            showDeleteRestrictedAlert = true
        } else {
            showDeleteConfirmAlert = true
        }
    }

    private func moveSubcategories(from source: IndexSet, to destination: Int) {
        var revisedItems = category.subcategories.sorted(by: { $0.sortOrder < $1.sortOrder })
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for index in 0..<revisedItems.count {
            revisedItems[index].sortOrder = index
        }
        try? modelContext.save()
    }
}
