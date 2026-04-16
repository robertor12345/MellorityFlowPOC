import AVFoundation
import Combine

/// Streams calm ambient audio from the internet (SoundHelix chill-out example — see README).
/// No extra synthesized layer — a previous ~9 kHz “air” sine read as an unpleasant whine on device speakers.
final class AmbientAudioSession: ObservableObject {
    private var didStart = false
    /// SoundHelix Song 8 — “Spy vs. Spy - Chill-out Acid Squeeze Mix” (calmer bed than Song 1).
    static let streamURL = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3")!

    private static let streamVolume: Float = 0.26

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
