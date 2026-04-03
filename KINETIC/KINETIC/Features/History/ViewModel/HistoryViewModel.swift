import Foundation

@Observable
final class HistoryViewModel {
    var sessions: [Session] = []
    var searchText = ""
    var isLoading = false

    var filteredSessions: [Session] {
        guard !searchText.isEmpty else { return sessions }
        return sessions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.vehicle.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: Fetch from API
    }
}
