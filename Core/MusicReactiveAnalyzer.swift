import AVFoundation
import Accelerate
import MediaToolbox

/// Live audio levels derived from PCM during AVPlayer playback — drives equalizer rings + orb pulse.
struct MusicReactiveSnapshot: Equatable {
    static let bandCount = OrbEqualizerMotion.barCount

    var bands: [CGFloat] = Array(repeating: 0.15, count: bandCount)
    var pulse: Double = 0.5
    var glow: Double = 0.72
    var isActive: Bool = false

    static let idle = MusicReactiveSnapshot()
}

// MARK: - Tap context (process callback runs on realtime thread)

final class MusicReactiveTapContext: @unchecked Sendable {
    weak var owner: MusicReactiveAnalyzer?
    var streamDescription: AudioStreamBasicDescription?
    private var smoothedBands = [Float](repeating: 0.15, count: MusicReactiveSnapshot.bandCount)
    private var smoothedPulse: Float = 0.5
    private var smoothedGlow: Float = 0.72
    private var lastPublishTime: CFAbsoluteTime = 0
    // ~24fps to SwiftUI: smooth visually, far less main-thread churn than 60fps.
    private let publishInterval: CFAbsoluteTime = 1.0 / 24.0

    // Reused across callbacks so the realtime audio thread never allocates per buffer.
    private var monoBuffer = [Float]()
    private var rawBands = [Float](repeating: 0, count: MusicReactiveSnapshot.bandCount)

    /// Log-spaced target frequencies for a 32-band “equalizer” readout.
    private static let bandCenterHz: [Double] = {
        let low = 90.0
        let high = 7_800.0
        let count = MusicReactiveSnapshot.bandCount
        return (0 ..< count).map { i in
            let t = Double(i) / Double(max(1, count - 1))
            return low * pow(high / low, t)
        }
    }()

    func ingest(bufferList: UnsafePointer<AudioBufferList>, frameCount: CMItemCount) {
        guard frameCount > 0, let owner else { return }

        let buffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: bufferList))
        guard let first = buffers.first, let data = first.mData else { return }

        let sampleCount = Int(frameCount)
        guard sampleCount > 0 else { return }

        // Reuse the buffer across callbacks — keeps capacity, no per-callback heap allocation.
        monoBuffer.removeAll(keepingCapacity: true)
        if monoBuffer.capacity < sampleCount {
            monoBuffer.reserveCapacity(sampleCount)
        }

        if let asbd = streamDescription, asbd.mFormatFlags & kAudioFormatFlagIsFloat != 0 {
            let channels = max(1, Int(asbd.mChannelsPerFrame))
            let floats = data.assumingMemoryBound(to: Float.self)
            if channels == 1 {
                monoBuffer.append(contentsOf: UnsafeBufferPointer(start: floats, count: sampleCount))
            } else {
                let inv = 1 / Float(channels)
                for i in 0 ..< sampleCount {
                    var sum: Float = 0
                    for ch in 0 ..< channels {
                        sum += floats[i * channels + ch]
                    }
                    monoBuffer.append(sum * inv)
                }
            }
        } else {
            let channels = max(1, Int(first.mNumberChannels))
            let samples = data.assumingMemoryBound(to: Int16.self)
            let frames = Int(first.mDataByteSize) / (MemoryLayout<Int16>.size * channels)
            let inv = 1 / (Float(Int16.max) * Float(channels))
            for i in 0 ..< frames {
                var sum: Float = 0
                for ch in 0 ..< channels {
                    sum += Float(samples[i * channels + ch])
                }
                monoBuffer.append(sum * inv)
            }
        }

        guard monoBuffer.isEmpty == false else { return }

        let sampleRate = streamDescription.map { Double($0.mSampleRate) } ?? 44_100

        monoBuffer.withUnsafeBufferPointer { mono in
            var rms: Float = 0
            vDSP_rmsqv(mono.baseAddress!, 1, &rms, vDSP_Length(mono.count))
            let clampedRMS = min(1, max(0, rms * 6.5))

            let bandCount = MusicReactiveSnapshot.bandCount
            for i in 0 ..< bandCount {
                let mag = Self.goertzelMagnitude(mono, sampleRate: sampleRate, targetHz: Self.bandCenterHz[i])
                rawBands[i] = min(1, mag * 9.5)
            }
            finishAnalysis(clampedRMS: clampedRMS)
        }
    }

    private func finishAnalysis(clampedRMS: Float) {
        guard let owner else { return }
        let bandCount = MusicReactiveSnapshot.bandCount

        let smooth: Float = 0.52
        let snap: Float = 1 - smooth
        for i in 0 ..< bandCount {
            smoothedBands[i] = smoothedBands[i] * smooth + rawBands[i] * snap
        }

        let peak = rawBands.max() ?? clampedRMS
        smoothedPulse = smoothedPulse * 0.72 + peak * 0.28
        smoothedGlow = smoothedGlow * 0.76 + clampedRMS * 0.24

        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastPublishTime >= publishInterval else { return }
        lastPublishTime = now

        let snapshot = MusicReactiveSnapshot(
            bands: smoothedBands.map { CGFloat(min(1, max(0.1, $0))) },
            pulse: Double(min(1, max(0.08, smoothedPulse))),
            glow: Double(min(1, max(0.45, 0.45 + smoothedGlow * 0.55))),
            isActive: true
        )
        owner.publish(snapshot)
    }

    /// Single-bin energy at `targetHz` — lightweight stand-in for a full FFT on the audio thread.
    private static func goertzelMagnitude(_ samples: UnsafeBufferPointer<Float>, sampleRate: Double, targetHz: Double) -> Float {
        let count = samples.count
        guard count > 8, sampleRate > 0, targetHz > 0 else { return 0 }
        let k = Int(0.5 + Double(count) * targetHz / sampleRate)
        let omega = 2 * Double.pi * Double(k) / Double(count)
        let coeff = 2 * cos(omega)
        var s0 = 0.0
        var s1 = 0.0
        var s2 = 0.0
        for sample in samples {
            s0 = Double(sample) + coeff * s1 - s2
            s2 = s1
            s1 = s0
        }
        let power = s1 * s1 + s2 * s2 - coeff * s1 * s2
        return Float(sqrt(max(0, power))) / Float(count)
    }

    func reset() {
        smoothedBands = [Float](repeating: 0.15, count: MusicReactiveSnapshot.bandCount)
        smoothedPulse = 0.5
        smoothedGlow = 0.72
        lastPublishTime = 0
    }
}

// MARK: - Analyzer (MainActor-facing)

@MainActor
final class MusicReactiveAnalyzer {
    private let context = MusicReactiveTapContext()
    private var onUpdate: ((MusicReactiveSnapshot) -> Void)?

    init() {
        context.owner = self
    }

    func setUpdateHandler(_ handler: @escaping (MusicReactiveSnapshot) -> Void) {
        onUpdate = handler
    }

    /// Applies the processing tap to `item` before playback / looper setup (fast, synchronous).
    @discardableResult
    func applyMixIfPossible(to item: AVPlayerItem) -> Bool {
        let asset = item.asset
        let tracks = asset.tracks(withMediaType: .audio)
        guard let track = tracks.first,
              let mix = Self.buildAudioMix(track: track, context: context)
        else { return false }
        item.audioMix = mix
        return true
    }

    func detach(clearPublished: Bool = true) {
        context.reset()
        if clearPublished {
            publish(.idle)
        }
    }

    fileprivate nonisolated func publish(_ snapshot: MusicReactiveSnapshot) {
        Task { @MainActor in
            onUpdate?(snapshot)
        }
    }

    private static func buildAudioMix(track: AVAssetTrack, context: MusicReactiveTapContext) -> AVMutableAudioMix? {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: Unmanaged.passUnretained(context).toOpaque(),
            init: tapInit,
            finalize: tapFinalize,
            prepare: tapPrepare,
            unprepare: tapUnprepare,
            process: tapProcess
        )

        var tap: MTAudioProcessingTap?
        let status = MTAudioProcessingTapCreate(
            kCFAllocatorDefault,
            &callbacks,
            kMTAudioProcessingTapCreationFlag_PostEffects,
            &tap
        )
        guard status == noErr, let tap else { return nil }

        let params = AVMutableAudioMixInputParameters(track: track)
        params.audioTapProcessor = tap

        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [params]
        return audioMix
    }
}

// MARK: - MTAudioProcessingTap callbacks

private func tapInit(
    _ tap: MTAudioProcessingTap,
    clientInfo: UnsafeMutableRawPointer?,
    tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) {
    tapStorageOut.pointee = clientInfo
}

private func tapFinalize(_ tap: MTAudioProcessingTap) {}

private func tapPrepare(
    _ tap: MTAudioProcessingTap,
    maxFrames: CMItemCount,
    processingFormat: UnsafePointer<AudioStreamBasicDescription>
) {
    let storage = MTAudioProcessingTapGetStorage(tap)
    let context = Unmanaged<MusicReactiveTapContext>.fromOpaque(storage).takeUnretainedValue()
    context.streamDescription = processingFormat.pointee
}

private func tapUnprepare(_ tap: MTAudioProcessingTap) {
    let storage = MTAudioProcessingTapGetStorage(tap)
    let context = Unmanaged<MusicReactiveTapContext>.fromOpaque(storage).takeUnretainedValue()
    context.streamDescription = nil
}

private func tapProcess(
    _ tap: MTAudioProcessingTap,
    numberFrames: CMItemCount,
    flags: MTAudioProcessingTapFlags,
    bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
    numberFramesOut: UnsafeMutablePointer<CMItemCount>,
    flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
    // CRITICAL: pull the source audio into the output buffer. This both keeps playback
    // audible (the tap passes audio through) and gives us PCM to analyse. Skipping this
    // call leaves the output buffer empty → silence.
    let status = MTAudioProcessingTapGetSourceAudio(
        tap,
        numberFrames,
        bufferListInOut,
        flagsOut,
        nil,
        numberFramesOut
    )
    guard status == noErr else { return }

    let storage = MTAudioProcessingTapGetStorage(tap)
    let context = Unmanaged<MusicReactiveTapContext>.fromOpaque(storage).takeUnretainedValue()
    context.ingest(bufferList: bufferListInOut, frameCount: numberFramesOut.pointee)
}
