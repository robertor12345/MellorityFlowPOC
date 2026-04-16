import AVFoundation
import Combine

/// Streams meditation-style ambient music (see README for license / fallback).
/// Uses `AVPlayerLooper` for **gapless** looping until `stop()` — no seek-to-zero hitch at loop points.
final class AmbientAudioSession: ObservableObject {
    private var didStart = false

    /// CC0 calm bed — Morsi / OpenGameArt “calm music” (`song_2.mp3`). Replace with a bundled asset for offline or production if you prefer.
    static let streamURL = URL(string: "https://opengameart.org/sites/default/files/song_2.mp3")!

    private static let streamVolume: Float = 0.22

    @Published var isMuted = false {
        didSet { applyMute() }
    }

    private var queuePlayer: AVQueuePlayer?
    private var audioLooper: AVPlayerLooper?

    func start() {
        guard !didStart else { return }
        didStart = true
        configureSession()
        startStream()
    }

    func stop() {
        didStart = false
        audioLooper = nil
        queuePlayer?.pause()
        queuePlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func startStream() {
        let item = AVPlayerItem(url: Self.streamURL)
        let qp = AVQueuePlayer()
        qp.volume = isMuted ? 0 : Self.streamVolume
        audioLooper = AVPlayerLooper(player: qp, templateItem: item)
        qp.play()
        queuePlayer = qp
    }

    private func applyMute() {
        queuePlayer?.volume = isMuted ? 0 : Self.streamVolume
    }
}
