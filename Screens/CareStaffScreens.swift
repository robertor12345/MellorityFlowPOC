import SwiftUI

// MARK: - Patient roster

struct CarePatientListView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 22) {
                    FadeInTitle(text: "One-to-one calm", delay: 0)
                    FadeInLine(
                        text: "Unhurried moments for people you support — sound, smart lighting, and optional immersive routes (POC mock, not a medical device).",
                        font: .caption,
                        color: BrandTheme.brownMuted,
                        delay: 0.08
                    )

                    ForEach(state.carePatients) { patient in
                        Button {
                            state.selectedCarePatientId = patient.id
                            state.phase = .carePatientDetail
                        } label: {
                            BrandCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(BrandTheme.goldDeep)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(patient.displayName)
                                                .font(BrandTheme.title(.headline))
                                                .foregroundStyle(BrandTheme.brown)
                                            Text(patient.careContextLabel)
                                                .font(.caption)
                                                .foregroundStyle(BrandTheme.brownMuted)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(BrandTheme.gold.opacity(0.8))
                                    }
                                    if let last = state.recordsForPatient(patient.id).first {
                                        Text(lastSessionSummary(last))
                                            .font(.caption2)
                                            .foregroundStyle(BrandTheme.brownMuted)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)

                    SecondaryButton(title: "Back to home") {
                        state.selectedCarePatientId = nil
                        state.phase = .home
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.vertical, 28)
            }
        }
    }

    private func lastSessionSummary(_ last: CareSessionRecord) -> String {
        var parts = ["Last moment", last.moodSummary, "\(last.calmPercent)% ease"]
        if let s = last.settledness {
            parts.append("settled \(s)%")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Environment & IoT prep (lighting, immersive / VR)

struct CareSessionPrepView: View {
    @ObservedObject var state: SessionPOCState

    private let durationChoices = [10, 12, 15, 20, 25]

    private var patient: CarePatientProfile? {
        state.carePatient(id: state.selectedCarePatientId)
    }

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(alignment: .leading, spacing: 20) {
                    FadeInTitle(text: "Link the environment", delay: 0)
                    FadeInLine(
                        text: "Mellority is designed to sit alongside smart homes and immersive hardware — calm scenes on lights, optional breath-sync, and VR or room displays when your home supports them (all POC toggles).",
                        font: .caption,
                        color: BrandTheme.brownMuted,
                        delay: 0.06
                    )

                    if let patient {
                        BrandCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("With \(patient.displayName)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brown)
                                Text("Light: \(patient.preferredLight)")
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Text("Scent: \(patient.scentGuidance)")
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Text("Touch: \(patient.touchComfortNotes)")
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brownMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)
                    }

                    Text("Smart lighting")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandTheme.brown)
                        .padding(.horizontal, 4)

                    BrandCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Pair bridges so a calm scene can run with the session — warm dim, slow fades, no harsh snaps.")
                                .font(.caption)
                                .foregroundStyle(BrandTheme.brownMuted)
                            iotToggle("Philips Hue scenes", isOn: $state.iotPhilipsHueEnabled)
                            iotToggle("Apple HomeKit rooms", isOn: $state.iotHomeKitEnabled)
                            iotToggle("Matter accessories", isOn: $state.iotMatterEnabled)
                            Divider().opacity(0.35)
                            iotToggle("Let gentle light pulses follow the breath pacing", isOn: $state.iotFollowSessionBreath)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Max scene brightness cap")
                                        .font(.caption)
                                        .foregroundStyle(BrandTheme.brown)
                                    Spacer()
                                    Text("\(Int((state.iotMaxSceneBrightness * 100).rounded()))%")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(BrandTheme.brownMuted)
                                }
                                Slider(value: $state.iotMaxSceneBrightness, in: 0.15 ... 1)
                                    .tint(BrandTheme.goldDeep)
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 4)

                    Text("Immersive & VR")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandTheme.brown)
                        .padding(.horizontal, 4)

                    BrandCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(
                                "Headsets (for example pass-through VR) or fixed room displays can carry the same nature-led calm with staff beside the person. Production would use your governance, consent, and infection-control policy."
                            )
                            .font(.caption)
                            .foregroundStyle(BrandTheme.brownMuted)
                            iotToggle(
                                "This moment: VR / headset-calibrated route (when integrated)",
                                isOn: $state.carePrepVRImmersiveRoute
                            )
                            iotToggle(
                                "Mirror visuals to wall / TV / bedside panel",
                                isOn: $state.carePrepRoomDisplayMirroring
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Planned unhurried length")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.brown)
                        Picker("Minutes", selection: $state.carePlannedDurationMinutes) {
                            ForEach(durationChoices, id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("A soft guide — end early anytime. IoT scenes can wind down with the closing breath.")
                            .font(.caption2)
                            .foregroundStyle(BrandTheme.brownMuted)
                    }
                    .padding(.horizontal, 4)

                    Text("POC wellness companion — not clinical advice or a medical device. Device names are examples only.")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted.opacity(0.9))
                        .padding(.horizontal, 4)

                    PrimaryButton(title: "Continue to photo or quick calm") {
                        state.continueCareSessionFromPrep()
                    }
                    .padding(.horizontal, 24)

                    SecondaryButton(title: "Back to profile") {
                        state.phase = .carePatientDetail
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 28)
            }
        }
    }

    private func iotToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.brown)
                .multilineTextAlignment(.leading)
        }
        .tint(BrandTheme.goldDeep)
    }
}

// MARK: - Patient detail

struct CarePatientDetailView: View {
    @ObservedObject var state: SessionPOCState

    private var patient: CarePatientProfile? {
        state.carePatient(id: state.selectedCarePatientId)
    }

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 20) {
                    if let patient {
                        FadeInTitle(text: patient.displayName, delay: 0)
                        FadeInLine(text: patient.careContextLabel, font: .subheadline, delay: 0.06)

                        BrandCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Comfort & senses")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Text("Light")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Text(patient.preferredLight)
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brown)
                                Text("Scent")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                    .padding(.top, 4)
                                Text(patient.scentGuidance)
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brown)
                                Text("Touch")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                    .padding(.top, 4)
                                Text(patient.touchComfortNotes)
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brown)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

                        BrandCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Life themes / reminiscence anchors")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                                    ForEach(patient.comfortThemes, id: \.self) { theme in
                                        Text(theme)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(BrandTheme.brown)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(BrandTheme.creamDeep.opacity(0.85)))
                                            .overlay(
                                                Capsule().stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
                                            )
                                    }
                                }
                                if patient.prefersGentleSoundOnsets {
                                    Text("Sound: prefer very gentle onsets — avoid abrupt changes.")
                                        .font(.caption2)
                                        .foregroundStyle(BrandTheme.brownMuted)
                                        .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

                        BrandCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Likes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                                    ForEach(patient.likes, id: \.self) { tag in
                                        tagPill(tag, positive: true)
                                    }
                                }
                                Text("Dislikes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                    .padding(.top, 4)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                                    ForEach(patient.dislikes, id: \.self) { tag in
                                        tagPill(tag, positive: false)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

                        BrandCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Sound shaping for next visit (mock)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                meterRow("Tempo — gentler ↔ slightly brighter", value: patient.musicTempoBias)
                                meterRow("Nature ↔ abstract", value: patient.natureVsAbstract)
                                meterRow("Instrumental ↔ voice", value: patient.voiceVsInstrumental)
                                Text("After each moment together, you can note how they responded and adjust these for the next calm block.")
                                    .font(.caption2)
                                    .foregroundStyle(BrandTheme.brownMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Previous sessions")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BrandTheme.brown)
                                .padding(.horizontal, 4)

                            let rows = state.recordsForPatient(patient.id)
                            if rows.isEmpty {
                                Text("No records yet.")
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                    .padding(.horizontal, 8)
                            } else {
                                ForEach(rows) { rec in
                                    BrandCard {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(rec.date, style: .date)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(BrandTheme.brownMuted)
                                                Spacer()
                                                Text("\(rec.calmPercent)% calm")
                                                    .font(.caption.weight(.medium))
                                                    .foregroundStyle(BrandTheme.goldDeep)
                                            }
                                            Text("Mood tags: \(rec.moodSummary)")
                                                .font(.subheadline)
                                                .foregroundStyle(BrandTheme.brown)
                                            if let line = outcomeLine(rec) {
                                                Text(line)
                                                    .font(.caption)
                                                    .foregroundStyle(BrandTheme.brownMuted)
                                            }
                                            if let note = rec.staffNote, !note.isEmpty {
                                                Text(note)
                                                    .font(.caption)
                                                    .foregroundStyle(BrandTheme.brownMuted)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        PrimaryButton(title: "Lighting, VR & session setup") {
                            state.openCareSessionPrep()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    } else {
                        FadeInLine(text: "No patient selected.", delay: 0)
                    }

                    SecondaryButton(title: "Back to roster") {
                        state.selectedCarePatientId = nil
                        state.phase = .carePatientList
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 28)
            }
        }
    }

    private func tagPill(_ text: String, positive: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(BrandTheme.brown)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(positive ? BrandTheme.goldSoft.opacity(0.45) : BrandTheme.creamDeep.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(BrandTheme.gold.opacity(positive ? 0.35 : 0.18), lineWidth: 1)
            )
    }

    private func meterRow(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(BrandTheme.brown)
                Spacer()
                Text("\(Int((value * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(BrandTheme.brownMuted)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(BrandTheme.brown.opacity(0.1))
                    Capsule()
                        .fill(BrandTheme.gold.opacity(0.85))
                        .frame(width: max(4, g.size.width * CGFloat(value)))
                }
            }
            .frame(height: 6)
        }
    }

    private func outcomeLine(_ rec: CareSessionRecord) -> String? {
        guard rec.settledness != nil || rec.engagement != nil || rec.comfortTolerance != nil else { return nil }
        var p: [String] = []
        if let s = rec.settledness { p.append("Settled \(s)%") }
        if let e = rec.engagement { p.append("Engaged \(e)%") }
        if let c = rec.comfortTolerance { p.append("Comfort \(c)%") }
        return p.joined(separator: " · ")
    }
}

// MARK: - Post-session feedback & tuning

struct CareSessionFeedbackView: View {
    @ObservedObject var state: SessionPOCState
    @State private var settled: Double = 0.6
    @State private var engagement: Double = 0.55
    @State private var comfort: Double = 0.7
    @State private var tempo: Double = 0.5
    @State private var nature: Double = 0.5
    @State private var voice: Double = 0.5
    @State private var staffNote = ""

    private var targetPatient: CarePatientProfile? {
        state.carePatient(id: state.activeCarePatientId ?? state.selectedCarePatientId)
    }

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 22) {
                    FadeInTitle(text: "After the calm moment", delay: 0)
                    if let patient = targetPatient {
                        FadeInLine(
                            text: "How did \(patient.displayName) respond? This honours their experience — not a score for staff. Then tune sound for the next visit.",
                            font: .caption,
                            color: BrandTheme.brownMuted,
                            delay: 0.08
                        )

                        BrandCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("In the moment outcomes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                outcomeSlider(
                                    title: "Seemed settled",
                                    caption: "Still distressed or restless  ←  →  More at ease",
                                    value: $settled
                                )
                                outcomeSlider(
                                    title: "Connection / presence",
                                    caption: "Withdrawn or distant  ←  →  With you / engaged",
                                    value: $engagement
                                )
                                outcomeSlider(
                                    title: "Tolerated the experience",
                                    caption: "Struggled or wanted to stop  ←  →  Comfortable throughout",
                                    value: $comfort
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

                        Text("Sound for the next visit")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.brown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)

                        tuningSlider(title: "Tempo — gentler ↔ slightly brighter", value: $tempo)
                        tuningSlider(title: "Nature ↔ abstract", value: $nature)
                        tuningSlider(title: "Instrumental ↔ voice", value: $voice)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your note (optional)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BrandTheme.brownMuted)
                            TextField("What soothed them, light, touch, sound — what to repeat or soften?", text: $staffNote, axis: .vertical)
                                .lineLimit(3 ... 6)
                                .font(.body)
                                .foregroundStyle(BrandTheme.brown)
                                .padding(12)
                                .background(BrandTheme.creamMid.opacity(0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(BrandTheme.gold.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 4)

                        PrimaryButton(title: "Save note, outcomes & sound") {
                            state.saveCareFeedback(
                                tempoBias: tempo,
                                natureVsAbstract: nature,
                                voiceVsInstrumental: voice,
                                settledness: Int((settled * 100).rounded()),
                                engagement: Int((engagement * 100).rounded()),
                                comfortTolerance: Int((comfort * 100).rounded()),
                                staffNote: staffNote
                            )
                        }
                        .padding(.horizontal, 24)

                        SecondaryButton(title: "Skip — log session only") {
                            state.skipCareFeedback()
                        }
                        .padding(.horizontal, 24)
                    } else {
                        FadeInLine(text: "Need an active patient to save feedback.", delay: 0)
                        SecondaryButton(title: "Back") { state.phase = .insight }
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 28)
            }
        }
        .onAppear {
            staffNote = ""
            syncFromPatient()
            settled = 0.55
            engagement = 0.55
            comfort = 0.65
        }
    }

    private func syncFromPatient() {
        guard let patient = targetPatient else { return }
        tempo = patient.musicTempoBias
        nature = patient.natureVsAbstract
        voice = patient.voiceVsInstrumental
    }

    private func outcomeSlider(title: String, caption: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BrandTheme.brown)
                Spacer()
                Text("\(Int((value.wrappedValue * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(BrandTheme.brownMuted)
            }
            Text(caption)
                .font(.caption2)
                .foregroundStyle(BrandTheme.brownMuted)
            Slider(value: value, in: 0 ... 1)
                .tint(BrandTheme.goldDeep)
        }
    }

    private func tuningSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.brown)
                Spacer()
                Text("\(Int((value.wrappedValue * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(BrandTheme.brownMuted)
            }
            Slider(value: value, in: 0 ... 1)
                .tint(BrandTheme.goldDeep)
        }
        .padding(.horizontal, 4)
    }
}
