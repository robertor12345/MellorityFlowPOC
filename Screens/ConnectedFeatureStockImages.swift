import SwiftUI

/// Stock imagery for connected-feature surfaces. Used by post-sign-in slides, unlock list, and detail sheets.
struct ConnectedFeatureStock: Identifiable {
    let id: String
    let imageURL: URL
    /// Short label on the hero image (e.g. product category).
    let badge: String
    let fallbackSystemImage: String

    static let health = ConnectedFeatureStock(
        id: "health",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0b/Fitbit_Alta_HR.jpg")!,
        badge: "Wearable",
        fallbackSystemImage: "heart.fill"
    )

    static let iot = ConnectedFeatureStock(
        id: "iot",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/84/Philips_Hue_hub_and_2_bulbs.jpg")!,
        badge: "Philips Hue",
        fallbackSystemImage: "lightbulb.led.fill"
    )

    static let personalisation = ConnectedFeatureStock(
        id: "personalisation",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/29/DJ_Mixer.JPG")!,
        badge: "Mix & tune",
        fallbackSystemImage: "slider.horizontal.3"
    )

    static let snippetsMemory = ConnectedFeatureStock(
        id: "snippetsMemory",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Woman_writing_on_a_notebook_with_a_pen.jpg")!,
        badge: "Notes",
        fallbackSystemImage: "bookmark.fill"
    )

    static let replayCalm = ConnectedFeatureStock(
        id: "replayCalm",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/e/e8/Deep_meditation_in_forest.jpg")!,
        badge: "Calm",
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
