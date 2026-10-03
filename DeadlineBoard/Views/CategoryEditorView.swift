import SwiftUI

enum CategoryEditorMode {
    case create
    case edit(DDCategory)
}

struct CategoryEditorView: View {
    let mode: CategoryEditorMode
    let onSave: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedColorHex: String
    @State private var selectedIcon: String

    init(mode: CategoryEditorMode, onSave: @escaping (String, String, String) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _selectedColorHex = State(initialValue: AppConstants.CategoryColors.all[0].hex)
            _selectedIcon = State(initialValue: "folder.fill")
        case .edit(let category):
            _name = State(initialValue: category.name)
            _selectedColorHex = State(initialValue: category.colorHex)
            _selectedIcon = State(initialValue: category.iconName)
        }
    }

    private var title: String {
        switch mode {
        case .create: "新建分类"
        case .edit: "编辑分类"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $name)

                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 8), count: 5), spacing: 8) {
                        ForEach(AppConstants.CategoryColors.all, id: \.hex) { c in
                            Circle()
                                .fill(Color(hex: c.hex) ?? .blue)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if c.hex == selectedColorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColorHex = c.hex }
                        }
                    }
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 4), spacing: 8) {
                        ForEach(AppConstants.CategoryIcons.all, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(icon == selectedIcon ? (Color(hex: selectedColorHex) ?? .blue).opacity(0.2) : .clear)
                                )
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                }
            }
            .padding()
            .frame(minWidth: 320, minHeight: 350)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, selectedColorHex, selectedIcon)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
