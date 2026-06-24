import AVFoundation
import SwiftUI

// MARK: - Track / genre backdrop (full MP4 clips inside the resident panel)

enum ResidentPlaylistVisualCatalog {
    private static let jazz: [ArchiveEraClip] = [
        .rumbaMamba,
        .partyJohnnieRay,
        .royalWedding,
        ArchiveEraClip(
            archiveItemID: ArchiveEraClipLibrary.partyJohnnieRay.archiveItemID,
            videoFileNames: ["ArthurMurrayPartyJohnnieRay.mp4"],
            posterFileName: "ArthurMurrayPartyJohnnieRay.gif"
        ),
        .bowlingFull,
    ]

    private static let classical: [ArchiveEraClip] = [
        .royalWedding,
        .partyJohnnieRay,
        .rumbaMamba,
        .bowlingFull,
    ]

    private static let pop: [ArchiveEraClip] = [
        .bowlingFull,
        .partyJohnnieRay,
        ArchiveEraClip(
            archiveItemID: ArchiveEraClipLibrary.bowlingFull.archiveItemID,
            videoFileNames: ["LetsGoBo1955_edit.mp4", "LetsGoBo1955.mp4"],
            posterFileName: "LetsGoBo1955.gif"
        ),
        .royalWedding,
    ]

    private static let rock: [ArchiveEraClip] = [
        ArchiveEraClip(
            archiveItemID: ArchiveEraClipLibrary.bowlingFull.archiveItemID,
            videoFileNames: ["LetsGoBo1955_edit.mp4", "LetsGoBo1955.mp4", "LetsGoBo1955_512kb.mp4"],
            posterFileName: "LetsGoBo1955.gif"
        ),
        .partyJohnnieRay,
        .rumbaMamba,
    ]

    private static let gospel: [ArchiveEraClip] = [
        .partyJohnnieRay,
        .royalWedding,
        .bowlingFull,
        .rumbaMamba,
    ]

    private static let country: [ArchiveEraClip] = [
        .bowlingFull,
        ArchiveEraClip(
            archiveItemID: ArchiveEraClipLibrary.bowlingFull.archiveItemID,
            videoFileNames: ["LetsGoBo1955.mp4", "LetsGoBo1955_edit.mp4"],
            posterFileName: "LetsGoBo1955.gif"
        ),
        .partyJohnnieRay,
    ]

    private static let soul: [ArchiveEraClip] = [
        .partyJohnnieRay,
        .rumbaMamba,
        .royalWedding,
        .bowlingFull,
    ]

    static func clip(
        for genre: ResidentMusicGenre,
        trackTitle: String,
        trackIndex: Int
    ) -> ArchiveEraClip {
        let pool = pool(for: genre)
        guard pool.isEmpty == false else {
            return .partyJohnnieRay
        }
        let titleHash = abs(trackTitle.hashValue)
        let idx = (trackIndex + titleHash) % pool.count
        return pool[idx]
    }

    private static func pool(for genre: ResidentMusicGenre) -> [ArchiveEraClip] {
        switch genre {
        case .jazz: jazz
        case .classical: classical
        case .pop: pop
        case .rock: rock
        case .gospel: gospel
        case .country: country
        case .soul: soul
        }
    }
}

/// Full-bleed muted clip — only mounted while a playlist is playing.
struct ResidentPlaylistBackdropView: View {
    let genre: ResidentMusicGenre
    let trackTitle: String
    let trackIndex: Int

    @StateObject private var videoLooper = DiscoverySnippetVideoLooper()
    @State private var playlistMediaReady = false

    private var clip: ArchiveEraClip {
        ResidentPlaylistVisualCatalog.clip(for: genre, trackTitle: trackTitle, trackIndex: trackIndex)
    }

    var body: some View {
        ZStack {
            DiscoverySnippetMediaFill(
                visual: discoveryVisualAdapter,
                player: videoLooper.player,
                isMediaReady: $playlistMediaReady
            )
                .scaleEffect(1.02)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [
                    BrandTheme.skyBackgroundTop.opacity(0.18),
                    Color.black.opacity(0.06),
                    BrandTheme.skyBackgroundDeep.opacity(0.24),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(playlistMediaReady ? 1 : 0)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .id("\(genre.rawValue)-\(trackIndex)-\(trackTitle)-\(clip.archiveItemID)")
        .onAppear { restartVideo() }
        .onChange(of: trackIndex) { _, _ in
            playlistMediaReady = false
            restartVideo()
        }
        .onChange(of: trackTitle) { _, _ in
            playlistMediaReady = false
            restartVideo()
        }
        .onDisappear { videoLooper.stop() }
    }

    private var discoveryVisualAdapter: DiscoverySnippetEraVisual {
        DiscoverySnippetEraVisual(
            snippetIndex: trackIndex,
            eraYear: 1955,
            eraEvent: trackTitle,
            clip: clip
        )
    }

    private func restartVideo() {
        let urls = clip.videoURLs
        guard urls.isEmpty == false else {
            videoLooper.stop()
            return
        }
        videoLooper.play(urls: urls)
    }
}

/// Clips playlist media to the same circular nebula orb as discovery.
struct ResidentPlaylistPanelBackdropView: View {
    let genre: ResidentMusicGenre
    let trackTitle: String
    let trackIndex: Int
    let orbSize: CGSize

    var body: some View {
        OrbInteriorMediaPanel(orbSize: orbSize, showArcFrame: false) {
            ResidentPlaylistBackdropView(
                genre: genre,
                trackTitle: trackTitle,
                trackIndex: trackIndex
            )
        }
    }
}
