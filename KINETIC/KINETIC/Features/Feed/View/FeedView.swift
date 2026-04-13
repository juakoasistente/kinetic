import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                VStack {
                    Spacer()
                    SpinningView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.posts.isEmpty {
                emptyState
            } else {
                feedContent
            }
        }
        .background(Color.fog)
        .refreshable {
            await viewModel.loadFeed()
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadFeed()
            }
        }
    }

    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    PostCardView(
                        post: post,
                        onLike: { Task { await viewModel.toggleLike(for: post) } },
                        onComment: { tabCoordinator.feedPath.append(.postDetail(post)) },
                        onShare: {},
                        onBookmark: { Task { await viewModel.toggleBookmark(for: post) } }
                    )
                    .onTapGesture {
                        tabCoordinator.feedPath.append(.postDetail(post))
                    }
                    .onAppear {
                        if post == viewModel.posts.last {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    SpinningView()
                        .scaleEffect(0.5)
                        .padding(24)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(Color.silver)

            Text(LanguageManager.shared.localizedString("feed.empty.title"))
                .font(.inter(18, weight: .bold))
                .foregroundStyle(Color.coal)

            Text(LanguageManager.shared.localizedString("feed.empty.subtitle"))
                .font(.inter(14, weight: .regular))
                .foregroundStyle(Color.gravel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        FeedView()
    }
    .environment(MainTabCoordinator())
}
