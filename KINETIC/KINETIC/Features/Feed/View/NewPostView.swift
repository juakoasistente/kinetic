import SwiftUI
import PhotosUI

struct NewPostView: View {
    @State private var viewModel = NewPostViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("KINETIC")
                    .font(.inter(16, weight: .black))
                    .foregroundStyle(.stravaOrange)

                Spacer()

                // Invisible balance element
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.black)

            // MARK: - Content
            ScrollView(showsIndicators: false) {
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
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            // MARK: - Publish Button
            VStack(spacing: 0) {
                Divider()
                    .overlay(Color.white.opacity(0.1))

                Button {
                    Task {
                        await viewModel.publish()
                        if viewModel.didPublish {
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isPublishing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                        }
                        Text(viewModel.isPublishing
                             ? LanguageManager.shared.localizedString("newPost.publish").uppercased() + "..."
                             : LanguageManager.shared.localizedString("newPost.publish").uppercased()
                        )
                            .font(.inter(15, weight: .black))
                            .tracking(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(viewModel.canPublish && !viewModel.isPublishing ? Color.stravaOrange : Color.gravel)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.canPublish || viewModel.isPublishing)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(.black)
        }
        .background(.black)
        .dismissKeyboardOnTap()
        .navigationBarHidden(true)
        .task {
            await viewModel.loadSessions()
        }
        .alert(LanguageManager.shared.localizedString("alert.error"), isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(LanguageManager.shared.localizedString("alert.ok")) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Activity Selector

    private var activitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString("newPost.selectActivity"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(.gravel)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableSessions) { session in
                        sessionChip(session)
                    }
                }
                .padding(.horizontal, 20)
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
                    .fill(isSelected ? Color.stravaOrange : Color.white.opacity(0.08))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "car.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(isSelected ? .white : .gravel)
                    }

                Text(session.name)
                    .font(.inter(11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.stravaOrange : .gravel)
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
                .foregroundStyle(.gravel)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 20)

            HStack(spacing: 0) {
                statBlock(value: String(format: "%.0f", 142), unit: "KM/H")
                Spacer()
                statBlock(value: String(format: "%.1f", session.distance), unit: "KM")
                Spacer()
                statBlock(value: session.formattedDuration, unit: "MIN")
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
    }

    private func statBlock(value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.inter(22, weight: .bold))
                .foregroundStyle(.white)
            Text(unit)
                .font(.inter(10, weight: .medium))
                .foregroundStyle(.gravel)
        }
    }

    // MARK: - Description

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.localizedString("newPost.description"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(.gravel)
                .textCase(.uppercase)
                .tracking(1)

            TextField(
                LanguageManager.shared.localizedString("newPost.descriptionPlaceholder"),
                text: $viewModel.postDescription,
                axis: .vertical
            )
            .font(.inter(14, weight: .regular))
            .foregroundStyle(.white)
            .lineLimit(3...6)
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Media Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LanguageManager.shared.localizedString("newPost.photos"))
                .font(.inter(12, weight: .bold))
                .foregroundStyle(.gravel)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add media button
                    PhotosPicker(
                        selection: $viewModel.selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .any(of: [.images, .videos])
                    ) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.gravel)
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

                    // Selected videos (thumbnails with play icon)
                    ForEach(viewModel.videoThumbnails.indices, id: \.self) { index in
                        ZStack {
                            Image(uiImage: viewModel.videoThumbnails[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(radius: 4)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    NewPostView()
}
