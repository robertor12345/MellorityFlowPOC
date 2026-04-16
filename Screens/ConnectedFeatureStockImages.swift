import SwiftUI

/// Remote stock imagery for “connected feature” surfaces (Wikimedia Commons). Used by post-sign-in slides and unlock list.
struct ConnectedFeatureStock: Identifiable {
    let id: String
    let imageURL: URL
    /// Short label on the hero image (e.g. product category).
    let badge: String
    /// One-line attribution / license for the slide footer.
    let attribution: String
    let fallbackSystemImage: String

    static let health = ConnectedFeatureStock(
        id: "health",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0b/Fitbit_Alta_HR.jpg")!,
        badge: "Wearable",
        attribution:
            "Stock photo: Fitbit Alta HR (heart-rate display) — Wikimedia Commons (CC BY-SA 4.0, PamD). POC only; not affiliated with Fitbit.",
        fallbackSystemImage: "heart.fill"
    )

    static let iot = ConnectedFeatureStock(
        id: "iot",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/84/Philips_Hue_hub_and_2_bulbs.jpg")!,
        badge: "Philips Hue",
        attribution:
            "Stock photo: Philips Hue hub and bulbs — Wikimedia Commons (CC BY 2.0, Sho Hashimoto). POC only; not affiliated with Signify.",
        fallbackSystemImage: "lightbulb.led.fill"
    )

    static let personalisation = ConnectedFeatureStock(
        id: "personalisation",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/29/DJ_Mixer.JPG")!,
        badge: "Mix & tune",
        attribution: "Stock photo: DJ mixer — Wikimedia Commons (public domain, Jana C.).",
        fallbackSystemImage: "slider.horizontal.3"
    )

    static let snippetsMemory = ConnectedFeatureStock(
        id: "snippetsMemory",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Woman_writing_on_a_notebook_with_a_pen.jpg")!,
        badge: "Notes",
        attribution:
            "Stock photo: writing in a notebook — Wikimedia Commons (CC0, Kristin Hardwick; ISO Republic).",
        fallbackSystemImage: "bookmark.fill"
    )

    static let replayCalm = ConnectedFeatureStock(
        id: "replayCalm",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/e/e8/Deep_meditation_in_forest.jpg")!,
        badge: "Calm",
        attribution:
            "Stock photo: meditation in forest — Wikimedia Commons (CC BY-SA 4.0, intergalactic Passenger).",
        fallbackSystemImage: "play.circle.fill"
    )
}

// MARK: - Hero (post-sign-in TabView slides)

struct ConnectedFeatureHeroImage: View {
    let stock: ConnectedFeatureStock
    var height: CGFloat = 200

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: stock.imageURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BrandTheme.creamMid)
                        .frame(height: height)
                        .overlay {
                            ProgressView()
                                .tint(BrandTheme.goldDeep)
                        }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .clipped()
                case .failure:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BrandTheme.creamMid)
                        .frame(height: height)
                        .overlay {
                            Image(systemName: stock.fallbackSystemImage)
                                .font(.system(size: 48))
                                .foregroundStyle(BrandTheme.goldDeep)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandTheme.gold.opacity(0.35), lineWidth: 1)
            )

            Text(stock.badge)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BrandTheme.cream)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.45), in: Capsule())
                .padding(10)
        }
    }
}

// MARK: - Thumbnail (unlock list)

struct ConnectedFeatureThumbnail: View {
    let stock: ConnectedFeatureStock
    var side: CGFloat = 76

    var body: some View {
        AsyncImage(url: stock.imageURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandTheme.creamMid)
                    .frame(width: side, height: side)
                    .overlay {
                        ProgressView()
                            .tint(BrandTheme.goldDeep)
                            .scaleEffect(0.85)
                    }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    .clipped()
            case .failure:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandTheme.creamMid)
                    .frame(width: side, height: side)
                    .overlay {
                        Image(systemName: stock.fallbackSystemImage)
                            .font(.title2)
                            .foregroundStyle(BrandTheme.goldDeep)
                    }
            @unknown default:
                EmptyView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BrandTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }
}
