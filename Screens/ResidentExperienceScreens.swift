import SwiftUI

// MARK: - Resident session: genre glyphs play immediately → idle & playing layouts span the playable hull

private enum GlyphFloatLayout {
    static let glyphRadius: CGFloat = 46
    /// Resting clearance between disk edges (motion budget is capped below this).
    private static let restingEdgeSeparation: CGFloat = 54

    private static func minCenterDistance(resting: Bool = true) -> CGFloat {
        2 * glyphRadius + (resting ? restingEdgeSeparation : 20)
    }

    /// Playscreen inset — kept fairly tight so **idle** constellation can use nearly the whole view (staff FAB overlays top-trailing).
    private static func playableRect(in size: CGSize) -> CGRect {
        let padX = max(BrandTheme.contentGutter, 18)
        let side = glyphRadius + 10 + padX
        let top: CGFloat = 52
        let bottom: CGFloat = 88
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
            let maxEllipseX = playable.width / 2 - glyphRadius - 8
            let maxEllipseY = playable.height / 2 - glyphRadius - 10
            // Chord-derived radius prefers non-overlap on a perfect ring; blending with hull scale spreads glyphs edge-to-edge.
            let radiusChord = CGFloat(minD * 1.06) / (2 * max(sinHalfChord, CGFloat(1e-3)))
            var rx = min(maxEllipseX * 0.995, radiusChord * 1.48)
            var ry = min(maxEllipseY * 0.99, radiusChord * CGFloat(1.32))
            rx = max(rx, maxEllipseX * 0.84)
            ry = max(min(ry, maxEllipseY), maxEllipseY * 0.8)

            var pts = ellipsePoints(count: count, hub: hub, rx: rx, ry: ry)
            pts = pts.map { clampToPlayable($0, playable: playable) }
            pts = relaxCenters(pts, playable: playable, minDist: minD * 1.03, iterations: 24)

            let spread = pairwiseMinSpacing(pts)
            if spread < minD * 1.015, count >= 2 {
                let scale: CGFloat = 1.128
                let rx2 = min(maxEllipseX * 0.999, rx * scale)
                let ry2 = min(maxEllipseY * 0.99, ry * scale)
                var pts2 = ellipsePoints(count: count, hub: hub, rx: rx2, ry: ry2)
                pts2 = pts2.map { clampToPlayable($0, playable: playable) }
                pts = relaxCenters(pts2, playable: playable, minDist: minD * 1.03, iterations: 22)
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

    private static func clampToPlayable(_ p: CGPoint, playable: CGRect, glyphR: CGFloat) -> CGPoint {
        let edge: CGFloat = 4
        return CGPoint(
            x: min(max(playable.minX + glyphR + edge, p.x), playable.maxX - glyphR - edge),
            y: min(max(playable.minY + glyphR + edge, p.y), playable.maxY - glyphR - edge)
        )
    }

    private static func clampToPlayable(_ p: CGPoint, playable: CGRect) -> CGPoint {
        clampToPlayable(p, playable: playable, glyphR: glyphRadius)
    }

    /// Push overlaps apart gently while respecting the playable hull.
    private static func relaxCenters(
        _ pts: [CGPoint],
        playable: CGRect,
        minDist: CGFloat,
        iterations: Int,
        clampRadius: CGFloat = glyphRadius
    ) -> [CGPoint] {
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
                p[i] = clampToPlayable(p[i], playable: playable, glyphR: clampRadius)
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

    /// Keeps a disk center ≥ `minRadius` from `hub` (clears centred hero occupancy).
    private static func ensureMinRadialDistanceFromHub(_ p: CGPoint, hub: CGPoint, minRadius: CGFloat) -> CGPoint {
        let dx = p.x - hub.x
        let dy = p.y - hub.y
        let d = hypot(dx, dy)
        guard d > 1e-3 else {
            return CGPoint(x: hub.x + minRadius, y: hub.y)
        }
        guard d < minRadius else { return p }
        let scale = minRadius / d
        return CGPoint(x: hub.x + dx * scale, y: hub.y + dy * scale)
    }

    static func rotationDynamics(index: Int, phase: TimeInterval) -> Double {
        sin(phase * 0.21 + Double(index) * 0.97) * 6.2
            + cos(phase * 0.33 + Double(index) * 0.63) * 4.1
            + sin(phase * 0.11 + Double(index) * 2.71) * 3.2
    }

    static func scalePulse(index: Int, phase: TimeInterval) -> CGFloat {
        CGFloat(1 + 0.028 * sin(phase * (0.24 + Double(index % 11) * 0.036) + Double(index)))
    }

    /// Center of the music-glyph playable area — same hull `constellation` uses.
    static func musicGlyphHub(in size: CGSize) -> CGPoint {
        constellation(count: 1, in: size).hub
    }

    /// While one genre occupies **`hub`** as hero, lays out the inactive picks on an **ellipse** through the playable hull —
    /// same spreading idea as idle `constellation`, but with pairwise spacing for the smaller periphery disks and a ring floor outside the hero.
    static func focusedInactivePeriphery(
        inactiveCount: Int,
        heroDiameter: CGFloat,
        hub: CGPoint,
        in size: CGSize
    ) -> [CGPoint] {
        guard inactiveCount > 0 else { return [] }
        let playable = playableRect(in: size)
        let inactiveR: CGFloat = 32
        let minPairSep = CGFloat(2 * inactiveR + restingEdgeSeparation * 0.94)
        let minOrbitRadius = CGFloat(heroDiameter * 0.5 + inactiveR + 54)

        if inactiveCount == 1 {
            var solo = CGPoint(
                x: playable.minX + inactiveR + 14 + playable.width * 0.08,
                y: playable.minY + inactiveR + 18 + playable.height * 0.16
            )
            solo = ensureMinRadialDistanceFromHub(solo, hub: hub, minRadius: minOrbitRadius)
            return [clampToPlayable(solo, playable: playable, glyphR: inactiveR)]
        }

        let sinHalfChord = CGFloat(sin(Double.pi / Double(inactiveCount)))
        let maxEllipseX = playable.width / 2 - inactiveR - 8
        let maxEllipseY = playable.height / 2 - inactiveR - 10
        let radiusChord = CGFloat(minPairSep * 1.06) / (2 * max(sinHalfChord, CGFloat(1e-3)))

        var rx = min(maxEllipseX * 0.995, radiusChord * 1.52)
        var ry = min(maxEllipseY * 0.99, radiusChord * CGFloat(1.36))
        rx = max(rx, maxEllipseX * 0.84)
        ry = max(ry, maxEllipseY * 0.8)
        rx = max(rx, min(minOrbitRadius * 1.06, maxEllipseX * 0.998))
        ry = max(ry, min(minOrbitRadius * CGFloat(1.02), maxEllipseY * 0.998))

        var pts = ellipsePoints(count: inactiveCount, hub: hub, rx: rx, ry: ry)
        pts = pts.map { ensureMinRadialDistanceFromHub($0, hub: hub, minRadius: minOrbitRadius) }
        pts = pts.map { clampToPlayable($0, playable: playable, glyphR: inactiveR) }
        pts = relaxCenters(pts, playable: playable, minDist: minPairSep * 1.03, iterations: 26, clampRadius: inactiveR)

        pts = pts.map { ensureMinRadialDistanceFromHub($0, hub: hub, minRadius: minOrbitRadius) }
        pts = pts.map { clampToPlayable($0, playable: playable, glyphR: inactiveR) }

        let spread = pairwiseMinSpacing(pts)
        if spread < minPairSep * 1.012, inactiveCount >= 2 {
            let scale: CGFloat = 1.14
            let rx2 = min(maxEllipseX * 0.999, rx * scale)
            let ry2 = min(maxEllipseY * 0.99, ry * scale)
            var pts2 = ellipsePoints(count: inactiveCount, hub: hub, rx: rx2, ry: ry2)
            pts2 = pts2.map { ensureMinRadialDistanceFromHub($0, hub: hub, minRadius: minOrbitRadius) }
            pts2 = pts2.map { clampToPlayable($0, playable: playable, glyphR: inactiveR) }
            pts = relaxCenters(pts2, playable: playable, minDist: minPairSep * 1.03, iterations: 22, clampRadius: inactiveR)

            pts = pts.map { ensureMinRadialDistanceFromHub($0, hub: hub, minRadius: minOrbitRadius) }
            pts = pts.map { clampToPlayable($0, playable: playable, glyphR: inactiveR) }
        }
        return pts
    }
}

struct ResidentProfileView: View {
    @ObservedObject var state: SessionPOCState
    @StateObject private var residentAudio = AmbientAudioSession()
    /// Highlights the glyph whose playlist is sounding; reshapes the floating layout around it.
    @State private var selectedPlayingGenre: ResidentMusicGenre?

    private var patient: CarePatientProfile? {
        state.carePatient(id: state.selectedCarePatientId)
    }

    private var genresOnFile: [ResidentMusicGenre] {
        guard let patient else { return [] }
        let set = Set(patient.genrePlaylistGroups.map(\.genre))
        return ResidentMusicGenre.allCases.filter { set.contains($0) }
    }

    private enum ResidentMusicGlyphSizing {
        /// Hero disk while a playlist plays — must stay in sync with `glyphFrames` hero metrics.
        static let heroDiskDiameter: CGFloat = 154
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
                    let hub = GlyphFloatLayout.musicGlyphHub(in: geo.size)
                    let idle = GlyphFloatLayout.constellation(count: genresOnFile.count, in: geo.size)
                    let playingPeriphery: [CGPoint] = {
                        guard let sg = selectedPlayingGenre else { return [] }
                        let others = genresOnFile.filter { $0 != sg }
                        guard others.isEmpty == false else { return [] }
                        return GlyphFloatLayout.focusedInactivePeriphery(
                            inactiveCount: others.count,
                            heroDiameter: ResidentMusicGlyphSizing.heroDiskDiameter,
                            hub: hub,
                            in: geo.size
                        )
                    }()

                    ForEach(Array(genresOnFile.enumerated()), id: \.offset) { index, genre in
                        let emphasis = glyphRole(for: genre)
                        let (computedCenter, disk, icon) = glyphFrames(
                            genre: genre,
                            index: index,
                            in: geo.size,
                            idleCenters: idle.centers,
                            idleHub: idle.hub,
                            peripheryPlayingCenters: playingPeriphery
                        )
                        let anchor = emphasis == .hero ? hub : computedCenter

                        floatingGlyphButton(
                            genre: genre,
                            index: index,
                            baseCenter: anchor,
                            constellationHub: hub,
                            phase: t,
                            diskDiameter: disk,
                            iconSize: icon,
                            emphasis: emphasis,
                            action: { playGenreImmediately(genre) }
                        )
                        .zIndex(emphasis == .hero ? 50 : CGFloat(index))
                    }
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        residentAudio.stop()
                        selectedPlayingGenre = nil
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

            if let sg = selectedPlayingGenre {
                VStack {
                    Spacer()
                    Button {
                        residentAudio.stop()
                        state.prepareResidentImmersiveFromPlaylist(genre: sg)
                        selectedPlayingGenre = nil
                    } label: {
                        Label("Calm room visuals", systemImage: "leaf.fill")
                            .font(BrandTheme.title(.subheadline))
                            .fontWeight(.medium)
                            .foregroundStyle(BrandTheme.brown)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(BrandTheme.cream.opacity(0.94))
                                    .shadow(color: BrandTheme.brown.opacity(0.1), radius: 12, y: 5)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(BrandTheme.gold.opacity(0.38), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Leaves this screen for nature visuals.")
                    .padding(.bottom, 42)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(.spring(response: 0.52, dampingFraction: 0.82), value: selectedPlayingGenre)
        .onChange(of: state.selectedCarePatientId) { _, _ in
            selectedPlayingGenre = nil
            residentAudio.stop()
        }
        .onDisappear {
            residentAudio.stop()
        }
    }

    /// Rest drift, hero bloom, or **periphery** positions when another genre’s playlist is audible.
    private enum GlyphEmphasis {
        case idle
        case hero
        case sideStrip
    }

    private func glyphRole(for genre: ResidentMusicGenre) -> GlyphEmphasis {
        guard let sel = selectedPlayingGenre else { return .idle }
        return genre == sel ? .hero : .sideStrip
    }

    private func glyphFrames(
        genre: ResidentMusicGenre,
        index: Int,
        in size: CGSize,
        idleCenters: [CGPoint],
        idleHub: CGPoint,
        peripheryPlayingCenters: [CGPoint]
    ) -> (CGPoint, CGFloat, CGFloat) {
        let idleDisk: CGFloat = 92
        let idleIcon: CGFloat = 38
        let heroDisk = ResidentMusicGlyphSizing.heroDiskDiameter
        let heroIcon: CGFloat = 62
        let sideDisk: CGFloat = 64
        let sideIcon: CGFloat = 26

        switch glyphRole(for: genre) {
        case .idle:
            guard index < idleCenters.count else {
                return (idleHub, idleDisk, idleIcon)
            }
            return (idleCenters[index], idleDisk, idleIcon)
        case .hero:
            return (idleHub, heroDisk, heroIcon)
        case .sideStrip:
            guard let sg = selectedPlayingGenre else {
                guard index < idleCenters.count else {
                    return (idleHub, sideDisk, sideIcon)
                }
                return (idleCenters[index], sideDisk, sideIcon)
            }
            let inactiveOrdered = genresOnFile.filter { $0 != sg }
            guard let idx = inactiveOrdered.firstIndex(of: genre), idx < peripheryPlayingCenters.count else {
                guard index < idleCenters.count else {
                    return (idleHub, sideDisk, sideIcon)
                }
                return (idleCenters[index], sideDisk, sideIcon)
            }
            return (peripheryPlayingCenters[idx], sideDisk, sideIcon)
        }
    }

    private func playGenreImmediately(_ genre: ResidentMusicGenre) {
        guard let group = patient?.genrePlaylistGroups.first(where: { $0.genre == genre }),
              group.playlists.isEmpty == false
        else {
            return
        }
        let playlist = group.playlists.first(where: { !$0.trackTitles.isEmpty }) ?? group.playlists[0]
        _ = playlist // Binding for future per-playlist URLs; POC uses one calm streamed loop.

        withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
            selectedPlayingGenre = genre
        }
        residentAudio.stop()
        residentAudio.startFresh(photoAnchored: false)
    }

    private func floatingGlyphButton(
        genre: ResidentMusicGenre,
        index: Int,
        baseCenter: CGPoint,
        constellationHub: CGPoint,
        phase: TimeInterval,
        diskDiameter: CGFloat,
        iconSize: CGFloat,
        emphasis: GlyphEmphasis,
        action: @escaping () -> Void
    ) -> some View {
        let rawΔ = GlyphFloatLayout.animatedDelta(index: index, base: baseCenter, hub: constellationHub, phase: phase)
        /// Periphery icons still orbit the hull — drift can be lighter now that anchors sit farther out.
        let motionScale: CGFloat =
            emphasis == .sideStrip ? 0.58 : emphasis == .hero ? 0.82 : 1
        let Δ = CGSize(width: rawΔ.width * motionScale, height: rawΔ.height * motionScale)
        let pos = CGPoint(x: baseCenter.x + Δ.width, y: baseCenter.y + Δ.height)
        let rot = GlyphFloatLayout.rotationDynamics(index: index, phase: phase)
        let driftScale = GlyphFloatLayout.scalePulse(index: index, phase: phase)
        let roleScale: CGFloat =
            emphasis == .hero ? 1.02 : emphasis == .sideStrip ? 0.98 : 1
        let endR = diskDiameter * 0.62

        return Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                genre.accent.opacity(emphasis == .hero ? 0.58 : 0.46),
                                BrandTheme.cream.opacity(emphasis == .hero ? 0.95 : 0.92),
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: endR
                        )
                    )
                    .frame(width: diskDiameter, height: diskDiameter)
                    .shadow(color: BrandTheme.brown.opacity(emphasis == .hero ? 0.12 : 0.06), radius: emphasis == .hero ? 26 : 12, y: emphasis == .hero ? 14 : 6)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: emphasis == .hero
                                        ? [BrandTheme.gold.opacity(0.72), BrandTheme.goldSoft.opacity(0.4)]
                                        : [BrandTheme.gold.opacity(0.52), BrandTheme.goldSoft.opacity(0.22)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: emphasis == .hero ? 1.4 : 1
                            )
                    )
                Image(systemName: genre.iconName)
                    .font(.system(size: iconSize, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrandTheme.brown.opacity(0.48), BrandTheme.brown.opacity(0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(genre.accessibilityLabel)
        .accessibilityAddTraits(selectedPlayingGenre == genre ? .isSelected : [])
        .position(x: pos.x, y: pos.y)
        .rotationEffect(.degrees(rot))
        .scaleEffect(driftScale * roleScale, anchor: .center)
    }
}


