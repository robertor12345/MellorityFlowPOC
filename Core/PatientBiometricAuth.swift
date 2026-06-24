import LocalAuthentication

enum PatientBiometricAuth {
    /// POC: simulate Face ID — no device enrollment required.
    static let usesPOCMockFlow = true

    enum AuthFailure: LocalizedError {
        case notAvailable
        case cancelled
        case failed

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return nil
            case .cancelled:
                return "Sign-in was cancelled."
            case .failed:
                return "We could not verify your identity."
            }
        }
    }

    static var isAvailable: Bool {
        if usesPOCMockFlow { return true }
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static var biometryLabel: String {
        if usesPOCMockFlow { return "Face ID" }
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Biometrics"
        }
    }

    static func authenticate(reason: String) async throws {
        if usesPOCMockFlow {
            try await Task.sleep(nanoseconds: 650_000_000)
            return
        }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthFailure.notAvailable
        }

        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if !ok { throw AuthFailure.failed }
        } catch let laError as LAError where laError.code == .userCancel || laError.code == .appCancel || laError.code == .systemCancel {
            throw AuthFailure.cancelled
        } catch is AuthFailure {
            throw AuthFailure.failed
        } catch {
            throw AuthFailure.failed
        }
    }
}
