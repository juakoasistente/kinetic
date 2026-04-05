import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showLogoutAlert = false
    @State private var showLanguageSheet = false
    @State private var showLegal: LegalType?
    @State private var showEditProfile = false
    @State private var currentLanguage: AppLanguage = LanguageManager.shared.current
    @Environment(AppCoordinator.self) private var appCoordinator
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile card
                profileCard
                    .onTapGesture { showEditProfile = true }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Overlay Customization
                sectionHeader(icon: "overlay", title: "OVERLAY CUSTOMIZATION")

                VStack(spacing: 0) {
                    toggleRow(icon: "speed", title: "Speed", isOn: $viewModel.showSpeed)
                    toggleRow(icon: "speed", title: "Distance", isOn: $viewModel.showDistance)
                    toggleRow(icon: "time", title: "Time", isOn: $viewModel.showTime)
                    toggleRow(icon: "gps", title: "GPS Status", isOn: $viewModel.showGPS)
                    unitsRow
                }
                .padding(.horizontal, 20)

                // General Settings
                sectionHeader(icon: "settingsSelected", title: "GENERAL SETTINGS")

                VStack(spacing: 0) {
                    navigationRow(icon: "language", title: "Language", detail: currentLanguage.title)
                        .onTapGesture { showLanguageSheet = true }
                    navigationRow(icon: "privacy", title: "Privacy Policy")
                        .onTapGesture { showLegal = .privacy }
                    navigationRow(icon: "terms 1", title: "Terms of Service")
                        .onTapGesture { showLegal = .terms }
                }
                .padding(.horizontal, 20)

                // Logout
                Button { showLogoutAlert = true } label: {
                    HStack(spacing: 8) {
                        Image("logout")
                        Text("LOG OUT")
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
                Text("KINETIC V1.1.0")
                    .font(.inter(9, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.gravel.opacity(0.5))
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
        }
        .background(.fog)
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
        .fullScreenCover(item: $showLegal) { type in
            LegalView(type: type)
        }
        .sheet(isPresented: $showLanguageSheet) {
            LanguageSelectorView(current: currentLanguage) { language in
                LanguageManager.shared.current = language
                currentLanguage = language
            }
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                appCoordinator.showAuth()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gravel.opacity(0.3))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.gravel)
                    }

                Image("edit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.userName)
                    .font(.inter(18, weight: .bold))
                    .foregroundStyle(.coal)
                Text(viewModel.userTier)
                    .font(.inter(13, weight: .regular))
                    .foregroundStyle(.gravel)
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
