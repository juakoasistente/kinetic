import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @State private var nickname = "Alex Runner"
    @State private var bio = "Just finished a 10k personal beste"
    @State private var profileImage: UIImage?
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var galleryItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image("back")
                        Text("Settings")
                            .font(.inter(16, weight: .semibold))
                            .foregroundStyle(.coal)
                    }
                }

                Spacer()

                Text("KINETIC")
                    .font(.inter(16, weight: .black))
                    .foregroundStyle(.coal)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile photo
                    VStack(spacing: 12) {
                        Button {
                            showPhotoOptions = true
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                if let profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.stravaOrange.opacity(0.15))
                                        .frame(width: 140, height: 140)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.gravel)
                                        }
                                }

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(.stravaOrange)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .offset(x: 4, y: 4)
                            }
                        }

                        Text("TAP TO UPDATE PHOTO")
                            .font(.inter(11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.stravaOrange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                    // Nickname field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PROFILE NICKNAME")
                            .font(.inter(11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.gravel)

                        TextField("", text: $nickname)
                            .font(.inter(16, weight: .semibold))
                            .foregroundStyle(.coal)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.mist)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)

                    // Bio field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description")
                            .font(.inter(11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.gravel)

                        TextField("Write your description...", text: $bio)
                            .font(.inter(16, weight: .regular))
                            .foregroundStyle(.coal)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.mist)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Info text
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(.gravel)
                        Text("Your nickname and profile picture will be public on the Feed and visible to other athletes in the community.")
                            .font(.inter(13, weight: .regular))
                            .foregroundStyle(.gravel)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    // Feed preview
                    VStack(alignment: .leading, spacing: 14) {
                        Text("FEED PREVIEW")
                            .font(.inter(11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.gravel)

                        HStack(spacing: 12) {
                            if let profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gravel.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.gravel)
                                    }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(nickname.isEmpty ? "Your Name" : nickname)
                                    .font(.inter(15, weight: .bold))
                                    .foregroundStyle(.coal)
                                Text(bio.isEmpty ? "Your bio" : bio)
                                    .font(.inter(13, weight: .regular))
                                    .foregroundStyle(.gravel)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                    // Save button
                    Button {
                        dismiss()
                    } label: {
                        Text("Save Profile Changes")
                            .font(.inter(16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.rust)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                }
            }
            .background(.fog)
        }
        .background(.fog)
        .navigationBarHidden(true)
        .swipeBack { dismiss() }
        .confirmationDialog("Update Profile Photo", isPresented: $showPhotoOptions) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Gallery") { showGallery = true }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                profileImage = image
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showGallery, selection: $galleryItem, matching: .images)
        .onChange(of: galleryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                }
            }
        }
    }
}

// MARK: - Camera

struct CameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                EditProfileView()
            }
    }
}
