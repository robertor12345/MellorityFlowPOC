import Foundation

/// POC gate for care-home supervisor access — username + PIN before roster.
enum SupervisorAuth {
    /// Demo credentials; replace with secure backend validation before production.
    static let demoUsername = "supervisor"
    static let demoPIN = "1234"

    static func validate(username: String, pin: String) -> String? {
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !user.isEmpty else { return "Enter your username." }
        guard code.count >= 4 else { return "PIN must be at least four digits." }
        guard user.caseInsensitiveCompare(demoUsername) == .orderedSame,
              code == demoPIN
        else { return "Username or PIN didn’t match. Try again." }
        return nil
    }
}
