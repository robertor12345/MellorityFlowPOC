import AVFoundation

/// Single source of truth for the shared `AVAudioSession` lifecycle.
///
/// Both ambient music (`AVPlayer`) and UI chimes (`AVAudioEngine`) route through here so they
/// never fight over category/activation. Activation is idempotent and only re-applies when needed.
@MainActor
enum AppAudioSession {
    private static var categoryConfigured = false
    private static var isActive = false

    /// Ensures the session is configured for mixed playback and active. Safe to call repeatedly.
    @discardableResult
    static func activate() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            if !categoryConfigured {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                categoryConfigured = true
            }
            if !isActive {
                try session.setActive(true)
                isActive = true
            }
            return true
        } catch {
            // Reset so the next call retries a full configure + activate.
            categoryConfigured = false
            isActive = false
            return false
        }
    }

    /// Marks the session inactive without tearing down playback ownership.
    /// Rarely needed — kept warm by default so UI chimes always work.
    static func deactivate() {
        guard isActive else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isActive = false
    }
}
