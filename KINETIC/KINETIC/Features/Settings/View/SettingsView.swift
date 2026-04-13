import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var overlaySettings = OverlaySettings.shared
    @State private var showLogoutAlert = false
    @State private var showLanguageSheet = false
    @State private var showLegal: LegalType?
    @State private var showEditProfile = false
    @State private var currentLanguage: AppLanguage = LanguageManager.shared.current
    @Environment(AppCoordinator.self) private var appCoordinator
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Profile card
                profileCard
                    .onTapGesture { showEditProfile = true }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Overlay Customization
                sectionHeader(icon: "overlay", title: LanguageManager.shared.localizedString("settings.overlayCustomization"))

                VStack(spacing: 0) {
                    toggleRow(icon: "speed", title: LanguageManager.shared.localizedString("settings.overlay.speed"), isOn: $overlaySettings.showSpeed)
                    toggleRow(icon: "speed", title: LanguageManager.shared.localizedString("settings.overlay.maxSpeed"), isOn: $overlaySettings.showMaxSpeed)
                    toggleRow(icon: "speed", title: LanguageManager.shared.localizedString("settings.overlay.avgSpeed"), isOn: $overlaySettings.showAvgSpeed)
                    toggleRow(icon: "speed", title: LanguageManager.shared.localizedString("settings.overlay.distance"), isOn: $overlaySettings.showDistance)
                    toggleRow(icon: "time", title: LanguageManager.shared.localizedString("settings.overlay.time"), isOn: $overlaySettings.showTime)
                    toggleRow(icon: "gps", title: LanguageManager.shared.localizedString("settings.overlay.miniMap"), isOn: $overlaySettings.showMiniMap)
                    unitsRow
                }
                .padding(.horizontal, 20)

                // General Settings
                sectionHeader(icon: "settingsSelected", title: LanguageManager.shared.localizedString("settings.generalSettings"))

                VStack(spacing: 0) {
                    navigationRow(icon: "language", title: LanguageManager.shared.localizedString("settings.language"), detail: currentLanguage.title)
                        .onTapGesture { showLanguageSheet = true }
                    navigationRow(icon: "privacy", title: LanguageManager.shared.localizedString("settings.privacyPolicy"))
                        .onTapGesture { showLegal = .privacy }
                    navigationRow(icon: "terms 1", title: LanguageManager.shared.localizedString("settings.termsOfService"))
                        .onTapGesture { showLegal = .terms }
                }
                .padding(.horizontal, 20)

                // Logout
                Button { showLogoutAlert = true } label: {
                    HStack(spacing: 8) {
                        Image("logout")
                        Text(localized: "settings.logout")
                            .font(.inter(14, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundStyle(.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.danger.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Version
                Text("KINETIC V\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.inter(9, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.gravel.opacity(0.5))
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
        }
        .background(.fog)
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.fog.ignoresSafeArea()
                    SpinningView()
                }
            }
        }
        .toolbarBackground(.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("logoNavBar")
            }
        }
        .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
            case .editProfile:
                EditProfileView()
            case .language:
                LanguageSelectorView()
            case .terms:
                LegalView(type: .terms)
            case .privacy:
                LegalView(type: .privacy)
            }
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView()
            }
        }
        .onChange(of: showEditProfile) { _, isShowing in
            if !isShowing {
                // Reload profile after editing
                viewModel.forceReload()
            }
        }
        .fullScreenCover(item: $showLegal) { type in
            LegalView(type: type)
        }
        .sheet(isPresented: $showLanguageSheet) {
            LanguageSelectorView(current: currentLanguage) { language in
                LanguageManager.shared.current = language
                currentLanguage = language
            }
        }
        .alert(LanguageManager.shared.localizedString("settings.logoutTitle"), isPresented: $showLogoutAlert) {
            Button(LanguageManager.shared.localizedString("settings.cancel"), role: .cancel) {}
            Button(LanguageManager.shared.localizedString("settings.logoutTitle"), role: .destructive) {
                Task { try? await SupabaseManager.shared.signOut() }
                appCoordinator.showAuth()
            }
        } message: {
            Text(localized: "settings.logoutMessage")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let avatarUrl = viewModel.userAvatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gravel.opacity(0.3))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.gravel)
                            }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gravel.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.gravel)
                        }
                }

                Image("edit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.userName.isEmpty ? "KINETIC User" : viewModel.userName)
                    .font(.inter(18, weight: .bold))
                    .foregroundStyle(.coal)
                if !viewModel.userBio.isEmpty {
                    Text(viewModel.userBio)
                        .font(.inter(13, weight: .regular))
                        .foregroundStyle(.gravel)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(title)
                .font(.inter(11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(.coal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    // MARK: - Rows

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .frame(width: 32, height: 32)
                    .cornerRadius(4)
                    .foregroundColor(.mist)
                
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            

            Text(title)
                .font(.inter(15, weight: .medium))
                .foregroundStyle(.coal)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .scaleEffect(0.8)
                .tint(.stravaOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private var unitsRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .frame(width: 32, height: 32)
                    .cornerRadius(4)
                    .foregroundColor(.mist)
                
                Image("units")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            
            Text("Units")
                .font(.inter(15, weight: .medium))
                .foregroundStyle(.coal)

            Spacer()

            HStack(spacing: 0) {
                unitButton(title: "KM", selected: viewModel.useMetric) {
                    viewModel.useMetric = true
                }
                unitButton(title: "MI", selected: !viewModel.useMetric) {
                    viewModel.useMetric = false
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }

    private func unitButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.inter(12, weight: .bold))
                .foregroundStyle(selected ? .white : .gravel)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? .stravaOrange : .icicle)
        }
    }

    private func navigationRow(icon: String, title: String, detail: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text(title)
                .font(.inter(15, weight: .medium))
                .foregroundStyle(.coal)

            Spacer()

            if let detail {
                Text(detail)
                    .font(.inter(13, weight: .regular))
                    .foregroundStyle(.gravel)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.gravel.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color.white)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppCoordinator())
    .environment(MainTabCoordinator())
    .environment(LanguageManager.shared)
}
