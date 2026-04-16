import SwiftUI
import PhotosUI

// MARK: - 3. Capture moment

struct CaptureHomeView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Capture the moment")
                    .font(BrandTheme.title(.largeTitle))
                    .foregroundStyle(BrandTheme.brown)
                    .multilineTextAlignment(.center)
                Text("We’ll read colour, light, and context — then build an ethereal soundscape around you.")
                    .font(.body)
                    .foregroundStyle(BrandTheme.brownMuted)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Start Session") {
                    state.phase = .capturePhoto
                }
                .padding(.horizontal, 24)

                BrandCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Optional biometrics", systemImage: "waveform.path.ecg")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.brown)
                        Text("When Health is connected, we blend live heart rate with your image context (simulated here).")
                            .font(.caption)
                            .foregroundStyle(BrandTheme.brownMuted)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 32)
        }
    }
}

struct CapturePhotoView: View {
    @ObservedObject var state: SessionPOCState
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Add a visual anchor")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)

                if let img = state.capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BrandTheme.gold.opacity(0.4), lineWidth: 1))
                } else {
                    BrandCard {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundStyle(BrandTheme.goldDeep)
                            Text("No image yet")
                                .foregroundStyle(BrandTheme.brownMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
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

                PrimaryButton(title: "Use this moment") {
                    state.beginSession()
                    state.phase = .processing
                }
                SecondaryButton(title: "Back") { state.phase = .captureHome }
            }
            .padding(24)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $state.capturedImage)
                .ignoresSafeArea()
        }
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
