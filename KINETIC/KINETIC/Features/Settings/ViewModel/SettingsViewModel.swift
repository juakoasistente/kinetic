import Foundation

@Observable
final class SettingsViewModel {

    // MARK: - Overlay toggles

    var showSpeed = true
    var showDistance = true
    var showTime = false
    var showGPS = true
    var useMetric = true

    // MARK: - Profile

    var userName = ""
    var userTier = ""

    // MARK: - State

    var isLoading = false
    var errorMessage: String?

    // MARK: - Private

    private var saveTask: Task<Void, Never>?
    private var hasLoaded = false

    // MARK: - Load

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }

            guard let userId = SupabaseManager.shared.currentUserId else { return }

            await withTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor [weak self] in
                    await self?.loadProfile(userId: userId)
                }
                group.addTask { @MainActor [weak self] in
                    await self?.loadSettings(userId: userId)
                }
            }
        }
    }

    // MARK: - Save (debounced)

    func settingsDidChange() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await self?.persistSettings()
        }
    }

    func logout() {
        // Handled by SettingsView directly
    }

    // MARK: - Private helpers

    @MainActor
    private func loadProfile(userId: UUID) async {
        do {
            let profile = try await ProfileService.shared.fetchProfile(userId: userId)
            self.userName = profile.nickname
            self.userTier = profile.tier
        } catch {
            print("[SettingsVM] Failed to load profile: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func loadSettings(userId: UUID) async {
        do {
            let settings = try await SettingsService.shared.fetchSettings(userId: userId)
            self.showSpeed = settings.showSpeed
            self.showDistance = settings.showDistance
            self.showTime = settings.showTime
            self.showGPS = settings.showGps
            self.useMetric = settings.useMetric
        } catch {
            print("[SettingsVM] Failed to load settings: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func persistSettings() async {
        guard let userId = SupabaseManager.shared.currentUserId else { return }

        let payload = UserSettings(
            userId: userId,
            showSpeed: showSpeed,
            showDistance: showDistance,
            showTime: showTime,
            showGps: showGPS,
            useMetric: useMetric
        )

        do {
            try await SettingsService.shared.updateSettings(payload)
        } catch {
            print("[SettingsVM] Failed to save settings: \(error.localizedDescription)")
        }
    }
}
