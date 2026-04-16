import AVFoundation
import Combine
import SwiftUI

/// Plays a **royalty-free nature “compilation”** — sequenced HD clips from [Mixkit](https://mixkit.co/license/#videoFree).
/// Clip **order is shuffled per `mediaSessionID`** so each session (especially with a photo anchor) gets a fresh visual sequence.
enum NatureVideoCompilation {
    static let mixkitClipURLs: [URL] = [
        URL(string: "https://assets.mixkit.co/videos/5038/5038-720.mp4")!,
        URL(string: "https://assets.mixkit.co/videos/2363/2363-720.mp4")!,
        URL(string: "https://assets.mixkit.co/videos/40657/40657-720.mp4")!,
        URL(string: "https://assets.mixkit.co/videos/1164/1164-720.mp4")!,
    ]

    /// Deterministic shuffle from session id — same id ⇒ same order (used for replay).
    static func clipPlaylist(seed: UUID) -> [URL] {
        var urls = mixkitClipURLs
        var rng = SeededRandomNumberGenerator(seed: seed)
        urls.shuffle(using: &rng)
        return urls
    }
}

/// Seeded shuffle so replay can reproduce the same sequence.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UUID) {
        var h = Hasher()
        seed.hash(into: &h)
        let v = Int(truncatingIfNeeded: h.finalize())
        state = UInt64(bitPattern: Int64(v))
        if state == 0 { state = 0x9E37_79B9_7F4A_7C15 }
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}

final class NatureCompilationSession: ObservableObject {
    private(set) var queuePlayer = AVQueuePlayer()
    var player: AVPlayer { queuePlayer }

    private let clipURLs: [URL]
    private var endObserver: NSObjectProtocol?

    init(clipURLs: [URL]) {
        self.clipURLs = clipURLs.isEmpty ? NatureVideoCompilation.mixkitClipURLs : clipURLs
    }

    func prepareAndPlay() {
        queuePlayer.removeAllItems()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .advance
        enqueueRound()
        queuePlayer.play()
    }

    func pause() {
        queuePlayer.pause()
    }

    private func enqueueRound() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            endObserver = nil
        }

        let items = clipURLs.map { AVPlayerItem(url: $0) }
        guard let last = items.last else { return }

        for item in items {
            queuePlayer.insert(item, after: nil)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: last,
            queue: .main
        ) { [weak self] _ in
            self?.onCompilationRoundEnded()
        }
    }

    private func onCompilationRoundEnded() {
        enqueueRound()
        queuePlayer.play()
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
}

struct NatureVideoCompilationView: View {
    let mediaSessionID: UUID

    @StateObject private var session: NatureCompilationSession

    init(mediaSessionID: UUID) {
        self.mediaSessionID = mediaSessionID
        let clips = NatureVideoCompilation.clipPlaylist(seed: mediaSessionID)
        _session = StateObject(wrappedValue: NatureCompilationSession(clipURLs: clips))
    }

    var body: some View {
        NatureVideoPlayerRepresentable(player: session.player)
            .ignoresSafeArea()
            .onAppear {
                session.prepareAndPlay()
            }
            .onDisappear {
                session.pause()
            }
            .id(mediaSessionID)
    }
}

private struct NatureVideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerHostingView {
        let v = PlayerHostingView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PlayerHostingView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerHostingView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
