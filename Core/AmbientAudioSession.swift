import AVFoundation
import Combine

/// Streams meditation-style ambient music (see README for license / fallback).
/// No extra synthesized layer — a previous ~9 kHz “air” sine read as an unpleasant whine on device speakers.
final class AmbientAudioSession: ObservableObject {
    private var didStart = false

    /// CC0 calm bed — Morsi, [OpenGameArt](https://opengameart.org/content/calm-music) (`song_2.mp3`). Replace with a bundled asset for offline / production if you prefer.
    static let streamURL = URL(string: "https://opengameart.org/sites/default/files/song_2.mp3")!

    private static let streamVolume: Float = 0.22

    @Published var isMuted = false {
        didSet { applyMute() }
    }

    private var streamPlayer: AVPlayer?
    private var loopObserver: Any?

    func start() {
        guard !didStart else { return }
        didStart = true
        configureSession()
        startStream()
    }

    func stop() {
        didStart = false
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObserver = nil
        streamPlayer?.pause()
        streamPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func startStream() {
        let item = AVPlayerItem(url: Self.streamURL)
        let player = AVPlayer(playerItem: item)
        player.volume = isMuted ? 0 : Self.streamVolume
        player.actionAtItemEnd = .none
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        player.play()
        streamPlayer = player
    }

    private func applyMute() {
        streamPlayer?.volume = isMuted ? 0 : Self.streamVolume
    }
}
