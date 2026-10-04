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
    @FocusState private var nameFieldFocused: Bool

    init(mode: CategoryEditorMode, onSave: @escaping (String, String, String) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _selectedColorHex = State(initialValue: CategoryPalette.all[0].hex)
            _selectedIcon = State(initialValue: "folder.fill")
        case .edit(let category):
            _name = State(initialValue: category.name)
            _selectedColorHex = State(initialValue: category.colorHex)
            _selectedIcon = State(initialValue: category.iconName)
        }
    }

    private var isCreate: Bool {
        if case .create = mode { return true }
        return false
    }

    private var currentPal: CategoryPalette {
        CategoryPalette.forHex(selectedColorHex)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text(isCreate ? "新建分类" : "编辑分类")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 18)

            // Preview
            HStack(spacing: 12) {
                Circle()
                    .fill(currentPal.tint)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 18))
                            .foregroundStyle(currentPal.deep)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name.isEmpty ? "分类名称" : name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(name.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                    Text("预览")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(currentPal.base.opacity(0.3), lineWidth: 1))
            )
            .padding(.bottom, 20)

            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text("名称")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                TextField("例如 课程名", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#F1EBE0")!)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(nameFieldFocused ? currentPal.base.opacity(0.6) : Theme.divider, lineWidth: 1)
                            )
                    )
                    .focused($nameFieldFocused)
            }
            .padding(.bottom, 18)

            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("颜色")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 10) {
                    ForEach(CategoryPalette.all, id: \.hex) { pal in
                        Button(action: { selectedColorHex = pal.hex }) {
                            Circle()
                                .fill(pal.base)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if pal.hex.uppercased() == selectedColorHex.uppercased() {
                                        Circle()
                                            .stroke(Theme.background, lineWidth: 2)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .shadow(
                                    color: pal.hex.uppercased() == selectedColorHex.uppercased()
                                        ? pal.base.opacity(0.5) : .clear,
                                    radius: 4
                                )
                        }
                        .buttonStyle(.plain)
                        .help(pal.name)
                    }
                }
            }
            .padding(.bottom, 18)

            // Icon picker
            VStack(alignment: .leading, spacing: 8) {
                Text("图标")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 6), count: 8), spacing: 6) {
                    ForEach(AppConstants.CategoryIcons.all, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundStyle(icon == selectedIcon ? currentPal.deep : Theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(icon == selectedIcon ? currentPal.tint : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 16)

            // Actions
            HStack(spacing: 8) {
                Spacer()
                Button(action: { dismiss() }) {
                    Text("取消")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(Theme.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: {
                    onSave(name, selectedColorHex, selectedIcon)
                    dismiss()
                }) {
                    Text(isCreate ? "添加" : "保存")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.background)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(currentPal.deep))
                        .opacity(canSave ? 1 : 0.45)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
        .padding(22)
        .frame(width: 400)
        .background(Theme.background)
        .onAppear { nameFieldFocused = true }
    }
}
