import SwiftUI

/// Body copy — soft fade + slight rise.
struct FadeInLine: View {
    let text: String
    var font: Font = .body
    var magnification: CGFloat = 1
    var color: Color = BrandTheme.logoLavenderBlue
    var delay: Double = 0
    @State private var visible = false

    private var resolvedFont: Font {
        magnification > 1 ? SignInPageLayout.subheadFont : font
    }

    var body: some View {
        Text(text)
            .font(resolvedFont)
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
    var magnification: CGFloat = 1
    var delay: Double = 0
    var useBrandGradient: Bool = false
    @State private var visible = false

    private var resolvedFont: Font {
        magnification > 1
            ? SignInPageLayout.titleFont
            : BrandTheme.title(size)
    }

    var body: some View {
        Text(text)
            .font(resolvedFont)
            .tracking(magnification > 1 ? 3 : 2)
            .foregroundStyle(useBrandGradient ? AnyShapeStyle(Color.white) : AnyShapeStyle(BrandTheme.brown))
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

/// NoteStalgia title fade — wordmark with ™.
struct FadeInNoteStalgiaWordmark: View {
    var magnification: CGFloat = 1
    var delay: Double = 0
    @State private var visible = false

    private var resolvedFont: Font {
        magnification > 1 ? SignInPageLayout.titleFont : BrandTheme.title(.title)
    }

    private var resolvedPointSize: CGFloat {
        magnification > 1 ? SignInPageLayout.points(28) : 28
    }

    var body: some View {
        NoteStalgiaWordmark(
            font: resolvedFont,
            tracking: magnification > 1 ? 3 : 2,
            pointSize: resolvedPointSize
        )
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
