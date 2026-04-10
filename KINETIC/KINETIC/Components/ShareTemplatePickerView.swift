import SwiftUI

struct ShareTemplatePickerView: View {
    let shareData: ShareData
    var onShare: (ShareTemplate) -> Void

    @State private var selected: ShareTemplate = .mapCard

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(LanguageManager.shared.localizedString("share.chooseStyle"))
                .font(.inter(12, weight: .bold))
                .tracking(2)
                .foregroundStyle(.gravel)
                .padding(.top, 24)

            // Preview — centered, paged
            TabView(selection: $selected) {
                ForEach(ShareTemplate.allCases) { template in
                    templatePreview(template)
                        .tag(template)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 520)
            .padding(.top, 32)

            // Template name + dots
            VStack(spacing: 12) {
                Text(selected.displayName)
                    .font(.inter(16, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    ForEach(ShareTemplate.allCases) { template in
                        Circle()
                            .fill(template == selected ? Color.stravaOrange : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.top, 12)

            Spacer()

            // Share button
            Button {
                onShare(selected)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                    Text(LanguageManager.shared.localizedString("share.share"))
                        .font(.inter(15, weight: .black))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.stravaOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(.black)
    }

    // MARK: - Template Preview Card

    private func templatePreview(_ template: ShareTemplate) -> some View {
        let isSelected = selected == template

        return ShareCardView(data: shareData, template: template)
            .scaleEffect(0.7)
            .frame(width: 280, height: 500)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.stravaOrange : Color.white.opacity(0.1), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: isSelected ? Color.stravaOrange.opacity(0.3) : .clear, radius: 12)
    }
}

#Preview {
    ShareTemplatePickerView(shareData: .preview) { template in
        print("Selected: \(template)")
    }
}
