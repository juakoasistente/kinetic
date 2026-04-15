import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

            // FAB — New post
            Button {
                tabCoordinator.feedPath.append(.newPost)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.stravaOrange)
                    .clipShape(Circle())
                    .shadow(color: .stravaOrange.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
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
                        onComment: { tabCoordinator.feedPath.append(.postDetail(post)) }
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
