import SwiftUI

// MARK: - Resident session: floating calm glyphs → in-app playlist panels (no system chrome)

private enum GlyphFloatLayout {
    static let glyphRadius: CGFloat = 46
    /// Resting clearance between disk edges (motion budget is capped below this).
    private static let restingEdgeSeparation: CGFloat = 54

    private static func minCenterDistance(resting: Bool = true) -> CGFloat {
        2 * glyphRadius + (resting ? restingEdgeSeparation : 20)
    }

    /// Playscreen inset so glyphs stay below staff affordances and safe edges.
    private static func playableRect(in size: CGSize) -> CGRect {
        let padX = max(BrandTheme.contentGutter, 28)
        let side = glyphRadius + 22 + padX
        let top: CGFloat = 124
        let bottom: CGFloat = 44
        return CGRect(
            x: side,
            y: top,
            width: max(120, size.width - side * 2),
            height: max(220, size.height - top - bottom)
        )
    }

    /// Evenly spaced on an ellipse inside `playable`, with pairwise separation guarded by relaxation.
    static func constellation(count: Int, in size: CGSize) -> (centers: [CGPoint], hub: CGPoint) {
        guard count > 0 else { return ([], .zero) }
        let playable = playableRect(in: size)
        let hub = CGPoint(x: playable.midX, y: playable.midY)
        switch count {
        case 1:
            return ([hub], hub)
        default:
            let minD = minCenterDistance()
            let sinHalfChord = CGFloat(sin(Double.pi / Double(count)))
            let maxEllipseX = playable.width / 2 - glyphRadius - 14
            let maxEllipseY = playable.height / 2 - glyphRadius - 16
            // Mean radius needed so neighbouring arc chord ≥ resting minimum.
            let radiusChord = CGFloat(minD * 1.06) / (2 * max(sinHalfChord, CGFloat(1e-3)))
            var rx = min(maxEllipseX * 0.97, radiusChord)
            var ry = min(maxEllipseY * 0.95, radiusChord * CGFloat(0.91))
            rx = max(rx, CGFloat(72 + count * 2))
            ry = max(min(ry, maxEllipseY), CGFloat(58 + count * 2))

            var pts = ellipsePoints(count: count, hub: hub, rx: rx, ry: ry)
            pts = pts.map { clampToPlayable($0, playable: playable) }
            pts = relaxCenters(pts, playable: playable, minDist: minD * 1.03, iterations: 14)

            let spread = pairwiseMinSpacing(pts)
            if spread < minD * 1.015, count >= 2 {
                let scale: CGFloat = 1.085
                let rx2 = min(maxEllipseX * 0.99, rx * scale)
                let ry2 = min(maxEllipseY * 0.97, ry * scale)
                var pts2 = ellipsePoints(count: count, hub: hub, rx: rx2, ry: ry2)
                pts2 = pts2.map { clampToPlayable($0, playable: playable) }
                pts = relaxCenters(pts2, playable: playable, minDist: minD * 1.03, iterations: 16)
            }
            return (pts, hub)
        }
    }

    private static func pairwiseMinSpacing(_ pts: [CGPoint]) -> CGFloat {
        guard pts.count >= 2 else { return CGFloat.greatestFiniteMagnitude }
        var m = CGFloat.greatestFiniteMagnitude
        for i in pts.indices {
            for j in (i &+ 1) ..< pts.count {
                m = min(m, hypot(pts[j].x - pts[i].x, pts[j].y - pts[i].y))
            }
        }
        return m
    }

    private static func ellipsePoints(count: Int, hub: CGPoint, rx: CGFloat, ry: CGFloat) -> [CGPoint] {
        guard count > 0 else { return [] }
        let start = -CGFloat.pi / 2 + 0.16
        return (0..<count).map { i in
            let θ = start + CGFloat(i) * (2 * .pi / CGFloat(count))
            return CGPoint(x: hub.x + cos(θ) * rx, y: hub.y + sin(θ) * ry)
        }
    }

    private static func clampToPlayable(_ p: CGPoint, playable: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(playable.minX + glyphRadius + 8, p.x), playable.maxX - glyphRadius - 8),
            y: min(max(playable.minY + glyphRadius + 8, p.y), playable.maxY - glyphRadius - 8)
        )
    }

    /// Push overlaps apart gently while respecting the playable hull.
    private static func relaxCenters(_ pts: [CGPoint], playable: CGRect, minDist: CGFloat, iterations: Int) -> [CGPoint] {
        var p = pts
        guard p.count >= 2 else { return p }
        for _ in 0 ..< iterations {
            for i in p.indices {
                var ax: CGFloat = 0
                var ay: CGFloat = 0
                for j in p.indices where j != i {
                    let dx = p[i].x - p[j].x
                    let dy = p[i].y - p[j].y
                    let dist = hypot(dx, dy)
                    guard dist > 0.001, dist < minDist else { continue }
                    let push = (minDist - dist) / dist * 0.42
                    ax += dx * push
                    ay += dy * push
                }
                p[i].x += ax
                p[i].y += ay
                p[i] = clampToPlayable(p[i], playable: playable)
            }
        }
        return p
    }

    /// Multi-layer motion that keeps typical displacement modest so relaxation margins hold.
    static func animatedDelta(index: Int, base: CGPoint, hub: CGPoint, phase: TimeInterval) -> CGSize {
        let ω1 = 0.19 + Double(index % 7) * 0.063
        let ω2 = 0.247 + Double((index ^ 5) % 9) * 0.058
        let ω3 = 0.089 + Double((index + 2) % 11) * 0.031

        let drift = CGSize(
            width: CGFloat(sin(phase * 0.049 + Double(index % 13) + 2.08) * 11),
            height: CGFloat(cos(phase * 0.043 + Double(index % 17) + 1.71) * 9.5)
        )

        let vx = base.x - hub.x
        let vy = base.y - hub.y
        let len = hypot(vx, vy)
        let tx = len > 0.5 ? -vy / len : 0
        let ty = len > 0.5 ? vx / len : 1

        let tangentialCarrier =
            sin(phase * ω3 + Double(index))
            + 0.34 * cos(phase * ω3 * 1.618 + Double(index + 9))
            + 0.26 * sin(phase * (ω3 + 0.067) + Double(index))

        let tangentialAmp = CGFloat(tangentialCarrier * Double(7 + index % 3))

        let normCarrier = CGFloat(0.42 * cos(phase * ω2 + Double(index)))
        let alongX = len > 0.5 ? vx / len : 1
        let alongY = len > 0.5 ? vy / len : 0

        let ripple = CGSize(
            width: CGFloat(sin(phase * ω1 + Double(index))) * CGFloat(7 + CGFloat(index % 4)),
            height: CGFloat(cos(phase * ω2 + Double(index) * 0.93)) * CGFloat(7 + CGFloat((index >> 1) % 5))
        )

        let orbital = CGSize(
            width: tx * tangentialAmp + alongX * normCarrier,
            height: ty * tangentialAmp + alongY * normCarrier
        )

        var Δ = CGSize(
            width: drift.width + ripple.width + orbital.width,
            height: drift.height + ripple.height + orbital.height
        )
        Δ = clampMotionVector(Δ, maxLength: motionCap)
        return Δ
    }

    /// Limits how far glyphs wander from lattice rest so pairwise separation survives motion + scale pulses.
    private static let motionCap: CGFloat = 19

    private static func clampMotionVector(_ Δ: CGSize, maxLength: CGFloat) -> CGSize {
        let length = hypot(Δ.width, Δ.height)
        guard length > maxLength, length > 0.001 else { return Δ }
        let s = maxLength / length
        return CGSize(width: Δ.width * s, height: Δ.height * s)
    }

    static func rotationDynamics(index: Int, phase: TimeInterval) -> Double {
        sin(phase * 0.21 + Double(index) * 0.97) * 6.2
            + cos(phase * 0.33 + Double(index) * 0.63) * 4.1
            + sin(phase * 0.11 + Double(index) * 2.71) * 3.2
    }

    static func scalePulse(index: Int, phase: TimeInterval) -> CGFloat {
        CGFloat(1 + 0.028 * sin(phase * (0.24 + Double(index % 11) * 0.036) + Double(index)))
    }
}

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
                    let layout = GlyphFloatLayout.constellation(count: genresOnFile.count, in: geo.size)
                    ForEach(Array(genresOnFile.enumerated()), id: \.offset) { index, genre in
                        if index < layout.centers.count {
                            floatingGlyphButton(
                                genre: genre,
                                index: index,
                                baseCenter: layout.centers[index],
                                constellationHub: layout.hub,
                                phase: t
                            )
                        }
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

                Spacer()
            }
            .padding(.horizontal, BrandTheme.contentGutter)
            .padding(.top, 10)

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
        baseCenter: CGPoint,
        constellationHub: CGPoint,
        phase: TimeInterval
    ) -> some View {
        let Δ = GlyphFloatLayout.animatedDelta(index: index, base: baseCenter, hub: constellationHub, phase: phase)
        let pos = CGPoint(x: baseCenter.x + Δ.width, y: baseCenter.y + Δ.height)
        let rot = GlyphFloatLayout.rotationDynamics(index: index, phase: phase)
        let scale = GlyphFloatLayout.scalePulse(index: index, phase: phase)

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
                    .font(.system(size: 38, weight: .light))
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
        .position(x: pos.x, y: pos.y)
        .rotationEffect(.degrees(rot))
        .scaleEffect(scale, anchor: .center)
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
