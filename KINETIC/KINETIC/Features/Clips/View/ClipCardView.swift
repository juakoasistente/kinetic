import SwiftUI

struct ClipCardView: View {
    let clip: Clip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Thumbnail
            if let thumbnailUrl = clip.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    thumbnailPlaceholder
                }
            } else {
                thumbnailPlaceholder
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Title
            Text(clip.title)
                .font(.inter(16, weight: .bold))
                .foregroundStyle(.white)
                .padding(16)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color.coal)
            .overlay {
                Image(systemName: "film")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.gravel)
            }
    }
}

#Preview {
    ClipCardView(clip: Clip.mockData[0])
        .padding()
}
