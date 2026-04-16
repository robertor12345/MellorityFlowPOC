import SwiftUI

/// Signed-in home: overview of integrations (mirrors post–sign-in preferences).
struct ConnectedDevicesView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 22) {
                    FadeInTitle(text: "Connected devices", delay: 0)
                    FadeInLine(
                        text: "What you’ve chosen to link with Mellority — change anytime after sync is available.",
                        font: .subheadline,
                        color: BrandTheme.brownMuted,
                        delay: 0.08
                    )

                    deviceRow(
                        title: "Health & wearables",
                        subtitle: "Heart rate, sleep, recovery",
                        on: state.wantsHealthSync,
                        systemImage: "heart.fill"
                    )
                    deviceRow(
                        title: "Home lighting",
                        subtitle: "Hue, HomeKit, similar bridges",
                        on: state.wantsIoT,
                        systemImage: "lightbulb.led.fill"
                    )
                    deviceRow(
                        title: "Personalisation profile",
                        subtitle: "Taste and timing",
                        on: state.wantsPersonalisation,
                        systemImage: "slider.horizontal.3"
                    )
                    deviceRow(
                        title: "Snippets + memory",
                        subtitle: "Session highlights",
                        on: state.wantsSnippetsMemory,
                        systemImage: "bookmark.fill"
                    )
                    deviceRow(
                        title: "Replay your calm",
                        subtitle: "Saved tones and moments",
                        on: state.wantsReplayCalm,
                        systemImage: "play.circle.fill"
                    )

                    PrimaryButton(title: "Back to home") {
                        state.phase = .home
                    }
                }
                .padding(24)
            }
        }
    }

    private func deviceRow(
        title: String,
        subtitle: String,
        on: Bool,
        systemImage: String
    ) -> some View {
        BrandCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(BrandTheme.goldDeep)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.brown)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(BrandTheme.brownMuted)
                }
                Spacer(minLength: 0)
                Text(on ? "On" : "Off")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(on ? BrandTheme.goldDeep : BrandTheme.brownMuted)
            }
        }
    }
}
