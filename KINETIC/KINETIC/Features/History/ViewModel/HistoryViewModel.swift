import Foundation

@Observable
final class HistoryViewModel {
    var sessions: [Session] = []
    var searchText = "" {
        didSet { scheduleSearch() }
    }
    var isLoading = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    var filteredSessions: [Session] {
        guard !searchText.isEmpty else { return sessions }
        return sessions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.vehicle.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }

        guard let userId = SupabaseManager.shared.currentUserId else {
            sessions = []
            return
        }

        do {
            sessions = try await SessionService.shared.fetchSessions(userId: userId)
        } catch {
            sessions = []
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Server-Side Search

    private func scheduleSearch() {
        searchTask?.cancel()
        guard searchText.count > 2 else { return }

        searchTask = Task { [searchText] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            guard let userId = SupabaseManager.shared.currentUserId else { return }

            do {
                let results = try await SessionService.shared.searchSessions(userId: userId, query: searchText)
                guard !Task.isCancelled else { return }
                sessions = results
            } catch {
                // Fall back to local filtering
            }
        }
    }

    // MARK: - Preview

    static var preview: HistoryViewModel {
        let vm = HistoryViewModel()
        vm.sessions = Session.mockData
        return vm
    }
}
