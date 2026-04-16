import SwiftUI
import PhotosUI

// MARK: - Camera path — confirm photo, then straight to session

struct CapturePhotoView: View {
    @ObservedObject var state: SessionPOCState
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                if state.capturedImage != nil {
                    photoConfirmationContent
                } else {
                    photoPickContent
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $state.capturedImage)
                .ignoresSafeArea()
        }
    }

    // MARK: Pick / capture

    private var photoPickContent: some View {
        VStack(spacing: 20) {
            FadeInTitle(text: "A visual anchor", delay: 0)
            FadeInLine(
                text: "Choose or take a photo — then confirm to start your session.",
                delay: 0.1
            )

            BrandCard {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundStyle(BrandTheme.goldDeep)
                    Text("Add a photo to continue")
                        .font(.caption)
                        .foregroundStyle(BrandTheme.brownMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose from library", systemImage: "photo.stack")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BrandTheme.cream)
                    .foregroundStyle(BrandTheme.brown)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: photoItem) { _, new in
                Task {
                    guard let new else { return }
                    if let data = try? await new.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        await MainActor.run { state.capturedImage = ui }
                    }
                }
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take a picture", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandTheme.goldSoft.opacity(0.5))
                        .foregroundStyle(BrandTheme.brown)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            SecondaryButton(title: "Back") { state.phase = .entryMode }
                .padding(.top, 4)
        }
        .padding(24)
    }

    // MARK: Confirm before session

    private var photoConfirmationContent: some View {
        VStack(spacing: 22) {
            FadeInTitle(text: "Use this photo?", delay: 0)
            FadeInLine(
                text: "We’ll tailor sound and visuals around this anchor.",
                delay: 0.08
            )

            if let img = state.capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(BrandTheme.gold.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: BrandTheme.brown.opacity(0.12), radius: 16, y: 6)
            }

            PrimaryButton(title: "Start session") {
                state.beginSession()
                state.phase = .immersive
            }
            .padding(.horizontal, 4)

            VStack(spacing: 10) {
                SecondaryButton(title: "Choose another photo") {
                    state.capturedImage = nil
                    photoItem = nil
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    SecondaryButton(title: "Take again") {
                        state.capturedImage = nil
                        showCamera = true
                    }
                }
            }
            .padding(.horizontal, 4)

            SecondaryButton(title: "Back") {
                state.capturedImage = nil
                photoItem = nil
                state.phase = .entryMode
            }
            .padding(.top, 4)
        }
        .padding(24)
    }
}

// MARK: - Camera bridge

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let c = UIImagePickerController()
        c.sourceType = .camera
        c.delegate = context.coordinator
        return c
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let ui = info[.originalImage] as? UIImage {
                parent.image = ui
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
