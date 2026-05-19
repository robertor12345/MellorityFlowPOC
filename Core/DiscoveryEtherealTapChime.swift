import AVFoundation

/// Soft, fleeting bell-like swell for discovery mood taps (synthesised — no bundled assets).
enum DiscoveryEtherealTapChime {
    /// ~0.4s decay at low level; honours main-actor AudioEngine use from SwiftUI taps.
    @MainActor
    static func playLight() {
        DiscoveryEtherealTapChimeEngine.shared.trigger()
    }
}

@MainActor
private final class DiscoveryEtherealTapChimeEngine {
    static let shared = DiscoveryEtherealTapChimeEngine()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.42
    }

    func trigger() {
        do {
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            return
        }

        let sr = format.sampleRate
        let duration: TimeInterval = 0.44
        let frameCount = AVAudioFrameCount(sr * duration)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return }

        buffer.frameLength = frameCount

        guard let ch = buffer.floatChannelData?.pointee else { return }

        // Airy fifth + gentle overtone — fast rise, slow ethereal tail.
        let f1 = 784.0
        let f2 = f1 * 1.498 // ~perfect fifth shimmer
        let f3 = f1 * 2.015

        for i in 0 ..< Int(frameCount) {
            let t = Double(i) / sr
            let attack = min(1, t / 0.026)
            let decay = exp(-t * 4.95)
            let env = attack * decay
            let swirl = sin(2 * Double.pi * 9.7 * t) * 0.11
            let body =
                sin(2 * Double.pi * f1 * t) * 0.74
                    + sin(2 * Double.pi * f2 * t) * 0.42
                    + sin(2 * Double.pi * f3 * t) * 0.14
            ch[i] = Float(body * env * (1 + swirl) * 0.07)
        }

        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }
}
