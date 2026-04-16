import SwiftUI

// MARK: - 1. Onboarding & login

struct WelcomeView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image("MellorityLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 160)
                    .padding(.top, 24)
                Text("Harmony through insight")
                    .font(BrandTheme.title(.title3))
                    .foregroundStyle(BrandTheme.brownMuted)
                PrimaryButton(title: "Continue") {
                    state.phase = .authChoice
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
    }
}

struct AuthChoiceView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Join Mellority")
                    .font(BrandTheme.title(.largeTitle))
                    .foregroundStyle(BrandTheme.brown)
                Text("Create an account or sign in. This POC uses mock auth only.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.brownMuted)

                VStack(spacing: 12) {
                    PrimaryButton(title: "Sign up with Email") { state.phase = .signUp }
                    socialRow(icon: "apple.logo", label: "Continue with Apple") {}
                    socialRow(icon: "g.circle.fill", label: "Continue with Google") {}
                    SecondaryButton(title: "Log in") { state.phase = .login }
                }
            }
            .padding(24)
        }
    }

    private func socialRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(BrandTheme.cream.opacity(0.85))
            .foregroundStyle(BrandTheme.brown)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SignUpView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sign up")
                    .font(BrandTheme.title(.largeTitle))
                    .foregroundStyle(BrandTheme.brown)
                TextField("Email", text: $state.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(BrandTheme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                SecureField("Password", text: $state.password)
                    .padding()
                    .background(BrandTheme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                PrimaryButton(title: "Create account") {
                    state.phase = .permissions
                }
                SecondaryButton(title: "Back") { state.phase = .authChoice }
            }
            .padding(24)
        }
    }
}

struct LoginView: View {
    @ObservedObject var state: SessionPOCState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Log in")
                    .font(BrandTheme.title(.largeTitle))
                    .foregroundStyle(BrandTheme.brown)
                TextField("Email", text: $state.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(BrandTheme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                SecureField("Password", text: $state.password)
                    .padding()
                    .background(BrandTheme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                PrimaryButton(title: "Log in") {
                    state.phase = .permissions
                }
                SecondaryButton(title: "Back") { state.phase = .authChoice }
            }
            .padding(24)
        }
    }
}
