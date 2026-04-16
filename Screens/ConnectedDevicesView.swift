import SwiftUI

/// Signed-in home: integrations hub with per-category configuration.
struct ConnectedDevicesView: View {
    @ObservedObject var state: SessionPOCState
    @State private var openConfig: ConnectedDeviceCategory?

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 18) {
                    FadeInTitle(text: "Connected devices", delay: 0)
                    FadeInLine(
                        text: "Choose what Mellority can use. Open a category to fine-tune sources and behaviour.",
                        font: .subheadline,
                        color: BrandTheme.brownMuted,
                        delay: 0.06
                    )

                    VStack(spacing: 12) {
                        ForEach(ConnectedDeviceCategory.allCases) { cat in
                            deviceRow(category: cat)
                        }
                    }
                    .padding(.horizontal, 2)

                    PrimaryButton(title: "Back to home") {
                        state.phase = .home
                    }
                }
                .padding(24)
            }
        }
        .sheet(item: $openConfig) { cat in
            ConnectedDeviceConfigSheet(category: cat, state: state)
        }
    }

    private func deviceRow(category: ConnectedDeviceCategory) -> some View {
        let on = isCategoryEnabled(category)
        return Button {
            openConfig = category
        } label: {
            BrandCard {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: category.symbol)
                        .font(.title2)
                        .foregroundStyle(BrandTheme.goldDeep)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.brown)
                        Text(subtitle(for: category))
                            .font(.caption)
                            .foregroundStyle(BrandTheme.brownMuted)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    Text(on ? "On" : "Off")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(on ? BrandTheme.goldDeep : BrandTheme.brownMuted)
                        .frame(minWidth: 36, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandTheme.gold.opacity(0.75))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func isCategoryEnabled(_ c: ConnectedDeviceCategory) -> Bool {
        switch c {
        case .health: return state.wantsHealthSync
        case .iot: return state.wantsIoT
        case .personalisation: return state.wantsPersonalisation
        case .snippets: return state.wantsSnippetsMemory
        case .replay: return state.wantsReplayCalm
        }
    }

    private func subtitle(for c: ConnectedDeviceCategory) -> String {
        switch c {
        case .health:
            return "Wearables, heart rate, sleep — \(state.healthPreferredProvider.rawValue)"
        case .iot:
            return "Hue, HomeKit, Matter — scenes follow your session"
        case .personalisation:
            return "How quickly sound and visuals learn your taste"
        case .snippets:
            return "Highlights & memory — \(state.snippetsKeepDays.label.lowercased()) retention"
        case .replay:
            return "Replay visuals & audio from your last session"
        }
    }

}
