import SwiftUI

// MARK: - Scroll metrics

struct ScrollViewportMetrics: Equatable {
    var contentHeight: CGFloat = 0
    var contentMinY: CGFloat = 0
}

enum ScrollViewportMetricsKey: PreferenceKey {
    static var defaultValue = ScrollViewportMetrics()

    static func reduce(value: inout ScrollViewportMetrics, nextValue: () -> ScrollViewportMetrics) {
        value = nextValue()
    }
}

struct ScrollViewportMetricsReader: View {
    var coordinateSpace: String

    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollViewportMetricsKey.self,
                value: ScrollViewportMetrics(
                    contentHeight: geo.size.height,
                    contentMinY: geo.frame(in: .named(coordinateSpace)).minY
                )
            )
        }
    }
}

// MARK: - Tight viewport edge mask (mask only — no scrim cap)

private struct ScrollViewportEdgeMask: View {
    var showTop: Bool
    var showBottom: Bool
    var fadeHeight: CGFloat
    var viewportHeight: CGFloat

    var body: some View {
        let height = max(viewportHeight, 1)
        // Keep the dissolve band narrow and hugging the viewport edge.
        let band = min(BrandLayout.scrollEdgeFadeMaxFraction, fadeHeight / height)

        LinearGradient(
            stops: edgeStops(band: band),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func edgeStops(band: CGFloat) -> [Gradient.Stop] {
        // Steep ramp: opaque almost to the edge, then a short dissolve.
        let ramp = band * 0.72
        var stops: [Gradient.Stop] = []

        if showTop {
            stops.append(.init(color: .clear, location: 0))
            stops.append(.init(color: .black, location: ramp))
        } else {
            stops.append(.init(color: .black, location: 0))
        }

        let opaqueThrough = showBottom ? (1 - ramp) : 1
        if opaqueThrough > (stops.last?.location ?? 0) {
            stops.append(.init(color: .black, location: opaqueThrough))
        }

        if showBottom {
            stops.append(.init(color: .clear, location: 1))
        } else if stops.last?.location != 1 {
            stops.append(.init(color: .black, location: 1))
        }

        return stops
    }
}

// MARK: - Scroll viewport with edge dissolve

struct ScrollViewportEdgeFade<Content: View>: View {
    var coordinateSpace: String
    var fadeHeight: CGFloat = BrandLayout.scrollEdgeFadeHeight
    var fadeBottom: Bool = true
    @ViewBuilder var content: () -> Content

    @State private var metrics = ScrollViewportMetrics()

    private var showTopFade: Bool {
        metrics.contentMinY < -6
    }

    var body: some View {
        ScrollView {
            content()
                .overlay {
                    ScrollViewportMetricsReader(coordinateSpace: coordinateSpace)
                }
        }
        .coordinateSpace(name: coordinateSpace)
        .mask {
            GeometryReader { geo in
                ScrollViewportEdgeMask(
                    showTop: showTopFade,
                    showBottom: fadeBottom,
                    fadeHeight: fadeHeight,
                    viewportHeight: geo.size.height
                )
            }
        }
        .onPreferenceChange(ScrollViewportMetricsKey.self) { metrics = $0 }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Back-compat alias used by group session screen.
struct ScrollViewportWithEdgeFade<Content: View>: View {
    var coordinateSpace: String
    var fadeHeight: CGFloat = BrandLayout.scrollEdgeFadeHeight
    var fadeTop: Bool = true
    var fadeBottom: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollViewportEdgeFade(
            coordinateSpace: coordinateSpace,
            fadeHeight: fadeHeight,
            fadeBottom: fadeBottom,
            content: content
        )
    }
}

extension View {
    func scrollViewportWithEdgeFade(
        coordinateSpace: String = "scrollFade",
        fadeHeight: CGFloat = BrandLayout.scrollEdgeFadeHeight,
        fadeTop: Bool = true,
        fadeBottom: Bool = true
    ) -> some View {
        ScrollViewportWithEdgeFade(
            coordinateSpace: coordinateSpace,
            fadeHeight: fadeHeight,
            fadeTop: fadeTop,
            fadeBottom: fadeBottom
        ) {
            self
        }
    }
}
