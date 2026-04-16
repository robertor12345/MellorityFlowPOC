import SwiftUI

enum ConnectedDeviceCategory: String, Identifiable, CaseIterable {
    case health
    case iot
    case personalisation
    case snippets
    case replay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health: return "Health & wearables"
        case .iot: return "Home lighting"
        case .personalisation: return "Personalisation"
        case .snippets: return "Snippets + memory"
        case .replay: return "Replay your calm"
        }
    }

    var symbol: String {
        switch self {
        case .health: return "heart.fill"
        case .iot: return "lightbulb.led.fill"
        case .personalisation: return "slider.horizontal.3"
        case .snippets: return "bookmark.fill"
        case .replay: return "play.circle.fill"
        }
    }
}

// MARK: - Sheet host (per-category settings)

struct ConnectedDeviceConfigSheet: View {
    let category: ConnectedDeviceCategory
    @ObservedObject var state: SessionPOCState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BrandBackground()
                .ignoresSafeArea()

            CenteredScrollScreen {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        Button("Done") { dismiss() }
                            .font(BrandTheme.buttonLabel(.subheadline))
                            .foregroundStyle(BrandTheme.brownMuted)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: category.symbol)
                            .font(.title)
                            .foregroundStyle(BrandTheme.goldDeep)
                        Text(category.title)
                            .font(BrandTheme.title(.title2))
                            .foregroundStyle(BrandTheme.brown)
                    }

                    Group {
                        switch category {
                        case .health:
                            healthContent
                        case .iot:
                            iotContent
                        case .personalisation:
                            personalisationContent
                        case .snippets:
                            snippetsContent
                        case .replay:
                            replayContent
                        }
                    }

                    Text("Settings apply when sync and integrations are available in the app.")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(22)
    }

    // MARK: Health

    private var healthContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable health sync", isOn: $state.wantsHealthSync)
                .tint(BrandTheme.goldDeep)

            VStack(alignment: .leading, spacing: 6) {
                Text("Preferred source")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.brownMuted)
                Picker("Provider", selection: $state.healthPreferredProvider) {
                    ForEach(SessionPOCState.HealthDataProvider.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BrandTheme.creamMid.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            }

            Toggle("Share heart rate during sessions", isOn: $state.healthShareHeartRate)
                .tint(BrandTheme.goldDeep)
            Toggle("Share resting heart rate", isOn: $state.healthShareRestingHR)
                .tint(BrandTheme.goldDeep)
            Toggle("Share sleep stages", isOn: $state.healthShareSleepStages)
                .tint(BrandTheme.goldDeep)
            Toggle("Share activity summaries", isOn: $state.healthShareActivity)
                .tint(BrandTheme.goldDeep)
        }
    }

    // MARK: IoT

    private var iotContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable home lighting", isOn: $state.wantsIoT)
                .tint(BrandTheme.goldDeep)

            Toggle("Philips Hue bridge", isOn: $state.iotPhilipsHueEnabled)
                .tint(BrandTheme.goldDeep)
            Toggle("Apple HomeKit", isOn: $state.iotHomeKitEnabled)
                .tint(BrandTheme.goldDeep)
            Toggle("Matter devices", isOn: $state.iotMatterEnabled)
                .tint(BrandTheme.goldDeep)
            Toggle("Follow session breathing (dim / warmth)", isOn: $state.iotFollowSessionBreath)
                .tint(BrandTheme.goldDeep)

            VStack(alignment: .leading, spacing: 8) {
                Text("Max scene brightness")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.brownMuted)
                HStack {
                    Text("Soft")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted)
                    Slider(value: $state.iotMaxSceneBrightness, in: 0.35 ... 1)
                        .tint(BrandTheme.goldDeep)
                    Text("Bright")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted)
                }
                Text("\(Int(state.iotMaxSceneBrightness * 100))% cap")
                    .font(.caption2)
                    .foregroundStyle(BrandTheme.brownMuted)
            }
        }
    }

    // MARK: Personalisation

    private var personalisationContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable personalisation", isOn: $state.wantsPersonalisation)
                .tint(BrandTheme.goldDeep)

            Toggle("Remember taste across sessions", isOn: $state.personalisationSessionMemory)
                .tint(BrandTheme.goldDeep)
            Toggle("Prefer gentle session starts", isOn: $state.personalisationPreferGentleStarts)
                .tint(BrandTheme.goldDeep)

            VStack(alignment: .leading, spacing: 8) {
                Text("How quickly Mellority adapts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.brownMuted)
                HStack {
                    Text("Gradual")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted)
                    Slider(value: $state.personalisationAdaptationSpeed, in: 0.15 ... 1)
                        .tint(BrandTheme.goldDeep)
                    Text("Fast")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted)
                }
            }
        }
    }

    // MARK: Snippets

    private var snippetsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable snippets + memory", isOn: $state.wantsSnippetsMemory)
                .tint(BrandTheme.goldDeep)

            Toggle("Auto-capture session peaks", isOn: $state.snippetsAutoCapturePeaks)
                .tint(BrandTheme.goldDeep)
            Toggle("Export journal as Markdown", isOn: $state.snippetsExportMarkdown)
                .tint(BrandTheme.goldDeep)

            VStack(alignment: .leading, spacing: 6) {
                Text("Keep highlights for")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.brownMuted)
                Picker("Retention", selection: $state.snippetsKeepDays) {
                    ForEach(SessionPOCState.SnippetRetention.allCases) { d in
                        Text(d.label).tag(d)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: Replay

    private var replayContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable replay after sessions", isOn: $state.wantsReplayCalm)
                .tint(BrandTheme.goldDeep)

            Toggle("Offer replay from insight screen", isOn: $state.replayOfferOnInsight)
                .tint(BrandTheme.goldDeep)
            Toggle("Restore original audio level", isOn: $state.replayRestoreVolume)
                .tint(BrandTheme.goldDeep)
            Toggle("Show heart rate & calm overlay", isOn: $state.replayShowMetricsOverlay)
                .tint(BrandTheme.goldDeep)

            if state.replayExperienceAvailable {
                BrandCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last captured session")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.brown)
                        if let mood = state.replayMoodSnapshot {
                            Text("Mood: \(mood)")
                                .font(.caption)
                                .foregroundStyle(BrandTheme.brownMuted)
                        }
                        Text("Calm \(state.replayCalmPercentSnapshot)% · HR \(state.replayHeartRateSnapshot) — used for replay overlay.")
                            .font(.caption2)
                            .foregroundStyle(BrandTheme.brownMuted)
                    }
                }
            }
        }
    }
}
