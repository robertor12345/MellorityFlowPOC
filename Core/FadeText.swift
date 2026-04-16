import SwiftUI

/// Body copy — soft fade + slight rise.
struct FadeInLine: View {
    let text: String
    var font: Font = .body
    var color: Color = BrandTheme.brownMuted
    var delay: Double = 0
    @State private var visible = false

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 10)
            .onAppear {
                withAnimation(.easeOut(duration: 0.65).delay(delay)) {
                    visible = true
                }
            }
            .onDisappear { visible = false }
    }
}

/// Serif title fade.
struct FadeInTitle: View {
    let text: String
    var size: Font.TextStyle = .title
    var delay: Double = 0
    @State private var visible = false

    var body: some View {
        Text(text)
            .font(BrandTheme.title(size))
            .foregroundStyle(BrandTheme.brown)
            .multilineTextAlignment(.center)
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(delay)) {
                    visible = true
                }
            }
            .onDisappear { visible = false }
    }
}

/// Fades the entire screen content in after transition.
struct ScreenFadeIn<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var visible = false

    var body: some View {
        content()
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 6)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    visible = true
                }
            }
            .onDisappear { visible = false }
    }
}
