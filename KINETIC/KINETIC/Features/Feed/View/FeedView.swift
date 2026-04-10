import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    var body: some View {
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
                }
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
}

#Preview {
    NavigationStack {
        FeedView()
    }
    .environment(MainTabCoordinator())
}
