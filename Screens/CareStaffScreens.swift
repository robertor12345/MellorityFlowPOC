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
                        text: "Quiet, unhurried time with someone you care for — sound, lights, optional VR or displays. Not a medical device.",
                        font: .caption,
                        color: BrandTheme.brownMuted,
                        delay: 0.08
                    )

                    PrimaryButton(title: "Face-linked profiles") {
                        state.openFaceLinkedProfilePicker()
                    }
                    .padding(.horizontal, 24)

                    FadeInLine(
                        text: "Starts the resident session (floating instrument symbols); it does not open the staff profile first.",
                        font: .caption2,
                        color: BrandTheme.brownMuted.opacity(0.9),
                        delay: 0.1
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                    ForEach(state.carePatients) { patient in
                        Button {
                            state.selectedCarePatientId = patient.id
                            state.phase = .carePatientDetail
                        } label: {
                            BrandCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(patient.stockPortraitAssetName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 52, height: 52)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1))
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
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fixedSize(horizontal: false, vertical: true)
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
        .onAppear {
            if !state.isSignedIn {
                state.phase = .home
            }
        }
    }

    private func lastSessionSummary(_ last: CareSessionRecord) -> String {
        var parts = ["Last visit", last.moodSummary, "\(last.calmPercent)% at ease"]
        if let s = last.settledness {
            parts.append("settled \(s)%")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Face-linked profile pick (after face enrollment, POC)

struct CareFaceLinkedPickView: View {
    @ObservedObject var state: SessionPOCState

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ScreenFadeIn {
            CenteredScrollScreen {
                VStack(spacing: 20) {
                    FadeInTitle(text: "Who’s with you?", delay: 0)
                    FadeInLine(
                        text: "Profiles here were created when their face was captured on this device. Tap someone to start their session — floating instrument icons tap to play; the playing symbol grows at the centre (no playlist list shown on this surface).",
                        font: .caption,
                        color: BrandTheme.brownMuted,
                        delay: 0.06
                    )

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(state.carePatients) { patient in
                            Button {
                                state.selectCarePatientFromFacePick(patient.id)
                            } label: {
                                faceLinkedCard(patient)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)

                    SecondaryButton(title: "Back to full roster") {
                        state.phase = .carePatientList
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.vertical, 28)
            }
        }
        .onAppear {
            if !state.isSignedIn { state.phase = .home }
        }
    }

    private func faceLinkedCard(_ patient: CarePatientProfile) -> some View {
        VStack(spacing: 10) {
            Image(patient.stockPortraitAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(BrandTheme.gold.opacity(0.45), lineWidth: 2)
                )
                .shadow(color: BrandTheme.brown.opacity(0.12), radius: 8, y: 4)

            VStack(spacing: 2) {
                Text(patient.displayName)
                    .font(BrandTheme.title(.headline))
                    .foregroundStyle(BrandTheme.brown)
                Text(patient.careContextLabel)
                    .font(.caption)
                    .foregroundStyle(BrandTheme.brownMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BrandTheme.cream.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
        )
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
                    VStack(spacing: 12) {
                        FadeInTitle(text: "Room & kit", delay: 0)
                            .frame(maxWidth: .infinity)
                        FadeInLine(
                            text: "If you use smart lights, a headset, or a TV in the room, set that up here so the session matches the space. None of this is required — it’s just so Mellority knows what you have.",
                            font: .caption,
                            color: BrandTheme.brownMuted,
                            delay: 0.06
                        )
                        .frame(maxWidth: .infinity)
                    }

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
                            Text("Pair a bridge if you have one — then a calm scene can drift with the session: warmer dim, slow fades, no sudden bright flashes.")
                                .font(.caption)
                                .foregroundStyle(BrandTheme.brownMuted)
                            iotToggle("Philips Hue scenes", isOn: $state.iotPhilipsHueEnabled)
                            iotToggle("Apple HomeKit rooms", isOn: $state.iotHomeKitEnabled)
                            iotToggle("Matter accessories", isOn: $state.iotMatterEnabled)
                            Divider().opacity(0.35)
                            iotToggle("Soft light pulses with the breathing pace", isOn: $state.iotFollowSessionBreath)
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
                                "Some teams use a headset or a wall screen for nature-led calm, with you right beside the person. In a real setting, consent, policy, and infection control come first — this is just the rehearsal."
                            )
                            .font(.caption)
                            .foregroundStyle(BrandTheme.brownMuted)
                            iotToggle(
                                "VR / headset path (when your kit supports it)",
                                isOn: $state.carePrepVRImmersiveRoute
                            )
                            iotToggle(
                                "Also show on wall, TV, or bedside screen",
                                isOn: $state.carePrepRoomDisplayMirroring
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rough length")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.brown)
                        Picker("Minutes", selection: $state.carePlannedDurationMinutes) {
                            ForEach(durationChoices, id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("Only a guide — stop whenever it feels right. Lights can ease down with the closing breath.")
                            .font(.caption2)
                            .foregroundStyle(BrandTheme.brownMuted)
                    }
                    .padding(.horizontal, 4)

                    Text("Wellness support only — not clinical advice or a medical device. Device names here are examples.")
                        .font(.caption2)
                        .foregroundStyle(BrandTheme.brownMuted.opacity(0.9))
                        .padding(.horizontal, 4)

                    PrimaryButton(title: "Continue — photo or quick session") {
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

                        Image(patient.stockPortraitAssetName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(BrandTheme.gold.opacity(0.42), lineWidth: 2))
                            .shadow(color: BrandTheme.brown.opacity(0.12), radius: 10, y: 4)

                        genrePlaylistsCard(patient)

                        BrandCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Resident session (handoff)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Stepper(value: Binding(
                                    get: { patient.residentAgeYears },
                                    set: { state.setResidentAge(for: patient.id, age: $0) }
                                ), in: 55 ... 105) {
                                    Text("Approx. age: \(patient.residentAgeYears)")
                                        .font(.subheadline)
                                        .foregroundStyle(BrandTheme.brown)
                                }
                                Text("Music and playlists are chosen on the resident surface — not edited here.")
                                    .font(.caption2)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                PrimaryButton(title: "Open resident calm surface") {
                                    state.openResidentProfile()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

                        BrandCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Listening discovery")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                Text("Up to six calm clips (about 30 seconds each, unless they tap sooner). Tap the traffic-light faces (red unhappy → green happy) to match each sound — each tap completes that clip and starts the next. If they listen without tapping, we move on when the slice ends using a neutral default. When the pass ends, we reshuffle playlist genres/stubs from those picks, open their calm sandbox, and surface more instrument glyphs when discovery finds gaps.")
                                    .font(.caption2)
                                    .foregroundStyle(BrandTheme.brownMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                SecondaryButton(title: "Start discovery pass") {
                                    state.startDiscoveryCalibration(for: patient.id)
                                }
                                if let line = discoveryRunSummary(for: patient.id, state: state) {
                                    Text(line)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(BrandTheme.brown)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.top, 6)
                                        .accessibilityLabel(line)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

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
                                Text("Themes that help them land")
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
                                    Text("Sound: very gentle starts — no sudden jumps.")
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
                                Text("For next time")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                meterRow("Tempo — gentler ↔ slightly brighter", value: patient.musicTempoBias)
                                meterRow("Nature ↔ abstract", value: patient.natureVsAbstract)
                                meterRow("Instrumental ↔ voice", value: patient.voiceVsInstrumental)
                                Text("After you’re together, note how they responded — these sliders help the next visit land softly.")
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
                                Text("Nothing here yet.")
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
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                            if let line = outcomeLine(rec) {
                                                Text(line)
                                                    .font(.caption)
                                                    .foregroundStyle(BrandTheme.brownMuted)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            if let note = rec.staffNote, !note.isEmpty {
                                                Text(note)
                                                    .font(.caption)
                                                    .foregroundStyle(BrandTheme.brownMuted)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        PrimaryButton(title: "Lights, headset & timing") {
                            state.openCareSessionPrep()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    } else {
                        FadeInLine(text: "No one’s selected.", delay: 0)
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

    private func discoveryRunSummary(for patientId: UUID, state: SessionPOCState) -> String? {
        guard state.selectedCarePatientId == patientId else { return nil }
        guard state.discoveryResults.count == DiscoveryFlowPOC.snippetCount else { return nil }
        let unpleasant = state.discoveryResults.filter { $0.sentiment == .unpleasant }.count
        let neutral = state.discoveryResults.filter { $0.sentiment == .neutral }.count
        let pleasant = state.discoveryResults.filter { $0.sentiment == .pleasant }.count
        return "Last pass: red (uncomfortable) \(unpleasant), amber (unsure) \(neutral), green (comforting) \(pleasant)."
    }

    private func orderedPlaylistGroups(_ patient: CarePatientProfile) -> [CareGenrePlaylistGroup] {
        patient.genrePlaylistGroups.sorted { $0.genre.rawValue < $1.genre.rawValue }
    }

    private func genrePlaylistsCard(_ patient: CarePatientProfile) -> some View {
        let groups = orderedPlaylistGroups(patient)
        return BrandCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Playlists on file (by genre)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.brownMuted)
                Text("These appear as floating instruments for the resident — staff does not change them here.")
                    .font(.caption2)
                    .foregroundStyle(BrandTheme.brownMuted)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    if index > 0 {
                        Divider().opacity(0.35)
                    }
                    genrePlaylistSection(group: group)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
    }

    private func genrePlaylistSection(group: CareGenrePlaylistGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: group.genre.iconName)
                    .font(.title3)
                    .foregroundStyle(group.genre.accent)
                Text(group.genre.accessibilityLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandTheme.brown)
                Spacer(minLength: 0)
            }
            ForEach(group.playlists) { pl in
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "music.note.list")
                        .font(.caption)
                        .foregroundStyle(BrandTheme.brownMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pl.title)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.brown)
                        Text("\(pl.trackTitles.count) tracks in player · about \(pl.durationMinutes) min")
                            .font(.caption2)
                            .foregroundStyle(BrandTheme.brownMuted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
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
                    FadeInTitle(text: "Afterward", delay: 0)
                    if let patient = targetPatient {
                        FadeInLine(
                            text: "How did \(patient.displayName) seem? This isn’t a grade for you — it nudges the sound for next time.",
                            font: .caption,
                            color: BrandTheme.brownMuted,
                            delay: 0.08
                        )

                        BrandCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("In the moment")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.brownMuted)
                                outcomeSlider(
                                    title: "Seemed settled",
                                    caption: "Still unsettled  ←  →  More at ease",
                                    value: $settled
                                )
                                outcomeSlider(
                                    title: "With you",
                                    caption: "Withdrawn  ←  →  Present / connected",
                                    value: $engagement
                                )
                                outcomeSlider(
                                    title: "Comfort in the room",
                                    caption: "Struggling  ←  →  Comfortable throughout",
                                    value: $comfort
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)

                        Text("Sound for next time")
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
                            TextField("What helped — light, touch, sound? What would you soften next time?", text: $staffNote, axis: .vertical)
                                .lineLimit(1 ... 10)
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

                        PrimaryButton(title: "Save note & sound tweaks") {
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

                        SecondaryButton(title: "Skip — keep session only") {
                            state.skipCareFeedback()
                        }
                        .padding(.horizontal, 24)
                    } else {
                        FadeInLine(text: "Pick someone from the list to save a note.", delay: 0)
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
