import AVFoundation
import Combine

/// Streams meditation-style ambient music (see README for license / fallback).
/// Uses `AVPlayerLooper` for **gapless** looping until `stop()` — no seek-to-zero hitch at loop points.
///
/// **POC:** Photo-anchored sessions use a different stream than Quick Start so audio clearly differs by path.
final class AmbientAudioSession: ObservableObject {
    private var didStart = false

    /// Quick Start / mood-only path — Morsi / OpenGameArt “calm music” (`song_2.mp3`).
    static let quickStartStreamURL = URL(string: "https://opengameart.org/sites/default/files/song_2.mp3")!

    /// Photo-anchor path — Mixkit preview bed (distinct tone from Quick Start).
    static let photoAnchorStreamURL = URL(string: "https://assets.mixkit.co/music/preview/mixkit-dreaming-big-31.mp3")!

    private static let streamVolume: Float = 0.22

    /// Applied to stream volume (e.g. replay vs live session).
    var volumeMultiplier: Float = 1

    private var activeStreamURL: URL = Self.quickStartStreamURL

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

    /// Tears down the looper and starts a **new** stream — `photoAnchored` picks the POC’s alternate ambience.
    func startFresh(photoAnchored: Bool = false) {
        stop()
        activeStreamURL = photoAnchored ? Self.photoAnchorStreamURL : Self.quickStartStreamURL
        start()
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
        let item = AVPlayerItem(url: activeStreamURL)
        let qp = AVQueuePlayer()
        qp.volume = effectiveVolume
        audioLooper = AVPlayerLooper(player: qp, templateItem: item)
        qp.play()
        queuePlayer = qp
    }

    private var effectiveVolume: Float {
        isMuted ? 0 : Self.streamVolume * volumeMultiplier
    }

    private func applyMute() {
        queuePlayer?.volume = effectiveVolume
    }
}
