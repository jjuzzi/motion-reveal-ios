import SwiftUI

struct MarkerTouchMetrics: Equatable {
    static let minimumTouchTarget: CGFloat = 44
    static let compactIconVisualDiameter: CGFloat = 30
    static let waveformMarkerHitWidth: CGFloat = minimumTouchTarget
    static let markerFilterHitHeight: CGFloat = minimumTouchTarget
}

struct WaveformScrubMetrics: Equatable {
    static let horizontalDragThreshold: CGFloat = 8
    static let verticalCancelThreshold: CGFloat = 22
    static let scrubReleaseDelay: Duration = .milliseconds(140)
    static let markerCaptureCooldown: TimeInterval = 0.85
    static let markerEditorDismissalCooldown: TimeInterval = 1.10
    static let markerSelectionDismissalCooldown: TimeInterval = 0.45
    static let liveScrubSeekInterval: TimeInterval = 1.0 / 24.0

    static func fraction(for locationX: CGFloat, width: CGFloat) -> Double {
        guard width > 1 else { return 0 }

        let rawFraction = locationX / width
        return min(max(Double(rawFraction), 0), 1)
    }

    static func shouldScrub(translation: CGSize) -> Bool {
        abs(translation.width) >= horizontalDragThreshold
            && abs(translation.height) <= verticalCancelThreshold
    }

    static func shouldCancelTouch(translation: CGSize) -> Bool {
        abs(translation.height) > verticalCancelThreshold
    }

    static func shouldCommitLiveScrub(lastCommit: Date?, now: Date) -> Bool {
        guard let lastCommit else { return true }

        return now.timeIntervalSince(lastCommit) >= liveScrubSeekInterval
    }

    static func shouldBeginLongPress(
        isScrubbing: Bool,
        hasAddedMarkerDuringCurrentPress: Bool,
        hasSelectedMarker: Bool,
        isCoolingDown: Bool
    ) -> Bool {
        !isScrubbing
            && !hasAddedMarkerDuringCurrentPress
            && !hasSelectedMarker
            && !isCoolingDown
    }

    static func displayedElapsedLabel(for progress: PlaybackProgress, scrubFraction: Double?) -> String {
        scrubFraction.map(progress.timeLabel(atFraction:)) ?? progress.elapsedLabel
    }
}

struct WaveformGestureState: Equatable {
    private(set) var isScrubbing = false
    private(set) var scrubFraction: Double?
    private(set) var lastLiveScrubSeekDate: Date?
    private(set) var markerCaptureLockedUntil = Date.distantPast
    private(set) var hasAddedMarkerDuringCurrentPress = false

    var isPreviewingScrub: Bool {
        scrubFraction != nil
    }

    mutating func setScrubFraction(_ fraction: Double) {
        scrubFraction = min(max(fraction, 0), 1)
    }

    mutating func clearScrubFraction() {
        scrubFraction = nil
    }

    mutating func beginScrub(at fraction: Double, now: Date) -> Bool {
        let shouldPreview = !isScrubbing
            || WaveformScrubMetrics.shouldCommitLiveScrub(lastCommit: lastLiveScrubSeekDate, now: now)

        isScrubbing = true
        setScrubFraction(fraction)

        if shouldPreview {
            lastLiveScrubSeekDate = now
        }

        return shouldPreview
    }

    mutating func finishScrub(at fraction: Double) {
        setScrubFraction(fraction)
        isScrubbing = false
        lastLiveScrubSeekDate = nil
    }

    mutating func cancelLongPressState(resetScrubbing: Bool) {
        hasAddedMarkerDuringCurrentPress = false
        guard resetScrubbing else { return }

        isScrubbing = false
        lastLiveScrubSeekDate = nil
        scrubFraction = nil
    }

    mutating func prepareLongPress() {
        hasAddedMarkerDuringCurrentPress = false
    }

    mutating func markAddedMarker(now: Date) {
        hasAddedMarkerDuringCurrentPress = true
        markerCaptureLockedUntil = now.addingTimeInterval(WaveformScrubMetrics.markerCaptureCooldown)
    }

    mutating func lockMarkerCapture(until date: Date) {
        markerCaptureLockedUntil = date
    }

    func canBeginLongPress(
        now: Date,
        hasSelectedMarker: Bool,
        isMarkerEditorPresented: Bool
    ) -> Bool {
        WaveformScrubMetrics.shouldBeginLongPress(
            isScrubbing: isScrubbing,
            hasAddedMarkerDuringCurrentPress: hasAddedMarkerDuringCurrentPress,
            hasSelectedMarker: hasSelectedMarker,
            isCoolingDown: now < markerCaptureLockedUntil || isMarkerEditorPresented
        )
    }

    func shouldCommitTapSeek(translation: CGSize) -> Bool {
        !hasAddedMarkerDuringCurrentPress
            && abs(translation.width) < WaveformScrubMetrics.horizontalDragThreshold
            && abs(translation.height) < WaveformScrubMetrics.horizontalDragThreshold
    }
}

struct WaveformVisualMetrics: Equatable {
    static let barCount = [CGFloat].waveformBars.count
    static let horizontalInset: CGFloat = 2
    static let hitHeight: CGFloat = 112
    static let hitTop: CGFloat = 16
    static let barSpacing: CGFloat = 1.6
    static let minBarHeight: CGFloat = 6
    static let maxBarHeight: CGFloat = 62
    static let playheadHeight: CGFloat = 76
    static let playheadWidth: CGFloat = 1.6

    static func trackRect(in size: CGSize) -> CGRect {
        let width = max(1, size.width - horizontalInset * 2)
        return CGRect(
            x: horizontalInset,
            y: hitTop,
            width: width,
            height: hitHeight
        )
    }

    static func barWidth(in trackWidth: CGFloat) -> CGFloat {
        let barCount = CGFloat(Self.barCount)
        let spacingWidth = max(0, barCount - 1) * barSpacing
        return max(1.15, (trackWidth - spacingWidth) / max(1, barCount))
    }
}

struct WaveformPanel: View {
    let progress: PlaybackProgress
    @Binding var markers: [WaveformMarker]
    @Binding var selectedMarker: WaveformMarker?
    let seekPlayback: (Double) -> Void
    let previewSeekPlayback: (Double) -> Void
    let editMarker: (WaveformMarker) -> Void
    let isMarkerEditorPresented: Bool
    let markerEditorCooldownToken: Int
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressTask: Task<Void, Never>?
    @State private var pressToken = UUID()
    @State private var gestureState = WaveformGestureState()
    @State private var scrubReleaseTask: Task<Void, Never>?
    @State private var progressAnchorElapsed: TimeInterval = 0
    @State private var progressAnchorDate = Date()
    private let horizontalInset = WaveformVisualMetrics.horizontalInset
    private let barSpacing = WaveformVisualMetrics.barSpacing

    private var timelinePaused: Bool {
        reduceMotion || !progress.isPlaying || gestureState.isPreviewingScrub
    }

    var body: some View {
        GeometryReader { proxy in
            let trackRect = waveformTrackRect(in: proxy.size)

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: timelinePaused)) { timeline in
                let liveFraction = displayedFraction(at: timeline.date)
                let elapsedLabel = displayedElapsedLabel(at: liveFraction)

                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: trackRect.width, height: trackRect.height)
                        .position(x: trackRect.midX, y: trackRect.midY)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleWaveformDragChanged(value, trackRect: trackRect)
                                }
                                .onEnded { value in
                                    handleWaveformDragEnded(value, trackRect: trackRect)
                                }
                        )

                    WaveformCanvasLayer(
                        trackRect: trackRect,
                        barSpacing: barSpacing,
                        displayedFraction: liveFraction,
                        isPlaying: progress.isPlaying,
                        reduceMotion: reduceMotion,
                        animationPhase: timeline.date.timeIntervalSinceReferenceDate
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .allowsHitTesting(false)

                    ForEach(markers) { marker in
                        let markerLineWidth = WaveformVisualMetrics.barWidth(in: trackRect.width)
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                selectedMarker = marker
                            }
                            seekPlayback(Double(marker.position))
                        } label: {
                            ZStack {
                                Color.clear
                                    .frame(width: MarkerTouchMetrics.waveformMarkerHitWidth, height: 112)

                                Capsule()
                                    .fill(marker.color.opacity(marker.isResolved ? 0.38 : selectedMarker?.id == marker.id ? 0.94 : 0.72))
                                    .frame(width: markerLineWidth, height: max(24, 82 * marker.height))
                                    .shadow(color: marker.color.opacity(selectedMarker?.id == marker.id ? 0.26 : 0.12), radius: 5, x: 0, y: 0)

                                if differentiateWithoutColor {
                                    Image(systemName: marker.colorToken.symbolName)
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(marker.color)
                                        .frame(width: 18, height: 18)
                                        .background(Color.black.opacity(0.54), in: Circle())
                                        .offset(y: -56)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .position(x: waveformX(for: Double(marker.position), in: trackRect), y: trackRect.midY)
                        .accessibilityLabel("Jump to \(marker.accessibilitySummary)")
                    }

                    if let selectedMarker, !isMarkerEditorPresented {
                        let popoverX = min(
                            max(waveformX(for: Double(selectedMarker.position), in: trackRect), 104),
                            proxy.size.width - 104
                        )
                        Button {
                            editMarker(selectedMarker)
                        } label: {
                            MarkerNotePopover(marker: selectedMarker)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(selectedMarker.note.isEmpty ? "Add note to marker at \(selectedMarker.time)" : "Edit marker note at \(selectedMarker.time)")
                        .accessibilityIdentifier("marker-note-popover")
                        .position(x: popoverX, y: 36)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(5)
                    }

                    HStack {
                        Text(elapsedLabel)
                        Spacer()
                        Text(progress.durationLabel)
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.studioMuted)
                    .padding(.horizontal, horizontalInset)
                    .padding(.bottom, 2)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Waveform scrubber")
            .accessibilityValue("\(progress.elapsedLabel) of \(progress.durationLabel)")
            .accessibilityHint("Drag horizontally to scrub playback. Long press to add a marker.")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    seekPlayback(min(progress.fraction + 0.05, 1))
                case .decrement:
                    seekPlayback(max(progress.fraction - 0.05, 0))
                @unknown default:
                    break
                }
            }
        }
        .frame(height: 172)
        .onChange(of: progress.fraction) { _, fraction in
            guard !gestureState.isScrubbing else { return }
            guard let scrubFraction = gestureState.scrubFraction else { return }

            if abs(scrubFraction - fraction) < 0.004 {
                clearScrubFraction()
            }
        }
        .onAppear {
            resetProgressAnchor(to: progress)
        }
        .onChange(of: progress) { _, newProgress in
            resetProgressAnchor(to: newProgress)
        }
        .onDisappear {
            scrubReleaseTask?.cancel()
            pressTask?.cancel()
        }
        .onChange(of: selectedMarker?.id) { oldValue, newValue in
            if oldValue != nil, newValue == nil {
                gestureState.lockMarkerCapture(
                    until: Date().addingTimeInterval(WaveformScrubMetrics.markerSelectionDismissalCooldown)
                )
            }
        }
        .onChange(of: markerEditorCooldownToken) {
            cancelLongPress()
            gestureState.lockMarkerCapture(
                until: Date().addingTimeInterval(WaveformScrubMetrics.markerEditorDismissalCooldown)
            )
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .accessibilityIdentifier("waveform-panel")
    }

    private func handleWaveformDragChanged(_ value: DragGesture.Value, trackRect: CGRect) {
        if WaveformScrubMetrics.shouldCancelTouch(translation: value.translation) {
            cancelLongPress()
            return
        }

        let fraction = waveformFraction(for: value.location.x, in: trackRect)
        setScrubFraction(fraction)

        if WaveformScrubMetrics.shouldScrub(translation: value.translation) {
            scrubReleaseTask?.cancel()
            scrubReleaseTask = nil
            cancelLongPress(resetScrubbing: false)
            selectedMarker = nil
            previewLiveScrub(fraction)
            return
        }

        if gestureState.canBeginLongPress(
            now: Date(),
            hasSelectedMarker: selectedMarker != nil,
            isMarkerEditorPresented: isMarkerEditorPresented
        ) {
            beginLongPressIfNeeded(at: value.location, trackRect: trackRect)
        }
    }

    private func handleWaveformDragEnded(_ value: DragGesture.Value, trackRect: CGRect) {
        defer {
            cancelLongPress(resetScrubbing: false)
        }

        if gestureState.isScrubbing || WaveformScrubMetrics.shouldScrub(translation: value.translation) {
            let fraction = waveformFraction(for: value.location.x, in: trackRect)
            setScrubFraction(fraction)
            gestureState.finishScrub(at: fraction)
            seekPlayback(fraction)
            finishScrubbingAfterRelease()
            return
        }

        if gestureState.hasAddedMarkerDuringCurrentPress {
            finishScrubbingAfterRelease()
            return
        }

        if gestureState.shouldCommitTapSeek(translation: value.translation) {
            let fraction = waveformFraction(for: value.location.x, in: trackRect)
            setScrubFraction(fraction)
            gestureState.finishScrub(at: fraction)
            seekPlayback(fraction)
            finishScrubbingAfterRelease()
            withAnimation(.easeOut(duration: 0.16)) {
                selectedMarker = nil
            }
        }
    }

    private func waveformTrackRect(in size: CGSize) -> CGRect {
        WaveformVisualMetrics.trackRect(in: size)
    }

    private func waveformX(for fraction: Double, in trackRect: CGRect) -> CGFloat {
        trackRect.minX + trackRect.width * CGFloat(min(max(fraction, 0), 1))
    }

    private func waveformFraction(for locationX: CGFloat, in trackRect: CGRect) -> Double {
        WaveformScrubMetrics.fraction(for: locationX - trackRect.minX, width: trackRect.width)
    }

    private func displayedFraction(at date: Date) -> Double {
        if let scrubFraction = gestureState.scrubFraction {
            return scrubFraction
        }

        guard progress.isPlaying, !reduceMotion, progress.duration > 0 else {
            return progress.fraction
        }

        let elapsed = min(progress.duration, progressAnchorElapsed + max(0, date.timeIntervalSince(progressAnchorDate)))
        return min(max(elapsed / progress.duration, 0), 1)
    }

    private func displayedElapsedLabel(at fraction: Double) -> String {
        if gestureState.scrubFraction != nil {
            return progress.timeLabel(atFraction: fraction)
        }

        guard progress.isPlaying, !reduceMotion else {
            return progress.elapsedLabel
        }

        return progress.timeLabel(atFraction: fraction)
    }

    private func resetProgressAnchor(to progress: PlaybackProgress) {
        progressAnchorElapsed = progress.elapsed
        progressAnchorDate = Date()
    }

    private func setScrubFraction(_ fraction: Double) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            gestureState.setScrubFraction(fraction)
        }
    }

    private func clearScrubFraction() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            gestureState.clearScrubFraction()
        }
    }

    private func previewLiveScrub(_ fraction: Double, now: Date = Date()) {
        guard gestureState.beginScrub(at: fraction, now: now) else {
            return
        }

        previewSeekPlayback(fraction)
    }

    private func finishScrubbingAfterRelease() {
        scrubReleaseTask?.cancel()
        scrubReleaseTask = Task { @MainActor in
            do {
                try await Task.sleep(for: WaveformScrubMetrics.scrubReleaseDelay)
            } catch {
                return
            }
            clearScrubFraction()
            scrubReleaseTask = nil
        }
    }

    private func beginLongPressIfNeeded(at location: CGPoint, trackRect: CGRect) {
        guard pressTask == nil else { return }
        guard !gestureState.hasAddedMarkerDuringCurrentPress else { return }

        let token = UUID()
        pressToken = token
        gestureState.prepareLongPress()
        let position = min(max(CGFloat(waveformFraction(for: location.x, in: trackRect)), 0.10), 0.90)

        pressTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(520))
            guard pressToken == token else { return }

            let marker = WaveformMarker.created(
                position: position,
                time: progress.timeLabel(atFraction: Double(position)),
                existingCount: markers.count
            )

            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                markers.append(marker)
                selectedMarker = marker
            }

            gestureState.markAddedMarker(now: Date())
            pressTask = nil
        }
    }

    private func cancelLongPress(resetScrubbing: Bool = true) {
        pressToken = UUID()
        pressTask?.cancel()
        pressTask = nil
        gestureState.cancelLongPressState(resetScrubbing: resetScrubbing)
    }
}

private struct WaveformCanvasLayer: View {
    let trackRect: CGRect
    let barSpacing: CGFloat
    let displayedFraction: Double
    let isPlaying: Bool
    let reduceMotion: Bool
    let animationPhase: TimeInterval
    private static let bars = [CGFloat].waveformBars

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, _ in
            let bars = Self.bars
            let barWidth = WaveformVisualMetrics.barWidth(in: trackRect.width)
            let playedThreshold = CGFloat(min(max(displayedFraction, 0), 1))
            let phase = CGFloat(animationPhase)
            let bedHeight = min(trackRect.height * 0.64, WaveformVisualMetrics.maxBarHeight + 30)
            let bedRect = CGRect(
                x: trackRect.minX - 10,
                y: trackRect.midY - bedHeight / 2,
                width: trackRect.width + 20,
                height: bedHeight
            )
            let bedPath = Path(roundedRect: bedRect, cornerRadius: bedHeight / 2)

            context.fill(bedPath, with: .color(Color.black.opacity(0.17)))
            context.stroke(bedPath, with: .color(Color.white.opacity(0.045)), lineWidth: 1)

            var activeGlowPath = Path()

            for (index, height) in bars.enumerated() {
                let barFraction = CGFloat(index) / CGFloat(max(bars.count - 1, 1))
                let distanceFromPlayhead = abs(barFraction - playedThreshold)
                let activeFalloff = Self.activeFalloff(distance: distanceFromPlayhead)
                let pulse = reduceMotion || !isPlaying ? 0 : sin(phase * 4.8 + CGFloat(index) * 0.42)
                let liveLift = activeFalloff * (0.12 + 0.035 * pulse)
                let barHeight = min(
                    WaveformVisualMetrics.maxBarHeight + 8,
                    max(
                        WaveformVisualMetrics.minBarHeight,
                        WaveformVisualMetrics.maxBarHeight * height * (1 + liveLift)
                    )
                )
                let x = trackRect.minX + CGFloat(index) * (barWidth + barSpacing)
                let y = trackRect.midY - barHeight / 2
                let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let barPath = Path(roundedRect: barRect, cornerRadius: barWidth / 2)
                let barColor = Self.barColor(
                    barFraction: barFraction,
                    playedThreshold: playedThreshold,
                    activeFalloff: activeFalloff
                )

                if activeFalloff > 0.05 {
                    activeGlowPath.addPath(barPath)
                }

                context.fill(barPath, with: .color(barColor))
            }

            context.drawLayer { layer in
                layer.addFilter(.shadow(color: Color.studioGold.opacity(0.22), radius: 6, x: 0, y: 0))
                layer.fill(activeGlowPath, with: .color(Color.white.opacity(0.24)))
            }

            let playheadX = trackRect.minX + trackRect.width * playedThreshold
            let playheadRect = CGRect(
                x: playheadX - WaveformVisualMetrics.playheadWidth,
                y: trackRect.midY - WaveformVisualMetrics.playheadHeight / 2,
                width: WaveformVisualMetrics.playheadWidth * 2,
                height: WaveformVisualMetrics.playheadHeight
            )
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: Color.studioGold.opacity(0.26), radius: 5, x: 0, y: 0))
                layer.fill(
                    Path(roundedRect: playheadRect, cornerRadius: WaveformVisualMetrics.playheadWidth),
                    with: .color(Color.white.opacity(0.86))
                )
            }
        }
    }

    private static func activeFalloff(distance: CGFloat) -> CGFloat {
        let radius: CGFloat = 0.080
        let normalized = max(0, 1 - distance / radius)
        return normalized * normalized
    }

    private static func barColor(
        barFraction: CGFloat,
        playedThreshold: CGFloat,
        activeFalloff: CGFloat
    ) -> Color {
        if activeFalloff > 0.48 {
            return Color.white.opacity(0.58 + Double(activeFalloff) * 0.28)
        }

        if barFraction <= playedThreshold {
            return Color.studioGold.opacity(0.34 + Double(activeFalloff) * 0.34)
        }

        return Color.studioText.opacity(0.16 + Double(activeFalloff) * 0.22)
    }
}

struct MarkerListView: View {
    let markers: [WaveformMarker]
    @Binding var selectedMarker: WaveformMarker?
    let addMarkerAtPlayhead: () -> Void
    let editMarker: (WaveformMarker) -> Void
    let seekToMarker: (Double) -> Void
    let toggleResolved: (WaveformMarker) -> Void
    @State private var selectedFilter: WaveformMarkerFilter = .all

    private var visibleMarkers: [WaveformMarker] {
        markers.filtered(by: selectedFilter)
    }

    private var markerAccessibilityValue: String {
        guard !markers.isEmpty else {
            return "No markers"
        }

        return markers.map(\.accessibilitySummary).joined(separator: "; ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Markers")
                    .font(StudioType.control)
                    .foregroundStyle(Color.studioText)

                Spacer()

                Text("\(markers.count)")
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(Color.studioMuted)
                    .monospacedDigit()

                Button(action: addMarkerAtPlayhead) {
                    ZStack {
                        Circle()
                            .fill(Color.studioGold)
                            .frame(
                                width: MarkerTouchMetrics.compactIconVisualDiameter,
                                height: MarkerTouchMetrics.compactIconVisualDiameter
                            )

                        Image(systemName: "plus")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.studioBackground)
                    }
                    .frame(
                        width: MarkerTouchMetrics.minimumTouchTarget,
                        height: MarkerTouchMetrics.minimumTouchTarget
                    )
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add marker at playhead")
                .accessibilityIdentifier("add-marker-at-playhead")
            }

            if markers.count > 1 {
                MarkerFilterStrip(
                    markers: markers,
                    selectedFilter: selectedFilter,
                    select: { selectedFilter = $0 }
                )
            }

            VStack(spacing: 8) {
                if visibleMarkers.isEmpty {
                    EmptyMarkerFilterState(filter: selectedFilter)
                } else {
                    ForEach(visibleMarkers) { marker in
                        MarkerActionRow(
                            marker: marker,
                            isSelected: selectedMarker?.id == marker.id,
                            select: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    selectedMarker = marker
                                }
                                seekToMarker(Double(marker.position))
                            },
                            toggleResolved: { toggleResolved(marker) },
                            edit: { editMarker(marker) }
                        )
                    }
                }
            }
        }
        .onChange(of: markers) { _, updatedMarkers in
            if selectedFilter != .all, updatedMarkers.filtered(by: selectedFilter).isEmpty {
                selectedFilter = .all
            }
        }
        .accessibilityValue(markerAccessibilityValue)
        .accessibilityIdentifier("marker-list")
    }
}

private struct MarkerNotePopover: View {
    let marker: WaveformMarker
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                if differentiateWithoutColor {
                    Image(systemName: marker.colorToken.symbolName)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(marker.color)
                        .accessibilityHidden(true)
                }

                Text(marker.time)
                    .font(StudioType.marker)
                    .foregroundStyle(marker.color)

                if marker.isResolved {
                    Text("Resolved")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(marker.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(marker.color.opacity(0.13), in: Capsule())
                }
            }

            Text(marker.note.isEmpty ? "Add a note" : marker.note)
                .font(StudioType.marker)
                .foregroundStyle(marker.isResolved || marker.note.isEmpty ? Color.studioMuted : Color.studioText)
                .strikethrough(marker.isResolved, color: Color.studioMuted.opacity(0.68))
                .italic(marker.note.isEmpty)
                .lineLimit(3)
        }
        .padding(11)
        .frame(width: 188, alignment: .leading)
        .background(Color.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct MarkerFilterStrip: View {
    let markers: [WaveformMarker]
    let selectedFilter: WaveformMarkerFilter
    let select: (WaveformMarkerFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WaveformMarkerFilter.allCases) { filter in
                    Button {
                        select(filter)
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.title)
                                .lineLimit(1)

                            Text("\(markers.count(for: filter))")
                                .monospacedDigit()
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(filter == selectedFilter ? Color.studioBackground : Color.studioText)
                        .padding(.horizontal, 11)
                        .frame(minHeight: MarkerTouchMetrics.markerFilterHitHeight)
                        .background(filter == selectedFilter ? Color.studioGold : Color.white.opacity(0.06), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(markers.count(for: filter) == 0)
                    .opacity(markers.count(for: filter) == 0 ? 0.46 : 1)
                    .accessibilityLabel("Show \(filter.title.lowercased()) markers")
                    .accessibilityValue(filter == selectedFilter ? "Selected" : "\(markers.count(for: filter)) markers")
                }
            }
            .padding(.vertical, 1)
        }
        .accessibilityIdentifier("marker-filter-strip")
    }
}

private struct EmptyMarkerFilterState: View {
    let filter: WaveformMarkerFilter

    var body: some View {
        Text("No \(filter.title.lowercased()) markers yet.")
            .font(StudioType.metadataSmall)
            .foregroundStyle(Color.studioMuted)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.white.opacity(0.035), in: Capsule())
            .accessibilityIdentifier("empty-marker-filter-state")
    }
}

private struct MarkerActionRow: View {
    let marker: WaveformMarker
    let isSelected: Bool
    let select: () -> Void
    let toggleResolved: () -> Void
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: select) {
                MarkerListRow(
                    marker: marker,
                    isSelected: isSelected
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Jump to \(marker.accessibilitySummary)")
            .accessibilityIdentifier("marker-jump-\(marker.id.uuidString)")

            Button(action: toggleResolved) {
                Image(systemName: marker.isResolved ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(marker.isResolved ? Color.studioMint : Color.studioMuted)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(marker.isResolved ? 0.07 : 0.04), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(marker.isResolved ? "Reopen marker at \(marker.time)" : "Resolve marker at \(marker.time)")
            .accessibilityIdentifier("marker-resolve-\(marker.id.uuidString)")

            Button(action: edit) {
                Image(systemName: "pencil")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.studioMuted)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.04), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit marker at \(marker.time)")
            .accessibilityIdentifier("marker-edit-\(marker.id.uuidString)")
        }
    }
}

private struct MarkerListRow: View {
    let marker: WaveformMarker
    let isSelected: Bool
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(spacing: 11) {
            Capsule()
                .fill(marker.color)
                .frame(width: 2, height: max(18, 34 * marker.height))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    if differentiateWithoutColor {
                        Image(systemName: marker.colorToken.symbolName)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(marker.color)
                            .accessibilityHidden(true)
                    }

                    Text(marker.time)
                        .font(StudioType.marker)
                        .foregroundStyle(marker.color)

                    if marker.isResolved {
                        Text("Resolved")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(marker.color)
                            .lineLimit(1)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(marker.color.opacity(0.12), in: Capsule())
                    }
                }

                Text(marker.note.isEmpty ? "Add a note" : marker.note)
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(marker.isResolved || marker.note.isEmpty ? Color.studioMuted.opacity(0.62) : Color.studioMuted)
                    .strikethrough(marker.isResolved, color: Color.studioMuted.opacity(0.65))
                    .italic(marker.note.isEmpty)
                    .lineLimit(1)
                    .accessibilityIdentifier("marker-note-text")
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark" : "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.studioMuted)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 58)
        .background(Color.white.opacity(isSelected ? 0.075 : 0.04), in: Capsule())
        .opacity(marker.isResolved ? 0.68 : 1)
    }
}
