import SwiftUI

struct FlowRootView: View {
    @StateObject private var state = SessionPOCState()

    var body: some View {
        ZStack {
            BrandBackground()
            Group {
                switch state.phase {
                case .home:
                    HomeView(state: state)
                case .entryMode:
                    EntryModeView(state: state)
                case .captureMoment:
                    CapturePhotoView(state: state)
                case .moodSelect:
                    MoodSelectView(state: state)
                case .processingFast:
                    ProcessingFastView(state: state)
                case .immersive:
                    ImmersiveSessionView(state: state)
                case .insight:
                    InsightView(state: state)
                case .unlockFeatures:
                    UnlockFeaturesView(state: state)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .animation(.easeInOut(duration: 0.35), value: state.phase)
    }
}

struct BrandBackground: View {
    var body: some View {
        ZStack {
            BrandTheme.backgroundGradient
                .ignoresSafeArea()
            RadialGradient(
                colors: [BrandTheme.goldSoft.opacity(0.15), Color.clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

struct BrandCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(BrandTheme.cream.opacity(0.94))
                    .shadow(color: BrandTheme.brown.opacity(0.08), radius: 12, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
            )
    }
}

struct PrimaryButton: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTheme.buttonLabel(.headline))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [BrandTheme.goldSoft, BrandTheme.gold, BrandTheme.goldDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(BrandTheme.brown)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTheme.buttonLabel(.subheadline))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(BrandTheme.cream.opacity(0.6))
                .foregroundStyle(BrandTheme.brown)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(BrandTheme.gold.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
