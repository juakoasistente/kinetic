import SwiftUI

struct ClipsListView: View {
    @State private var viewModel = ClipsListViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text(LanguageManager.shared.localizedString("clips.title"))
                    .font(.inter(28, weight: .black))
                    .foregroundStyle(Color.coal)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.clips.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.clips) { clip in
                            ClipCardView(clip: clip)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteClip(clip) }
                                    } label: {
                                        Label(
                                            LanguageManager.shared.localizedString("clips.delete"),
                                            systemImage: "trash"
                                        )
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.fog)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.clips.isEmpty {
                await viewModel.loadClips()
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(Color.silver)

            Text(LanguageManager.shared.localizedString("clips.empty.title"))
                .font(.inter(18, weight: .bold))
                .foregroundStyle(Color.coal)

            Text(LanguageManager.shared.localizedString("clips.empty.subtitle"))
                .font(.inter(14, weight: .regular))
                .foregroundStyle(Color.gravel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#Preview {
    NavigationStack {
        ClipsListView()
    }
}
