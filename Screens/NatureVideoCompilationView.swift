import AVFoundation
import Combine
import SwiftUI

/// Plays a **royalty-free nature “compilation”** — sequenced HD clips from [Mixkit](https://mixkit.co/license/#videoFree) (free for personal & commercial use per their license).
/// Video is **muted**; session music comes from `AmbientAudioSession`.
enum NatureVideoCompilation {
    /// Forest lake, park trees, sunlit meadow, water ripples — loops as a playlist.
    static let mixkitClipURLs: [URL] = [
        URL(string: "https://assets.mixkit.co/videos/5038/5038-720.mp4")!, // Beautiful lake in a quiet forest
        URL(string: "https://assets.mixkit.co/videos/2363/2363-720.mp4")!, // Nature in the park
        URL(string: "https://assets.mixkit.co/videos/40657/40657-720.mp4")!, // Meadow, grass & trees
        URL(string: "https://assets.mixkit.co/videos/1164/1164-720.mp4")!, // Waves in the water
    ]
}

final class NatureCompilationSession: ObservableObject {
    private(set) var player = AVPlayer()
    private var endObserver: NSObjectProtocol?
    private var index = 0

    func prepareAndPlay() {
        player.isMuted = true
        index = 0
        playClip(at: 0)
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.play()
    }

    private func playClip(at i: Int) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        let url = NatureVideoCompilation.mixkitClipURLs[i]
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.index = (self.index + 1) % NatureVideoCompilation.mixkitClipURLs.count
            self.playClip(at: self.index)
        }

        player.play()
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
