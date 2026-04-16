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
            return "Connect wearables so Mellority can use heart rate, sleep, and recovery to gently tune sessions — softer when you’re depleted, steadier when you’re ready to focus."
        case .iot:
            return "Link lights such as Philips Hue or HomeKit scenes so colour and dimming can follow your breath and the arc of the session — warm shifts without you reaching for a switch."
        case .personalisation:
            return "Your preferences and timing refine over replays: sound layers, pacing, and visuals converge on what actually lands for you, faster each time you return."
        case .snippets:
            return "Save short peaks from a session — a phrase, texture, or stillness you want to remember — and build a light-touch journal of what grounded you."
        case .replayCalm:
            return "Return to a saved tone, loop, or moment whenever you need it — a calm you can reopen like a favourite room."
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
