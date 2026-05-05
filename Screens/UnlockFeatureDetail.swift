import SwiftUI

/// Sheet content for a row on **Unlock Deeper Features** (tap row to open).
enum UnlockFeaturePanel: String, Identifiable {
    case health
    case iot
    case personalisation
    case snippets
    case replayCalm

    var id: String { rawValue }

    init?(stockId: String) {
        switch stockId {
        case "health": self = .health
        case "iot": self = .iot
        case "personalisation": self = .personalisation
        case "snippetsMemory": self = .snippets
        case "replayCalm": self = .replayCalm
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .health: return "Health sync"
        case .iot: return "IoT & space"
        case .personalisation: return "Personalisation"
        case .snippets: return "Snippets + memory"
        case .replayCalm: return "Replay your calm"
        }
    }

    var detail: String {
        switch self {
        case .health:
            return "Wearables can share heart rate, sleep, and recovery so sessions ease up when you’re wiped and steady when you’re not."
        case .iot:
            return "Lights like Hue or HomeKit can warm, dim, and drift with your breath — less fumbling for switches mid-session."
        case .personalisation:
            return "Mellority notices what you actually return to — pacing, layers, visuals — and stops guessing wrong over time."
        case .snippets:
            return "Clip the moments that mattered — a texture, a phrase, a stillness — and keep a gentle log of what held you."
        case .replayCalm:
            return "Reopen a tone or stretch that worked before — like walking back into a room that still feels safe."
        }
    }
}

struct UnlockFeatureDetailSheet: View {
    let panel: UnlockFeaturePanel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BrandBackground()
                .ignoresSafeArea()

            CenteredScrollScreen {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(BrandTheme.buttonLabel(.subheadline))
                            .foregroundStyle(BrandTheme.brownMuted)
                    }

                    ConnectedFeatureHeroImage(
                        stock: stock(for: panel),
                        height: 180
                    )
                    .padding(.horizontal, 4)

                    Text(panel.title)
                        .font(BrandTheme.title(.title2))
                        .foregroundStyle(BrandTheme.brown)
                        .multilineTextAlignment(.center)

                    Text(panel.detail)
                        .font(.body)
                        .foregroundStyle(BrandTheme.brownMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(22)
    }

    private func stock(for panel: UnlockFeaturePanel) -> ConnectedFeatureStock {
        switch panel {
        case .health: return .health
        case .iot: return .iot
        case .personalisation: return .personalisation
        case .snippets: return .snippetsMemory
        case .replayCalm: return .replayCalm
        }
    }
}
