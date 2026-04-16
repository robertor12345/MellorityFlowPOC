import SwiftUI

/// After sign-in: pager on extra integrations — connect or skip each, or skip everything.
struct PostSignInIntegrationSlidesView: View {
    @ObservedObject var state: SessionPOCState
    @State private var page = 0

    var body: some View {
        ScreenFadeIn {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip all") {
                        state.exitPostSignInSlidesToHome()
                    }
                    .font(BrandTheme.buttonLabel(.subheadline))
                    .foregroundStyle(BrandTheme.brownMuted)
                    .padding(.trailing, 8)
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)

                TabView(selection: $page) {
                    featurePage(
                        index: 0,
                        stock: .health,
                        title: "Health sync",
                        detail:
                            "Connect wearables so sessions can respond to heart rate, rest, and recovery."
                    ) { state.wantsHealthSync = true }
                    featurePage(
                        index: 1,
                        stock: .iot,
                        title: "IoT & space",
                        detail:
                            "Pair lighting like Philips Hue so scenes can follow your session — warm dim for calm, soft shifts with breath."
                    ) { state.wantsIoT = true }
                    featurePage(
                        index: 2,
                        stock: .personalisation,
                        title: "Personalisation",
                        detail:
                            "Your taste and timing refine over time so sound and visuals match you faster."
                    ) { state.wantsPersonalisation = true }
                    featurePage(
                        index: 3,
                        stock: .snippetsMemory,
                        title: "Snippets + memory",
                        detail:
                            "Save short peaks from sessions and build a gentle memory of what grounded you."
                    ) { state.wantsSnippetsMemory = true }
                    featurePage(
                        index: 4,
                        stock: .replayCalm,
                        title: "Replay your calm",
                        detail: "Return to a saved tone or moment — a calm you can revisit."
                    ) { state.wantsReplayCalm = true }
                    summaryPage(index: 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.easeInOut(duration: 0.3), value: page)
            }
        }
    }

    @ViewBuilder
    private func featurePage(
        index: Int,
        stock: ConnectedFeatureStock,
        title: String,
        detail: String,
        onConnect: @escaping () -> Void
    ) -> some View {
        CenteredScrollScreen {
            VStack(spacing: 22) {
                Text(title)
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)
                    .multilineTextAlignment(.center)

                ConnectedFeatureHeroImage(stock: stock)

                Text(detail)
                    .font(.body)
                    .foregroundStyle(BrandTheme.brownMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                VStack(spacing: 12) {
                    PrimaryButton(title: "Connect") {
                        onConnect()
                        advanceFrom(index)
                    }
                    SecondaryButton(title: "Skip this one") {
                        advanceFrom(index)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .padding(.vertical, 16)
        }
        .tag(index)
    }

    private func summaryPage(index: Int) -> some View {
        CenteredScrollScreen {
            VStack(spacing: 20) {
                FadeInTitle(text: "You’re set", delay: 0)
                FadeInLine(
                    text: "We’ll honour these choices. You can change them anytime.",
                    delay: 0.08
                )

                BrandCard {
                    VStack(alignment: .leading, spacing: 8) {
                        summaryPreferenceRow("Health", state.wantsHealthSync)
                        summaryPreferenceRow("IoT", state.wantsIoT)
                        summaryPreferenceRow("Personalisation", state.wantsPersonalisation)
                        summaryPreferenceRow("Snippets + memory", state.wantsSnippetsMemory)
                        summaryPreferenceRow("Replay your calm", state.wantsReplayCalm)
                    }
                }
                .padding(.horizontal, 8)

                PrimaryButton(title: "Continue") {
                    state.exitPostSignInSlidesToHome()
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
        }
        .tag(index)
    }

    private func summaryPreferenceRow(_ label: String, _ on: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.brownMuted)
            Spacer()
            Text(on ? "Interested" : "Skipped")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(on ? BrandTheme.goldDeep : BrandTheme.brownMuted)
        }
    }

    /// Advance to next feature slide, or to the summary after the last feature (index 4 → 5).
    private func advanceFrom(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.28)) {
            if index < 4 {
                page = index + 1
            } else {
                page = 5
            }
        }
    }
}
