import SwiftUI

// MARK: - Resident session: floating calm glyphs → in-app playlist panels (no system chrome)

struct ResidentProfileView: View {
    @ObservedObject var state: SessionPOCState
    @State private var activeOverlay: ResidentMusicSheetRoute?

    private var patient: CarePatientProfile? {
        state.carePatient(id: state.selectedCarePatientId)
    }

    private var genresOnFile: [ResidentMusicGenre] {
        guard let patient else { return [] }
        let set = Set(patient.genrePlaylistGroups.map(\.genre))
        return ResidentMusicGenre.allCases.filter { set.contains($0) }
    }

    var body: some View {
        ZStack {
            BrandTheme.backgroundGradient
                .ignoresSafeArea()

            GoldAmbientSparklesView(intensity: 0.26)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    ForEach(Array(genresOnFile.enumerated()), id: \.offset) { index, genre in
                        floatingGlyphButton(genre: genre, index: index, phase: t, in: geo.size)
                    }
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        state.leaveResidentProfileToStaff()
                    } label: {
                        Image(systemName: "person.badge.key")
                            .font(.title3.weight(.light))
                            .foregroundStyle(BrandTheme.brownMuted)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(BrandTheme.cream.opacity(0.94))
                                    .shadow(color: BrandTheme.brown.opacity(0.06), radius: 10, y: 4)
                            )
                            .overlay(
                                Circle()
                                    .stroke(BrandTheme.gold.opacity(0.38), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Return device to staff")
                }
                .padding(.horizontal, BrandTheme.contentGutter)
                .padding(.top, 10)
                Spacer()
            }

            if let route = activeOverlay {
                residentChromeOverlay(route: route)
            }
        }
        .animation(.spring(response: 0.44, dampingFraction: 0.88), value: activeOverlay?.id)
    }

    private func residentChromeOverlay(route: ResidentMusicSheetRoute) -> some View {
        ZStack {
            Color(red: 0.2, green: 0.16, blue: 0.12)
                .opacity(0.32)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    activeOverlay = nil
                }

            VStack {
                Spacer(minLength: 0)
                Group {
                    switch route.kind {
                    case .choosePlaylist(let genre, let playlists):
                        ResidentPlaylistPickPanel(
                            genre: genre,
                            playlists: playlists,
                            onSelect: { pl in
                                activeOverlay = ResidentMusicSheetRoute(kind: .player(genre: genre, playlist: pl))
                            },
                            onDismiss: { activeOverlay = nil }
                        )
                    case .player(let genre, let playlist):
                        ResidentPlaylistPlayerPanel(
                            state: state,
                            genre: genre,
                            playlist: playlist,
                            onDismiss: { activeOverlay = nil }
                        )
                    }
                }
                .padding(.horizontal, BrandTheme.contentGutter)
                .padding(.bottom, max(20, 8))
            }
        }
        .transition(.opacity)
    }

    private func floatingGlyphButton(
        genre: ResidentMusicGenre,
        index: Int,
        phase: TimeInterval,
        in size: CGSize
    ) -> some View {
        let x = glyphX(index: index, count: genresOnFile.count, phase: phase, width: size.width)
        let y = glyphY(index: index, phase: phase, height: size.height)
        let sway = sin(phase * 0.38 + Double(index) * 0.87) * 4
        let bob = sin(phase * 0.68 + Double(index) * 0.53) * 5

        return Button {
            guard let group = patient?.genrePlaylistGroups.first(where: { $0.genre == genre }) else { return }
            if group.playlists.count == 1, let only = group.playlists.first {
                activeOverlay = ResidentMusicSheetRoute(kind: .player(genre: genre, playlist: only))
            } else {
                activeOverlay = ResidentMusicSheetRoute(kind: .choosePlaylist(genre: genre, playlists: group.playlists))
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                genre.accent.opacity(0.48),
                                BrandTheme.cream.opacity(0.92),
                            ],
                            center: .center,
                            startRadius: 6,
                            endRadius: 54
                        )
                    )
                    .frame(width: 92, height: 92)
                    .shadow(color: BrandTheme.brown.opacity(0.07), radius: 16, y: 7)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [BrandTheme.gold.opacity(0.55), BrandTheme.goldSoft.opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                Image(systemName: genre.iconName)
                    .font(.system(size: 34, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrandTheme.brown.opacity(0.5), BrandTheme.brown.opacity(0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(genre.accessibilityLabel)
        .position(x: x, y: y + bob)
        .rotationEffect(.degrees(sway))
    }

    private func glyphX(index: Int, count: Int, phase: TimeInterval, width: CGFloat) -> CGFloat {
        let base = Double(index + 1) / Double(max(count + 1, 2))
        let wobble = sin(phase * 0.27 + Double(index) * 1.05) * 0.055
        let frac = min(0.9, max(0.1, base + wobble))
        return width * CGFloat(frac)
    }

    private func glyphY(index: Int, phase: TimeInterval, height: CGFloat) -> CGFloat {
        let row = index % 3
        let baseY = 0.28 + Double(row) * 0.2 + sin(Double(index) * 0.65 + phase * 0.14) * 0.038
        return height * CGFloat(min(0.78, max(0.22, baseY)))
    }
}

// MARK: - Overlay routing

struct ResidentMusicSheetRoute: Identifiable {
    enum Kind {
        case choosePlaylist(genre: ResidentMusicGenre, playlists: [CarePlaylistEntry])
        case player(genre: ResidentMusicGenre, playlist: CarePlaylistEntry)
    }

    let id: String
    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
        switch kind {
        case .choosePlaylist(let g, _):
            self.id = "pick-\(g.rawValue)"
        case .player(let g, let pl):
            self.id = "play-\(g.rawValue)-\(pl.id.uuidString)"
        }
    }
}

// MARK: - Themed pick panel (replaces system list / nav)

private struct ResidentPlaylistPickPanel: View {
    let genre: ResidentMusicGenre
    let playlists: [CarePlaylistEntry]
    let onSelect: (CarePlaylistEntry) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader(symbol: genre.iconName, onClose: onDismiss)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(playlists) { pl in
                        Button {
                            onSelect(pl)
                        } label: {
                            HStack(alignment: .center, spacing: 14) {
                                Image(systemName: genre.iconName)
                                    .font(.title2.weight(.ultraLight))
                                    .foregroundStyle(genre.accent)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pl.title)
                                        .font(BrandTheme.title(.subheadline))
                                        .fontWeight(.medium)
                                        .foregroundStyle(BrandTheme.brown)
                                        .multilineTextAlignment(.leading)
                                    Text("\(pl.trackTitles.count) pieces · ~\(pl.durationMinutes) min")
                                        .font(.caption)
                                        .foregroundStyle(BrandTheme.brownMuted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.gold.opacity(0.7))
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(BrandTheme.cream.opacity(0.96))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(BrandTheme.gold.opacity(0.28), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 6)
            }
            .frame(maxHeight: 320)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(BrandTheme.creamMid.opacity(0.97))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: BrandTheme.brown.opacity(0.12), radius: 24, y: 8)
    }
}

// MARK: - Themed player panel

private struct ResidentPlaylistPlayerPanel: View {
    @ObservedObject var state: SessionPOCState
    let genre: ResidentMusicGenre
    let playlist: CarePlaylistEntry
    let onDismiss: () -> Void

    @StateObject private var audio = AmbientAudioSession()
    @State private var currentIndex = 0
    @State private var isPlaying = false
    @State private var streamStarted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader(symbol: genre.iconName, onClose: {
                audio.stop()
                onDismiss()
            })

            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.title)
                    .font(BrandTheme.title(.headline))
                    .foregroundStyle(BrandTheme.brown)
                Text("\(playlist.trackTitles.count) pieces · about \(playlist.durationMinutes) min")
                    .font(.caption)
                    .foregroundStyle(BrandTheme.brownMuted)
            }
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(playlist.trackTitles.enumerated()), id: \.offset) { idx, title in
                        Button {
                            currentIndex = idx
                            restartPlaybackFromCurrent()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: idx == currentIndex ? "waveform.path" : "circle.fill")
                                    .font(.system(size: idx == currentIndex ? 15 : 6, weight: .light))
                                    .foregroundStyle(idx == currentIndex ? BrandTheme.goldDeep : BrandTheme.brownMuted.opacity(0.45))
                                    .frame(width: 22)
                                Text(title)
                                    .font(BrandTheme.title(.subheadline))
                                    .foregroundStyle(BrandTheme.brown)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                if idx == currentIndex, isPlaying {
                                    ProgressView()
                                        .scaleEffect(0.85)
                                        .tint(BrandTheme.goldDeep)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        idx == currentIndex
                                            ? BrandTheme.goldSoft.opacity(0.35)
                                            : BrandTheme.cream.opacity(0.55)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        idx == currentIndex ? BrandTheme.gold.opacity(0.45) : BrandTheme.gold.opacity(0.15),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 260)

            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    Button {
                        stepTrack(delta: -1)
                    } label: {
                        Image(systemName: "backward.circle")
                            .font(.system(size: 36, weight: .ultraLight))
                    }
                    .disabled(playlist.trackTitles.isEmpty)

                    Button {
                        guard !playlist.trackTitles.isEmpty else { return }
                        if !streamStarted {
                            audio.startFresh(photoAnchored: false)
                            streamStarted = true
                            isPlaying = true
                        } else if isPlaying {
                            audio.pausePlayback()
                            isPlaying = false
                        } else {
                            audio.resumePlayback()
                            isPlaying = true
                        }
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [BrandTheme.goldSoft, BrandTheme.goldDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .symbolRenderingMode(.hierarchical)
                    }

                    Button {
                        stepTrack(delta: 1)
                    } label: {
                        Image(systemName: "forward.circle")
                            .font(.system(size: 36, weight: .ultraLight))
                    }
                    .disabled(playlist.trackTitles.isEmpty)
                }
                .foregroundStyle(BrandTheme.brown)

                PrimaryButton(title: "Calm room visuals") {
                    audio.stop()
                    state.prepareResidentImmersiveFromPlaylist(genre: genre)
                    onDismiss()
                }
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(BrandTheme.creamMid.opacity(0.97))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: BrandTheme.brown.opacity(0.12), radius: 24, y: 8)
        .onDisappear {
            audio.stop()
        }
    }

    private func stepTrack(delta: Int) {
        guard !playlist.trackTitles.isEmpty else { return }
        let n = playlist.trackTitles.count
        currentIndex = (currentIndex + delta + n) % n
        restartPlaybackFromCurrent()
    }

    private func restartPlaybackFromCurrent() {
        guard !playlist.trackTitles.isEmpty else { return }
        audio.stop()
        audio.startFresh(photoAnchored: false)
        streamStarted = true
        isPlaying = true
    }
}

// MARK: - Shared panel chrome

@ViewBuilder
private func panelHeader(symbol: String, onClose: @escaping () -> Void) -> some View {
    HStack {
        Capsule()
            .fill(BrandTheme.brownMuted.opacity(0.22))
            .frame(width: 36, height: 5)
        Spacer()
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandTheme.brownMuted)
                .padding(10)
                .background(Circle().fill(BrandTheme.cream.opacity(0.9)))
                .overlay(Circle().stroke(BrandTheme.gold.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
    .padding(.bottom, 14)

    HStack(spacing: 10) {
        Image(systemName: symbol)
            .font(.title2.weight(.ultraLight))
            .foregroundStyle(BrandTheme.brown.opacity(0.75))
        Spacer(minLength: 0)
    }
    .padding(.bottom, 8)
}
