import Foundation

@Observable
final class ClipsListViewModel {
    var clips: [Clip] = []
    var isLoading = false
    var errorMessage: String?

    func loadClips() async {
        guard let userId = SupabaseManager.shared.currentUserId else { return }
        isLoading = true
        do {
            clips = try await ClipService.shared.fetchClips(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteClip(_ clip: Clip) async {
        do {
            try await ClipService.shared.deleteClip(id: clip.id)
            clips.removeAll { $0.id == clip.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Preview

    static var preview: ClipsListViewModel {
        let vm = ClipsListViewModel()
        vm.clips = Clip.mockData
        return vm
    }
}
