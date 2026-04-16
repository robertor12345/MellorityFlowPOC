import AVFoundation
import Combine

/// Streams meditation-style ambient music (see README for license / fallback).
/// Uses `AVPlayerLooper` for **gapless** looping until `stop()` — no seek-to-zero hitch at loop points.
///
/// **POC:** Photo-anchored sessions use a **different, reliably streamable** URL than Quick Start (Mixkit preview
/// links were flaky in AVPlayer). If the alternate stream fails to load, we **fall back** to the Quick Start track.
@MainActor
final class AmbientAudioSession: ObservableObject {
    /// Quick Start / mood-only — CC0 calm bed on OpenGameArt (same host as README).
    static let quickStartStreamURL = URL(string: "https://opengameart.org/sites/default/files/song_2.mp3")!

    /// Photo-anchor — distinct orchestrated demo MP3 (widely used for streaming tests; HTTPS).
    /// Falls back to `quickStartStreamURL` if the player item fails.
    static let photoAnchorStreamURL = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!

    private static let streamVolume: Float = 0.38

    var volumeMultiplier: Float = 1

    private var activeStreamURL = AmbientAudioSession.quickStartStreamURL
    private var triedPhotoFallback = false

    @Published var isMuted = false {
        didSet { applyMute() }
    }

    private var queuePlayer: AVQueuePlayer?
    private var audioLooper: AVPlayerLooper?
    private var statusObservation: NSKeyValueObservation?

    func startFresh(photoAnchored: Bool = false) {
        stop()
        triedPhotoFallback = false
        activeStreamURL = photoAnchored ? Self.photoAnchorStreamURL : Self.quickStartStreamURL
        configureSession()
        startStream(allowPhotoFallback: photoAnchored)
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

    private func startStream(allowPhotoFallback: Bool) {
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
                self.handleItemStatus(observed.status, allowPhotoFallback: allowPhotoFallback)
            }
        }
    }

    private func handleItemStatus(_ status: AVPlayerItem.Status, allowPhotoFallback: Bool) {
        guard status == .failed else { return }
        guard allowPhotoFallback, !triedPhotoFallback else { return }
        triedPhotoFallback = true
        tearDownPlaybackOnly()
        activeStreamURL = Self.quickStartStreamURL
        startStream(allowPhotoFallback: false)
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
