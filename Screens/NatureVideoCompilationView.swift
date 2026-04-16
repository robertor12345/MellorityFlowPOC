import AVFoundation
import Combine
import SwiftUI

/// Plays a **royalty-free nature “compilation”** — sequenced HD clips from [Mixkit](https://mixkit.co/license/#videoFree).
/// Uses `AVQueuePlayer`: when the round finishes, the same clips are **re-queued** so playback **loops until the session ends** (video is **muted**; music is `AmbientAudioSession`).
enum NatureVideoCompilation {
    /// Forest lake, park trees, sunlit meadow, water ripples — cycles repeatedly.
    static let mixkitClipURLs: [URL] = [
        URL(string: "https://assets.mixkit.co/videos/5038/5038-720.mp4")!, // Beautiful lake in a quiet forest
        URL(string: "https://assets.mixkit.co/videos/2363/2363-720.mp4")!, // Nature in the park
        URL(string: "https://assets.mixkit.co/videos/40657/40657-720.mp4")!, // Meadow, grass & trees
        URL(string: "https://assets.mixkit.co/videos/1164/1164-720.mp4")!, // Waves in the water
    ]
}

final class NatureCompilationSession: ObservableObject {
    /// Subclass of `AVPlayer` — same layer binding, better queue control.
    private(set) var queuePlayer = AVQueuePlayer()

    /// Exposed for `AVPlayerLayer` (`AVQueuePlayer` is an `AVPlayer`).
    var player: AVPlayer { queuePlayer }

    private var endObserver: NSObjectProtocol?

    func prepareAndPlay() {
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .advance
        enqueueRound()
        queuePlayer.play()
    }

    func pause() {
        queuePlayer.pause()
    }

    /// Inserts one full compilation after any current queued items; wires loop when the **last** clip ends.
    private func enqueueRound() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        let items = NatureVideoCompilation.mixkitClipURLs.map { AVPlayerItem(url: $0) }
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

    /// When the final clip in this round ends, `AVQueuePlayer` has drained — enqueue another seamless **cycle**.
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
    @StateObject private var session = NatureCompilationSession()

    var body: some View {
        NatureVideoPlayerRepresentable(player: session.player)
            .ignoresSafeArea()
            .onAppear {
                session.prepareAndPlay()
            }
            .onDisappear {
                session.pause()
            }
    }
}

/// Full-bleed `AVPlayerLayer` (no controls, aspect fill).
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
