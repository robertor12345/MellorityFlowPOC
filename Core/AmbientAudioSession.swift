import AVFoundation
import Combine

/// Streams calm ambient audio from the internet (SoundHelix example — see README license note)
/// and adds a very quiet high-frequency sine “air” layer synthesized on-device (not streamed).
final class AmbientAudioSession: ObservableObject {
    private var didStart = false
    /// Public example MP3; reachable without API keys (used widely for demos).
    static let streamURL = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!

    @Published var isMuted = false {
        didSet { applyMute() }
    }

    private var streamPlayer: AVPlayer?
    private var loopObserver: Any?
    private var engine: AVAudioEngine?
    private let hfPhase = HFPhaseAccumulator()

    func start() {
        guard !didStart else { return }
        didStart = true
        configureSession()
        startStream()
        startHighFrequencyAir()
    }

    func stop() {
        didStart = false
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObserver = nil
        streamPlayer?.pause()
        streamPlayer = nil
        engine?.stop()
        engine = nil
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
        player.volume = isMuted ? 0 : 0.28
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

    private func startHighFrequencyAir() {
        let engine = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let holder = hfPhase
        let freq: Double = 9_200

        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            // Real-time callback: fill mono buffer with ~9.2 kHz sine (subtle “air”).
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let step = 2 * Double.pi * freq / 44_100
            for i in 0 ..< Int(frameCount) {
                holder.phase += step
                if holder.phase > 2 * Double.pi { holder.phase -= 2 * Double.pi }
                let sample = Float(sin(holder.phase) * 0.035)
                for buffer in abl {
                    guard let raw = buffer.mData else { continue }
                    let ptr = raw.assumingMemoryBound(to: Float.self)
                    ptr[i] = sample
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.volume = isMuted ? 0 : 0.45

        do {
            try engine.start()
            self.engine = engine
        } catch {
            self.engine = nil
        }
    }

    private func applyMute() {
        streamPlayer?.volume = isMuted ? 0 : 0.28
        engine?.mainMixerNode.volume = isMuted ? 0 : 0.45
    }
}

private final class HFPhaseAccumulator: @unchecked Sendable {
    var phase: Double = 0
}
