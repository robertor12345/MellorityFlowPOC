import SwiftUI

/// After mock sign-in: short pager on extra integrations — connect (mock opt-in) or skip each, or skip everything.
struct PostSignInIntegrationSlidesView: View {
    @ObservedObject var state: SessionPOCState
    @State private var page = 0

    /// Stock image: Philips Hue hub + colour bulbs — [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Philips_Hue_hub_and_2_bulbs.jpg) (CC BY 2.0, Sho Hashimoto).
    private static let philipsHueStockImageURL = URL(
        string: "https://upload.wikimedia.org/wikipedia/commons/8/84/Philips_Hue_hub_and_2_bulbs.jpg"
    )!

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
                        icon: "heart.fill",
                        title: "Health sync",
                        detail: "Connect wearables so sessions can respond to heart rate, rest, and recovery — in the full Mellority app."
                    ) { state.wantsHealthSync = true }
                    iotPage()
                    featurePage(
                        index: 2,
                        icon: "slider.horizontal.3",
                        title: "Personalisation",
                        detail: "Your taste and timing refine over time so sound and visuals match you faster."
                    ) { state.wantsPersonalisation = true }
                    featurePage(
                        index: 3,
                        icon: "bookmark.fill",
                        title: "Snippets + memory",
                        detail: "Save short peaks from sessions and build a gentle memory of what grounded you."
                    ) { state.wantsSnippetsMemory = true }
                    featurePage(
                        index: 4,
                        icon: "play.circle.fill",
                        title: "Replay your calm",
                        detail: "Return to a saved tone or moment — a calm you can revisit."
                    ) { state.wantsReplayCalm = true }
                    summaryPage(index: 5)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.easeInOut(duration: 0.3), value: page)
            }
        }
    }

    /// IoT slide with real **Philips Hue** stock imagery (hub + bulbs) and Hue-style pairing copy.
    @ViewBuilder
    private func iotPage() -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 8)

                Text("IoT & space")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)
                    .multilineTextAlignment(.center)

                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: Self.philipsHueStockImageURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(BrandTheme.creamMid)
                                .frame(height: 200)
                                .overlay {
                                    ProgressView()
                                        .tint(BrandTheme.goldDeep)
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(BrandTheme.creamMid)
                                .frame(height: 200)
                                .overlay {
                                    Image(systemName: "lightbulb.led.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(BrandTheme.goldDeep)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1)
                    )

                    Text("Philips Hue")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(BrandTheme.cream)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(10)
                }

                Text("Pair lighting like Philips Hue so scenes can follow your session — warm dim for calm, soft shifts with breath.")
                    .font(.body)
                .foregroundStyle(BrandTheme.brownMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

                Text("Stock photo: Philips Hue hub and bulbs — Wikimedia Commons (CC BY 2.0, Sho Hashimoto). POC only; not affiliated with Signify.")
                    .font(.caption2)
                    .foregroundStyle(BrandTheme.brownMuted.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                Text("POC: taps only save preferences for demo — no real connections yet.")
                    .font(.caption2)
                    .foregroundStyle(BrandTheme.brownMuted.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                VStack(spacing: 12) {
                    PrimaryButton(title: "Connect") {
                        state.wantsIoT = true
                        advanceFrom(1)
                    }
                    SecondaryButton(title: "Skip this one") {
                        advanceFrom(1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)

                Spacer(minLength: 24)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        .tag(1)
    }

    @ViewBuilder
    private func featurePage(
        index: Int,
        icon: String,
        title: String,
        detail: String,
        onConnect: @escaping () -> Void
    ) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 12)

                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrandTheme.goldSoft, BrandTheme.goldDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.bottom, 4)

                Text(title)
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)
                    .multilineTextAlignment(.center)

                Text(detail)
                    .font(.body)
                    .foregroundStyle(BrandTheme.brownMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)

                Text("POC: taps only save preferences for demo — no real connections yet.")
                    .font(.caption2)
                    .foregroundStyle(BrandTheme.brownMuted.opacity(0.9))
                    .multilineTextAlignment(.center)
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

                Spacer(minLength: 24)
            }
            .padding(.vertical, 16)
        }
        .tag(index)
    }

    private func summaryPage(index: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 20)

                FadeInTitle(text: "You’re set", delay: 0)
                FadeInLine(
                    text: "We’ll honour these choices when sync lands. You can change them anytime.",
                    delay: 0.08
                )

                BrandCard {
                    VStack(alignment: .leading, spacing: 8) {
                        mockRow("Health", state.wantsHealthSync)
                        mockRow("IoT", state.wantsIoT)
                        mockRow("Personalisation", state.wantsPersonalisation)
                        mockRow("Snippets + memory", state.wantsSnippetsMemory)
                        mockRow("Replay your calm", state.wantsReplayCalm)
                    }
                }
                .padding(.horizontal, 8)

                PrimaryButton(title: "Continue") {
                    state.exitPostSignInSlidesToHome()
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)

                Spacer(minLength: 32)
            }
            .padding(.vertical, 16)
        }
        .tag(index)
    }

    private func mockRow(_ label: String, _ on: Bool) -> some View {
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
