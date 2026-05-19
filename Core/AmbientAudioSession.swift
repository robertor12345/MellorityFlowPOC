import AVFoundation
import Combine

/// Streams **looping ambient music** (`AVPlayerLooper`) until `stop()`.
///
/// **Immersive / resident calm loops:**
/// - **Quick Start:** Morsi — [`song_2.mp3`](https://opengameart.org/content/calm-music) (CC0).
/// - **Photo-anchor:** YannZ — Indie Meditations [`lvl_5_the_oasis_or_resting_place.mp3`](https://opengameart.org/content/indie-meditations-free-music-pack)
///   (CC BY 4.0 — see pack readme). On load failure → `song_2.mp3`.
///
/// **Listening discovery snippets:** sequential **retro / 1950s-style** cues from incompetech — see `DiscoveryFlowPOC` (CC BY Kevin MacLeod). On failure → calm `song_2.mp3` so the calibration pass keeps running.
@MainActor
final class AmbientAudioSession: ObservableObject {
    static let quickStartStreamURL = URL(string: "https://opengameart.org/sites/default/files/song_2.mp3")!

    /// Oasis / resting-place loop from the *Indie Meditations* pack (meditation ambience).
    static let photoAnchorStreamURL =
        URL(string: "https://opengameart.org/sites/default/files/lvl_5_the_oasis_or_resting_place.mp3")!

    private static let streamVolume: Float = 0.38

    var volumeMultiplier: Float = 1

    private var activeStreamURL = AmbientAudioSession.quickStartStreamURL
    private var playbackFallbackURL: URL?
    private var triedStreamFallback = false

    @Published var isMuted = false {
        didSet { applyMute() }
    }

    private var queuePlayer: AVQueuePlayer?
    private var audioLooper: AVPlayerLooper?
    private var statusObservation: NSKeyValueObservation?

    func startFresh(photoAnchored: Bool = false) {
        stop()
        triedStreamFallback = false
        if photoAnchored {
            activeStreamURL = Self.photoAnchorStreamURL
            playbackFallbackURL = Self.quickStartStreamURL
        } else {
            activeStreamURL = Self.quickStartStreamURL
            playbackFallbackURL = nil
        }
        configureSession()
        startStream()
    }

    /// Loops streamed audio at `streamURL`; if the asset fails (network, CDN), retries once using `quickStartStreamURL`.
    func startFresh(streamURL: URL) {
        stop()
        triedStreamFallback = false
        activeStreamURL = streamURL
        playbackFallbackURL = Self.quickStartStreamURL
        configureSession()
        startStream()
    }

    /// Pause the current stream without tearing down the looper (playlist POC controls).
    func pausePlayback() {
        queuePlayer?.pause()
    }

    /// Resume after `pausePlayback()`.
    func resumePlayback() {
        queuePlayer?.play()
    }

    func stop() {
        tearDownPlaybackOnly()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? audioSession.setActive(true)
    }

    private func startStream() {
        statusObservation?.invalidate()
        statusObservation = nil

        let item = AVPlayerItem(url: activeStreamURL)
        item.preferredForwardBufferDuration = 4

        let qp = AVQueuePlayer()
        qp.automaticallyWaitsToMinimizeStalling = true
        qp.volume = effectiveVolume
        audioLooper = AVPlayerLooper(player: qp, templateItem: item)
        queuePlayer = qp
        qp.play()

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            guard let self else { return }
            Task { @MainActor in
                self.handleItemStatus(observed.status)
            }
        }
    }

    private func handleItemStatus(_ status: AVPlayerItem.Status) {
        guard status == .failed else { return }
        guard let fallback = playbackFallbackURL, !triedStreamFallback else { return }
        triedStreamFallback = true
        tearDownPlaybackOnly()
        activeStreamURL = fallback
        playbackFallbackURL = nil
        startStream()
    }

    private func tearDownPlaybackOnly() {
        statusObservation?.invalidate()
        statusObservation = nil
        audioLooper = nil
        queuePlayer?.pause()
        queuePlayer = nil
    }

    private var effectiveVolume: Float {
        isMuted ? 0 : Self.streamVolume * volumeMultiplier
    }

    private func applyMute() {
        queuePlayer?.volume = effectiveVolume
    }
}
