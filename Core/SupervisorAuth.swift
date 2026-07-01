import Foundation

/// POC gate for care-home supervisor access — work email + PIN, scoped to organisation & homes.
enum SupervisorAuth {
    static let pinDigitCount = PinInputSpec.digitCount

    static func validate(email: String, pin: String) -> (account: SupervisorAccount?, error: String?) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let code = pin.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty else { return (nil, "Enter your work email.") }
        guard normalizedEmail.contains("@") else { return (nil, "Enter a valid work email address.") }
        guard code.count == pinDigitCount else {
            return (nil, "Enter your \(pinDigitCount)-digit PIN.")
        }

        guard let domain = normalizedEmail.split(separator: "@").last.map(String.init)?.lowercased() else {
            return (nil, "Enter a valid work email address.")
        }
        guard CareTenancyMockData.organisation.emailDomains.contains(where: { $0.lowercased() == domain }) else {
            let allowed = CareTenancyMockData.organisation.emailDomains.map { "@\($0)" }.joined(separator: ", ")
            return (nil, "Use your organisation email (\(allowed)).")
        }

        guard let account = CareTenancyMockData.supervisors.first(where: {
            $0.email.lowercased() == normalizedEmail && $0.pin == code
        }) else {
            return (nil, "Email or PIN didn’t match. Try max@sunrise-care.co.uk (supervisor) or alex@sunrise-care.co.uk (home admin) with PIN 123456.")
        }

        return (account, nil)
    }
}
