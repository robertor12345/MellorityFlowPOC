import SwiftUI

// MARK: - Resident session: floating instrument symbols → playlist + playback

struct ResidentProfileView: View {
    @ObservedObject var state: SessionPOCState
    @State private var activeSheet: ResidentMusicSheetRoute?

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

            TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    ForEach(Array(genresOnFile.enumerated()), id: \.offset) { index, genre in
                        floatingInstrumentButton(genre: genre, index: index, phase: t, in: geo.size)
                    }
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        state.leaveResidentProfileToStaff()
                    } label: {
                        Image(systemName: "person.badge.key.fill")
                            .font(.title2)
                            .foregroundStyle(BrandTheme.brown.opacity(0.85))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Return device to staff")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
        }
        .sheet(item: $activeSheet) { route in
            switch route.kind {
            case .choosePlaylist(let genre, let playlists):
                ResidentPlaylistPickSheet(
                    genre: genre,
                    playlists: playlists,
                    onSelect: { pl in
                        activeSheet = ResidentMusicSheetRoute(kind: .player(genre: genre, playlist: pl))
                    },
                    onDismiss: { activeSheet = nil }
                )
            case .player(let genre, let playlist):
                ResidentPlaylistPlayerSheet(
                    state: state,
                    genre: genre,
                    playlist: playlist,
                    onDismiss: { activeSheet = nil }
                )
            }
        }
    }

    private func floatingInstrumentButton(
        genre: ResidentMusicGenre,
        index: Int,
        phase: TimeInterval,
        in size: CGSize
    ) -> some View {
        let x = instrumentX(index: index, count: genresOnFile.count, phase: phase, width: size.width)
        let y = instrumentY(index: index, phase: phase, height: size.height)
        let sway = sin(phase * 0.48 + Double(index) * 0.94) * 5
        let bob = sin(phase * 0.82 + Double(index) * 0.61) * 6

        return Button {
            guard let group = patient?.genrePlaylistGroups.first(where: { $0.genre == genre }) else { return }
            if group.playlists.count == 1, let only = group.playlists.first {
                activeSheet = ResidentMusicSheetRoute(kind: .player(genre: genre, playlist: only))
            } else {
                activeSheet = ResidentMusicSheetRoute(kind: .choosePlaylist(genre: genre, playlists: group.playlists))
            }
        } label: {
            ZStack {
                Circle()
                    .fill(genre.accent.opacity(0.38))
                    .frame(width: 88, height: 88)
                    .shadow(color: genre.accent.opacity(0.35), radius: 14, y: 6)
                Image(systemName: genre.iconName)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(BrandTheme.brown)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(genre.accessibilityLabel)
        .position(x: x, y: y + bob)
        .rotationEffect(.degrees(sway))
    }

    private func instrumentX(index: Int, count: Int, phase: TimeInterval, width: CGFloat) -> CGFloat {
        let base = Double(index + 1) / Double(max(count + 1, 2))
        let wobble = sin( phase * 0.31 + Double(index) * 1.1) * 0.06
        let frac = min(0.9, max(0.1, base + wobble))
        return width * CGFloat(frac)
    }

    private func instrumentY(index: Int, phase: TimeInterval, height: CGFloat) -> CGFloat {
        let row = index % 3
        let baseY = 0.28 + Double(row) * 0.2 + sin(Double(index) * 0.7 + phase * 0.17) * 0.04
        return height * CGFloat(min(0.78, max(0.22, baseY)))
    }
}

// MARK: - Sheet routing

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

// MARK: - Pick playlist (only when multiple for a genre)

private struct ResidentPlaylistPickSheet: View {
    let genre: ResidentMusicGenre
    let playlists: [CarePlaylistEntry]
    let onSelect: (CarePlaylistEntry) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(playlists) { pl in
                    Button {
                        onSelect(pl)
                    } label: {
                        HStack {
                            Image(systemName: genre.iconName)
                                .foregroundStyle(genre.accent)
                            VStack(alignment: .leading) {
                                Text(pl.title)
                                    .foregroundStyle(BrandTheme.brown)
                                Text("\(pl.trackCount) tracks · ~\(pl.durationMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(BrandTheme.brownMuted)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pick a list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Player + track list

private struct ResidentPlaylistPlayerSheet: View {
    @ObservedObject var state: SessionPOCState
    let genre: ResidentMusicGenre
    let playlist: CarePlaylistEntry
    let onDismiss: () -> Void

    @StateObject private var audio = AmbientAudioSession()
    @State private var currentIndex = 0
    @State private var isPlaying = false
    @State private var streamStarted = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        ForEach(Array(playlist.trackTitles.enumerated()), id: \.offset) { idx, title in
                            HStack {
                                Image(systemName: idx == currentIndex ? "waveform" : "music.note")
                                    .foregroundStyle(idx == currentIndex ? BrandTheme.goldDeep : BrandTheme.brownMuted)
                                Text(title)
                                    .foregroundStyle(BrandTheme.brown)
                                Spacer()
                                if idx == currentIndex, isPlaying {
                                    ProgressView()
                                        .scaleEffect(0.85)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                currentIndex = idx
                                restartPlaybackFromCurrent()
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: genre.iconName)
                                    .foregroundStyle(genre.accent)
                                Text(playlist.title)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.brown)
                            }
                            Text("\(playlist.trackCount) tracks · about \(playlist.durationMinutes) min")
                                .font(.caption)
                                .foregroundStyle(BrandTheme.brownMuted)
                        }
                        .padding(.vertical, 4)
                    }
                }

                VStack(spacing: 14) {
                    HStack(spacing: 36) {
                        Button {
                            stepTrack(delta: -1)
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title2)
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
                                .font(.system(size: 54))
                                .foregroundStyle(BrandTheme.goldDeep)
                        }

                        Button {
                            stepTrack(delta: 1)
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                        }
                        .disabled(playlist.trackTitles.isEmpty)
                    }
                    .foregroundStyle(BrandTheme.brown)
                    .padding(.vertical, 6)

                    PrimaryButton(title: "Calm room visuals") {
                        audio.stop()
                        state.prepareResidentImmersiveFromPlaylist(genre: genre)
                        onDismiss()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
                .background(BrandTheme.cream.opacity(0.95))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        audio.stop()
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
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
