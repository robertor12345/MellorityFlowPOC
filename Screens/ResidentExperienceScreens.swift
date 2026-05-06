import SwiftUI

// MARK: - Resident profile hub (icon-first; staff exit top-trailing)

struct ResidentProfileView: View {
    @ObservedObject var state: SessionPOCState
    @State private var genreSheet = false
    @State private var pulseNote: String?

    private var patient: CarePatientProfile? {
        state.carePatient(id: state.selectedCarePatientId)
    }

    var body: some View {
        ZStack {
            BrandTheme.backgroundGradient
                .ignoresSafeArea()

            if let patient {
                floatingNotes(themes: patient.comfortThemes)
            }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        state.leaveResidentProfileToStaff()
                    } label: {
                        Image(systemName: "person.badge.key.fill")
                            .font(.title2)
                            .foregroundStyle(BrandTheme.brown.opacity(0.85))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Return device to staff")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        genreSheet = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [BrandTheme.goldSoft.opacity(0.95), BrandTheme.goldDeep.opacity(0.75)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: BrandTheme.gold.opacity(0.45), radius: 24, y: 8)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 52, weight: .medium))
                            .foregroundStyle(BrandTheme.brown)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose music style")

                Spacer()
                Spacer()
            }

            if genreSheet {
                genrePickerOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: genreSheet)
    }

    @ViewBuilder
    private func floatingNotes(themes: [String]) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ForEach(Array(themes.enumerated()), id: \.offset) { i, theme in
                let xFrac = noteXFraction(index: i, count: themes.count)
                let yFrac = noteYFraction(index: i)
                notePill(theme, isPulsing: pulseNote == theme)
                    .position(x: w * xFrac, y: h * yFrac)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            pulseNote = theme
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            pulseNote = nil
                        }
                    }
                    .accessibilityLabel(theme)
            }
        }
        .allowsHitTesting(true)
    }

    private func noteXFraction(index: Int, count: Int) -> CGFloat {
        let base = CGFloat(index + 1) / CGFloat(max(count + 1, 2))
        return min(0.88, max(0.12, base + CGFloat(sin(Double(index) * 1.7)) * 0.08))
    }

    private func noteYFraction(index: Int) -> CGFloat {
        let row = index % 3
        return CGFloat(0.22 + Double(row) * 0.16 + sin(Double(index)) * 0.04)
    }

    private func notePill(_ text: String, isPulsing: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(BrandTheme.brown.opacity(0.92))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(BrandTheme.cream.opacity(0.88))
                    .shadow(color: BrandTheme.brown.opacity(0.12), radius: isPulsing ? 12 : 6, y: 3)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(BrandTheme.gold.opacity(isPulsing ? 0.55 : 0.28), lineWidth: isPulsing ? 2 : 1)
            )
            .scaleEffect(isPulsing ? 1.08 : 1)
    }

    private var genrePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { genreSheet = false }
                }

            VStack(spacing: 18) {
                Capsule()
                    .fill(BrandTheme.brownMuted.opacity(0.35))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 16
                ) {
                    ForEach(ResidentMusicGenre.allCases) { genre in
                        let fav = patient?.favouriteMusicGenre == genre
                        Button {
                            genreSheet = false
                            state.confirmResidentGenre(genre)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(genre.accent.opacity(0.35))
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        fav ? BrandTheme.gold : BrandTheme.brown.opacity(0.15),
                                        lineWidth: fav ? 3 : 1
                                    )
                                Image(systemName: genre.iconName)
                                    .font(.title)
                                    .foregroundStyle(BrandTheme.brown)
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .frame(height: 76)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(genre.accessibilityLabel)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(BrandTheme.cream.opacity(0.98))
                    .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
            )
            .padding(.horizontal, 12)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 8)
        }
    }
}
