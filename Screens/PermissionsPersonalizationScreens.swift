import SwiftUI

// MARK: - Permissions (mock toggles; real requests in production)

struct PermissionsView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Personalise your experience")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)
                Text("Grant access so Mellority can adapt sessions. Toggles are simulated in this POC.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.brownMuted)

                permissionRow(
                    title: "Health & fitness",
                    subtitle: "Heart rate, sleep, mindfulness apps",
                    isOn: $state.healthGranted,
                    icon: "heart.text.square.fill"
                )
                permissionRow(
                    title: "Camera",
                    subtitle: "Capture your environment for visual context",
                    isOn: $state.cameraGranted,
                    icon: "camera.fill"
                )
                permissionRow(
                    title: "Microphone",
                    subtitle: "Spatial audio & session capture",
                    isOn: $state.audioGranted,
                    icon: "mic.fill"
                )
                permissionRow(
                    title: "Smart home (optional)",
                    subtitle: "Philips Hue and similar — lighting sync",
                    isOn: $state.iotGranted,
                    icon: "house.fill"
                )

                PrimaryButton(title: "Continue") {
                    state.phase = .personalization
                }
                SecondaryButton(title: "Skip for now") {
                    state.phase = .personalization
                }
            }
            .padding(24)
        }
    }

    private func permissionRow(title: String, subtitle: String, isOn: Binding<Bool>, icon: String) -> some View {
        BrandCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(BrandTheme.goldDeep)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.brown)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(BrandTheme.brownMuted)
                }
                Spacer()
                Toggle("", isOn: isOn)
                    .tint(BrandTheme.gold)
            }
        }
    }
}

// MARK: - 2. Personalisation

struct PersonalizationView: View {
    @ObservedObject var state: SessionPOCState

    private let moods = ["Relaxation", "Focus", "Sleep", "Stress relief"]
    private let genreOptions = ["Ambient", "Classical", "Nature", "Electronic (soft)", "Jazz"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What do you need today?")
                    .font(BrandTheme.title(.title))
                    .foregroundStyle(BrandTheme.brown)

                Text("Mood goals")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.brown)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(moods, id: \.self) { m in
                        chip(m, selected: state.moodGoals.contains(m)) {
                            if state.moodGoals.contains(m) { state.moodGoals.remove(m) }
                            else { state.moodGoals.insert(m) }
                        }
                    }
                }

                Text("Music preferences")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.brown)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(genreOptions, id: \.self) { g in
                        chip(g, selected: state.genres.contains(g)) {
                            if state.genres.contains(g) { state.genres.remove(g) }
                            else { state.genres.insert(g) }
                        }
                    }
                }

                Text("Tempo")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.brown)
                Picker("Tempo", selection: $state.tempo) {
                    Text("Very slow").tag("Very slow")
                    Text("Slow").tag("Slow")
                    Text("Moderate").tag("Moderate")
                }
                .pickerStyle(.segmented)
                .tint(BrandTheme.goldDeep)

                Text("Connect sources")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.brown)
                toggleRow("Fitness trackers", $state.connectFitness)
                toggleRow("Mindfulness apps", $state.connectMindfulness)
                toggleRow("Smart home", $state.connectSmartHome)

                PrimaryButton(title: "Save & continue") {
                    state.phase = .captureHome
                }
            }
            .padding(24)
        }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? BrandTheme.goldSoft.opacity(0.7) : BrandTheme.cream.opacity(0.8))
                .foregroundStyle(BrandTheme.brown)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(BrandTheme.gold.opacity(selected ? 0.9 : 0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, _ binding: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(BrandTheme.brown)
            Spacer()
            Toggle("", isOn: binding).tint(BrandTheme.gold)
        }
        .padding(.vertical, 4)
    }
}
