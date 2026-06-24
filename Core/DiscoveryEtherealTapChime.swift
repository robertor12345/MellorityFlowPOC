import AVFoundation

/// Soft, fleeting bell-like swell for discovery mood taps (synthesised — no bundled assets).
enum DiscoveryEtherealTapChime {
    /// ~0.4s decay at low level; honours main-actor AudioEngine use from SwiftUI taps.
    @MainActor
    static func playLight() {
        DiscoveryEtherealTapChimeEngine.shared.trigger(variant: .light)
    }

    @MainActor
    static func playSuccess() {
        DiscoveryEtherealTapChimeEngine.shared.trigger(variant: .success)
    }
}

@MainActor
private final class DiscoveryEtherealTapChimeEngine {
    static let shared = DiscoveryEtherealTapChimeEngine()

    enum Variant { case light, success }

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.42
    }

    func trigger(variant: Variant = .light) {
        do {
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            return
        }

        let sr = format.sampleRate
        let duration: TimeInterval = variant == .success ? 0.72 : 0.44
        let frameCount = AVAudioFrameCount(sr * duration)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return }

        buffer.frameLength = frameCount

        guard let ch = buffer.floatChannelData?.pointee else { return }

        let (f1, f2, f3, volume, decayRate): (Double, Double, Double, Double, Double) = {
            switch variant {
            case .light:
                return (784.0, 784.0 * 1.498, 784.0 * 2.015, 0.07, 4.95)
            case .success:
                return (392.0, 392.0 * 1.335, 392.0 * 2.0, 0.09, 3.35)
            }
        }()

        for i in 0 ..< Int(frameCount) {
            let t = Double(i) / sr
            let attack = min(1, t / (variant == .success ? 0.04 : 0.026))
            let decay = exp(-t * decayRate)
            let env = attack * decay
            let swirl = sin(2 * Double.pi * 9.7 * t) * (variant == .success ? 0.06 : 0.11)
            let body =
                sin(2 * Double.pi * f1 * t) * 0.74
                    + sin(2 * Double.pi * f2 * t) * 0.42
                    + sin(2 * Double.pi * f3 * t) * 0.14
            ch[i] = Float(body * env * (1 + swirl) * volume)
        }

        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }
}
