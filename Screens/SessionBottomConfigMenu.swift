import SwiftUI
import UIKit

/// Unobtrusive collapsed bar at the bottom of the immersive session; expands for home lighting + share.
struct SessionBottomConfigMenu: View {
    @ObservedObject var state: SessionPOCState
    @State private var expanded = false
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                    Text(expanded ? "Hide" : "Session options")
                        .font(.caption.weight(.semibold))
                    Image(systemName: expanded ? "chevron.compact.down" : "chevron.compact.up")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(BrandTheme.brown.opacity(0.95))
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(expanded ? "Collapse session options" : "Expand session options")

            if expanded {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $state.sessionHomeLightsSyncEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            Label("Home lighting", systemImage: "lightbulb.led.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BrandTheme.brown)
                            Text("Sync calm scenes to your lights — Philips Hue, HomeKit, and compatible bridges.")
                                .font(.caption2)
                                .foregroundStyle(BrandTheme.brownMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(BrandTheme.goldDeep)

                    Button {
                        showShareSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.title3)
                                .foregroundStyle(BrandTheme.goldDeep)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Share visuals")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brown)
                                Text("Post your session look to social apps (uses system share sheet).")
                                    .font(.caption2)
                                    .foregroundStyle(BrandTheme.brownMuted)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(BrandTheme.cream.opacity(0.92))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(BrandTheme.gold.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(BrandTheme.gold.opacity(0.22), lineWidth: 1)
                )
                .padding(.top, 10)
                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(activityItems: shareItems)
        }
    }

    private var shareItems: [Any] {
        let mood = state.selectedMood ?? "Calm"
        let text = "My Mellority calm session — mood: \(mood)."
        return [text]
    }
}

// MARK: - UIKit share sheet

private struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
