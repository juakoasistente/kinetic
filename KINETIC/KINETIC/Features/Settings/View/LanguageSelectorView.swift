import SwiftUI

struct LanguageSelectorView: View {
    @State private var selected: AppLanguage
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (AppLanguage) -> Void = { _ in }

    init(current: AppLanguage = .english, onConfirm: @escaping (AppLanguage) -> Void = { _ in }) {
        self._selected = State(initialValue: current)
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(localized: "settings.language")
                .font(.inter(28, weight: .extraBold))
                .foregroundStyle(.coal)
                .padding(.top, 24)

            Text(localized: "language.subtitle")
                .font(.inter(14, weight: .regular))
                .foregroundStyle(.gravel)
                .padding(.top, 6)

            VStack(spacing: 0) {
                ForEach(AppLanguage.allCases) { language in
                    languageRow(language: language)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 24)

            Button {
                onConfirm(selected)
                dismiss()
            } label: {
                Text(localized: "language.confirm")
                    .font(.inter(16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.rust)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 24)

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(.fog)
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.visible)
    }

    private func languageRow(language: AppLanguage) -> some View {
        Button {
            selected = language
        } label: {
            HStack(spacing: 14) {
                Text(language.code)
                    .font(.inter(12, weight: .bold))
                    .foregroundStyle(selected == language ? .stravaOrange : .gravel.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(selected == language ? Color.stravaOrange.opacity(0.15) : .mist)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(language.title)
                    .font(.inter(16, weight: .semibold))
                    .foregroundStyle(.coal)

                Spacer()

                Circle()
                    .strokeBorder(selected == language ? Color.clear : Color.silver, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(selected == language ? .stravaOrange : .clear)
                    )
                    .overlay {
                        if selected == language {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(selected == language ? Color.white : .clear)
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            LanguageSelectorView(current: .spanish)
        }
}
