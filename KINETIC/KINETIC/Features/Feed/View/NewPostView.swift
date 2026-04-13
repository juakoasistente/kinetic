import SwiftUI
import PhotosUI

struct NewPostView: View {
    @State private var viewModel = NewPostViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Select Activity
                activitySelector

                // MARK: - Selected Session Preview
                if let session = viewModel.selectedSession {
                    sessionPreview(session)
                }

                // MARK: - Description
                descriptionField

                // MARK: - Photo Picker
                photoSection

                // MARK: - Visibility
                visibilitySelector
            }
            .padding(.vertical, 16)
        }
        .background(Color.fog)
        .dismissKeyboardOnTap()
        .navigationTitle(LanguageManager.shared.localizedString("newPost.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.coal)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.publish()
                        if viewModel.didPublish {
                            dismiss()
                        }
                    }
                } label: {
                    Text(LanguageManager.shared.localizedString("newPost.publish"))
                        .font(.inter(14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.canPublish ? Color.stravaOrange : Color.silver)
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.canPublish || viewModel.isPublishing)
            }
        }
        .task {
            await viewModel.loadSessions()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Activity Selector

    private var activitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString("newPost.selectActivity"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(Color.gravel)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableSessions) { session in
                        sessionChip(session)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func sessionChip(_ session: Session) -> some View {
        let isSelected = viewModel.selectedSession?.id == session.id
        return Button {
            viewModel.selectedSession = isSelected ? nil : session
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? Color.stravaOrange : Color.mist)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "car.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(isSelected ? .white : Color.gravel)
                    }

                Text(session.name)
                    .font(.inter(11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.stravaOrange : Color.gravel)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
    }

    // MARK: - Session Preview

    private func sessionPreview(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString("newPost.telemetry"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(Color.gravel)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                statBlock(value: String(format: "%.0f", 142), unit: "KM/H")
                Spacer()
                statBlock(value: String(format: "%.1f", session.distance), unit: "KM")
                Spacer()
                statBlock(value: session.formattedDuration, unit: "MIN")
            }
            .padding(16)
            .background(Color.coal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    private func statBlock(value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.inter(22, weight: .bold))
                .foregroundStyle(.white)
            Text(unit)
                .font(.inter(10, weight: .medium))
                .foregroundStyle(Color.gravel)
        }
    }

    // MARK: - Description

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.localizedString("newPost.description"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(Color.gravel)
                .textCase(.uppercase)
                .tracking(1)

            TextField(
                LanguageManager.shared.localizedString("newPost.descriptionPlaceholder"),
                text: $viewModel.postDescription,
                axis: .vertical
            )
            .font(.inter(14, weight: .regular))
            .lineLimit(3...6)
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString("newPost.photos"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(Color.gravel)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add photo button
                    PhotosPicker(selection: $viewModel.selectedPhotos, maxSelectionCount: 5, matching: .images) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.mist)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.gravel)
                            }
                    }

                    // Selected photos
                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                        Image(uiImage: viewModel.selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Visibility Selector

    private var visibilitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString("newPost.community"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(Color.gravel)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(PostVisibility.allCases, id: \.self) { visibility in
                    Button {
                        viewModel.visibility = visibility
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: visibility.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    viewModel.visibility == visibility ? Color.stravaOrange : Color.gravel
                                )
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(visibility.displayName)
                                    .font(.inter(14, weight: .semibold))
                                    .foregroundStyle(Color.coal)
                            }

                            Spacer()

                            if viewModel.visibility == visibility {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.stravaOrange)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    if visibility != PostVisibility.allCases.last {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    NavigationStack {
        NewPostView()
    }
}
