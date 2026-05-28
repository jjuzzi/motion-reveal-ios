# iOS Music App Code Recipes

Live doc started: 2026-05-26

Purpose: keep reusable Apple-platform research and Swift/SwiftUI code snippets for the music app. Add new recipes here when a feature needs official-source research plus implementation code.

## Source Policy

- Prefer Apple Developer documentation, Apple support docs, and SDK headers.
- Treat blog/forum snippets as hints only.
- Record minimum OS and entitlement/Info.plist requirements beside code.
- Keep snippets dependency-free unless a future feature explicitly needs a package.

## Recipe Index

| Recipe | Use when | Status |
| --- | --- | --- |
| Animated album cover art | App needs Apple Music-style moving covers or animated Now Playing artwork | Researched, code template added |
| Import audio from other apps | App needs to appear in share/open/save flows for MP3s and other audio files | Researched, code template added |
| Dynamic Island, notch-style controls, and haptics | App needs a Live Activity in the Dynamic Island, long-press expanded controls, or a custom in-app top capsule | Researched, code template added |

## Animated Album Cover Art

### Official Sources

- [Apple Music Album Motion Guidelines](https://help.apple.com/itc/albummotionguide/en.lproj/static.html)
- [Apple Music for Artists: Album cover art](https://artists.apple.com/support/1120-cover-art)
- [Apple Developer: Providing animated artwork for media items](https://developer.apple.com/documentation/mediaplayer/providing-animated-artwork-for-media-items)
- [Apple Developer: MPMediaItemAnimatedArtwork](https://developer.apple.com/documentation/mediaplayer/mpmediaitemanimatedartwork)

### Apple Music Delivery Specs

Static cover art:

- File: `JPG`, `PNG`, or `GIF`
- Shape: perfect square
- Minimum size: `4000 x 4000`

Album motion:

- `3:4`: `2048 x 2732`, for iPhone / Android album pages
- `1:1`: `3840 x 3840`, for Mac / iPad / smart TVs
- Codec: `H.264`, `Apple ProRes 422`, or `Apple ProRes 4444`
- File: `.mp4` or `.mov`
- Audio track: none
- Length: `8-35 seconds`
- Bitrate: `45-100 Mbps`
- Frame rates: `23.976`, `24`, `25`, `29.97`, or `30 fps`
- Color: `Rec. 709` or `sRGB`
- First frame should work as the static cover.
- Loop should be seamless.

Design rules:

- Motion should extend the static cover, not become a separate music video.
- No unrelated cuts, borders, fake Apple Music UI, promo copy, frantic flashing, or poor AI artifacts.
- Keep important content inside safe areas, especially for `3:4` iPhone artwork.

### In-App SwiftUI Looping Cover

Use this for artwork inside the app UI. This is separate from the system Lock Screen / Now Playing API.

```swift
import AVKit
import SwiftUI

struct AnimatedAlbumCover: View {
    let videoURL: URL
    let fallbackImage: Image

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if reduceMotion {
                fallbackImage
                    .resizable()
                    .scaledToFill()
            } else {
                LoopingVideoView(url: videoURL)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
    }
}

struct LoopingVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()

        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill

        player.isMuted = true
        player.play()

        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var looper: AVPlayerLooper?
    }
}

final class PlayerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
```

### System Now Playing Animated Artwork

Minimum OS from current SDK headers:

- `MPMediaItemAnimatedArtwork`: iOS 26, tvOS 26, watchOS 26, visionOS 26, macOS 16
- Now Playing keys: `MPNowPlayingInfoProperty1x1AnimatedArtwork`, `MPNowPlayingInfoProperty3x4AnimatedArtwork`

Important constraints:

- Video URL must be a local file URL.
- Preview image should match the first frame.
- `artworkID` should change when preview or video changes.
- Query `MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys`; unsupported keys are ignored.

```swift
import MediaPlayer
import UIKit

@available(iOS 26.0, *)
func updateNowPlayingAnimatedArtwork(
    title: String,
    artist: String,
    squarePreview: UIImage,
    squareVideoURL: URL,
    tallPreview: UIImage?,
    tallVideoURL: URL?
) {
    var info: [String: Any] = [
        MPMediaItemPropertyTitle: title,
        MPMediaItemPropertyArtist: artist
    ]

    let supportedKeys = MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys

    if supportedKeys.contains(MPNowPlayingInfoProperty1x1AnimatedArtwork) {
        info[MPNowPlayingInfoProperty1x1AnimatedArtwork] = MPMediaItemAnimatedArtwork(
            artworkID: "square-\(squareVideoURL.lastPathComponent)",
            previewImageRequestHandler: { _ in squarePreview },
            videoAssetFileURLRequestHandler: { _ in squareVideoURL }
        )
    }

    if
        let tallPreview,
        let tallVideoURL,
        supportedKeys.contains(MPNowPlayingInfoProperty3x4AnimatedArtwork)
    {
        info[MPNowPlayingInfoProperty3x4AnimatedArtwork] = MPMediaItemAnimatedArtwork(
            artworkID: "tall-\(tallVideoURL.lastPathComponent)",
            previewImageRequestHandler: { _ in tallPreview },
            videoAssetFileURLRequestHandler: { _ in tallVideoURL }
        )
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
}
```

## Import Audio From Other Apps

Goal: if someone sends an MP3 or other audio file in Messages, Files, Mail, AirDrop, etc., the app should appear as a destination and save the file into the app.

There are two complementary paths:

1. Main app document support: makes the app appear in `Open In`, `Copy to`, and file handoff flows for supported audio types.
2. Share extension: makes the app appear in the iOS share sheet as an action/destination for audio attachments.

Use both for a music app. Document support catches file-opening flows. Share extension catches richer share flows where the host app passes attachments through `NSItemProvider`.

### Official Sources

- [Apple Developer: Information Property List](https://developer.apple.com/documentation/BundleResources/Information-Property-List)
- [Apple Developer: Data and storage Info.plist keys](https://developer.apple.com/documentation/bundleresources/data-and-storage)
- [Apple Developer: CFBundleDocumentTypes / LSItemContentTypes / LSHandlerRank](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundledocumenttypes/lshandlerrank)
- [Apple Developer: Uniform Type Identifiers](https://developer.apple.com/documentation/UniformTypeIdentifiers)
- [Apple Developer: UTType](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct)
- [Apple Developer: UIDocumentPickerViewController](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller)
- [Apple Developer: onOpenURL](https://developer.apple.com/documentation/SwiftUI/View/onOpenURL%28perform%3A%29/)
- [Apple App Extension Programming Guide: Share](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)
- [Apple App Extension Programming Guide: Declaring Supported Data Types](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)
- [Apple Developer: NSItemProvider](https://developer.apple.com/documentation/foundation/nsitemprovider)
- [Apple Developer: App Groups Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.application-groups)
- [Apple Developer: FileManager app group container URL](https://developer.apple.com/documentation/Foundation/FileManager/containerURL%28forSecurityApplicationGroupIdentifier%3A%29)

### UTTypes To Support

Apple system identifiers from the current SDK:

| Content | UTI |
| --- | --- |
| Any audio | `public.audio` |
| MP3 | `public.mp3` |
| MPEG-4 audio / M4A | `public.mpeg-4-audio` |
| Protected Apple MPEG-4 audio / M4P | `com.apple.protected-mpeg-4-audio` |
| AIFF | `public.aiff-audio` |
| WAV | `com.microsoft.waveform-audio` |

Prefer `public.audio` for broad matching. Add specific types when a host app only advertises a precise UTI.

### Main App Info.plist

Add document types to the app target. For an import/save workflow, keep `LSSupportsOpeningDocumentsInPlace` omitted or `false` so the app receives/copies files instead of editing the source in place.

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Audio Files</string>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.audio</string>
            <string>public.mp3</string>
            <string>public.mpeg-4-audio</string>
            <string>public.aiff-audio</string>
            <string>com.microsoft.waveform-audio</string>
        </array>
    </dict>
</array>
<key>LSSupportsOpeningDocumentsInPlace</key>
<false/>
```

Notes:

- `Viewer` means the app can consume/open the file.
- `Alternate` avoids claiming default ownership of all audio files.
- If the app later becomes a document editor that edits external files in place, revisit `LSSupportsOpeningDocumentsInPlace` and security-scoped bookmarks.

### Main App Import Store

Use one import path for `.onOpenURL`, document picker imports, AirDrop handoff, and share-extension intake.

```swift
import Foundation

enum AudioImportStore {
    static func importsDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("Imported Audio", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @discardableResult
    static func importAudioFile(from sourceURL: URL) throws -> URL {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let directory = try importsDirectory()
        let destination = uniqueDestination(
            in: directory,
            preferredName: sourceURL.lastPathComponent
        )

        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }

    private static func uniqueDestination(in directory: URL, preferredName: String) -> URL {
        let cleanName = preferredName.isEmpty ? "Imported Audio" : preferredName
        let baseName = (cleanName as NSString).deletingPathExtension
        let ext = (cleanName as NSString).pathExtension

        var candidate = directory.appendingPathComponent(cleanName)
        var counter = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            let filename = ext.isEmpty ? "\(baseName) \(counter)" : "\(baseName) \(counter).\(ext)"
            candidate = directory.appendingPathComponent(filename)
            counter += 1
        }

        return candidate
    }
}
```

### SwiftUI App Entry For Open-In Files

```swift
import SwiftUI

@main
struct MusicApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .onOpenURL { url in
                    Task {
                        do {
                            let importedURL = try AudioImportStore.importAudioFile(from: url)
                            await MainActor.run {
                                // Insert importedURL into your library database.
                                // Example: library.addImportedTrack(fileURL: importedURL)
                            }
                        } catch {
                            // Route into your app's error state/toast/log.
                            assertionFailure("Audio import failed: \(error)")
                        }
                    }
                }
        }
    }
}
```

### In-App Document Picker Import

Use this when the user taps an Import button inside the app.

```swift
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct AudioDocumentPicker: UIViewControllerRepresentable {
    let onImport: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.audio],
            asCopy: true
        )
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImport: onImport)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onImport: (URL) -> Void

        init(onImport: @escaping (URL) -> Void) {
            self.onImport = onImport
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                onImport(url)
            }
        }
    }
}
```

Example presentation:

```swift
struct LibraryView: View {
    @State private var showingImporter = false

    var body: some View {
        Button("Import Audio") {
            showingImporter = true
        }
        .sheet(isPresented: $showingImporter) {
            AudioDocumentPicker { url in
                do {
                    let importedURL = try AudioImportStore.importAudioFile(from: url)
                    // Insert importedURL into your library database.
                } catch {
                    assertionFailure("Audio import failed: \(error)")
                }
            }
        }
    }
}
```

### Share Extension Info.plist

Create a Share Extension target in Xcode, then configure its `Info.plist`.

Set the extension target display name to the user-facing action label you want in the sheet, for example `Save to MyApp`.

```xml
<key>CFBundleDisplayName</key>
<string>Save to MyApp</string>
```

Use a predicate so the extension appears for audio attachments, not every possible share item.

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <string>SUBQUERY(extensionItems, $extensionItem, SUBQUERY($extensionItem.attachments, $attachment, ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.audio").@count == $extensionItem.attachments.@count).@count &gt;= 1</string>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
</dict>
```

For development only, `TRUEPREDICATE` can reveal the extension everywhere, but Apple says it must be replaced before App Store submission.

### App Group Entitlement

A share extension cannot write directly into the containing app's sandbox. Use an App Group so the extension and main app can share an intake folder.

Add this entitlement to both the app target and share extension target:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourcompany.yourapp</string>
</array>
```

Replace `group.com.yourcompany.yourapp` with the registered App Group ID.

### Shared Intake Store

Put this file in code shared by the app target and the share extension target.

```swift
import Foundation

enum SharedAudioImportStore {
    static let appGroupID = "group.com.yourcompany.yourapp"

    static func inboxDirectory() throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw ImportError.missingAppGroupContainer
        }

        let directory = container.appendingPathComponent("Incoming Audio", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @discardableResult
    static func copyIntoInbox(from sourceURL: URL, suggestedName: String?) throws -> URL {
        let directory = try inboxDirectory()
        let fallbackName = sourceURL.lastPathComponent.isEmpty ? "Shared Audio" : sourceURL.lastPathComponent
        let destination = uniqueDestination(
            in: directory,
            preferredName: suggestedName ?? fallbackName,
            fallbackExtension: sourceURL.pathExtension
        )

        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }

    static func pendingInboxFiles() throws -> [URL] {
        let directory = try inboxDirectory()
        return try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
    }

    static func removeInboxFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    private static func uniqueDestination(
        in directory: URL,
        preferredName: String,
        fallbackExtension: String
    ) -> URL {
        let cleanedName = preferredName.isEmpty ? "Shared Audio" : preferredName
        let nameExtension = (cleanedName as NSString).pathExtension
        let finalName = nameExtension.isEmpty && !fallbackExtension.isEmpty
            ? "\(cleanedName).\(fallbackExtension)"
            : cleanedName

        let baseName = (finalName as NSString).deletingPathExtension
        let ext = (finalName as NSString).pathExtension

        var candidate = directory.appendingPathComponent(finalName)
        var counter = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            let filename = ext.isEmpty ? "\(baseName) \(counter)" : "\(baseName) \(counter).\(ext)"
            candidate = directory.appendingPathComponent(filename)
            counter += 1
        }

        return candidate
    }

    enum ImportError: Error {
        case missingAppGroupContainer
        case missingSharedFile
    }
}
```

### Share Extension View Controller

This imports every shared audio attachment into the App Group inbox, then completes the share request.

```swift
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task {
            do {
                try await importSharedAudio()
                extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            } catch {
                extensionContext?.cancelRequest(withError: error)
            }
        }
    }

    private func importSharedAudio() async throws {
        let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] ?? []

        for item in extensionItems {
            for provider in item.attachments ?? [] {
                guard let audioType = provider.registeredContentTypes.first(where: { $0.conforms(to: .audio) }) else {
                    continue
                }

                try await copyAudioAttachment(from: provider, contentType: audioType)
            }
        }
    }

    private func copyAudioAttachment(
        from provider: NSItemProvider,
        contentType: UTType
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: contentType.identifier) { temporaryURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let temporaryURL else {
                    continuation.resume(throwing: SharedAudioImportStore.ImportError.missingSharedFile)
                    return
                }

                do {
                    try SharedAudioImportStore.copyIntoInbox(
                        from: temporaryURL,
                        suggestedName: provider.suggestedName
                    )
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

### Main App Consumes Share Extension Inbox

Run this when the app launches, becomes active, or the user opens the Import screen.

```swift
import Foundation

func consumeSharedAudioInbox() async {
    do {
        let pendingFiles = try SharedAudioImportStore.pendingInboxFiles()

        for fileURL in pendingFiles {
            let importedURL = try AudioImportStore.importAudioFile(from: fileURL)
            try SharedAudioImportStore.removeInboxFile(at: fileURL)

            await MainActor.run {
                // Insert importedURL into your library database.
            }
        }
    } catch {
        assertionFailure("Shared audio inbox import failed: \(error)")
    }
}
```

SwiftUI hook:

```swift
import SwiftUI

struct LibraryView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        LibraryContent()
            .task {
                await consumeSharedAudioInbox()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await consumeSharedAudioInbox()
                    }
                }
            }
    }
}
```

### Testing Checklist

- Install app on a real device; share extensions are easiest to validate outside Simulator.
- Share an `.mp3` from Files into the app.
- Share an `.m4a` from Files into the app.
- AirDrop an audio file and verify the app appears.
- Send an MP3 through Messages, long-press/share it, and verify the share extension appears.
- Confirm imported files land in `Application Support/Imported Audio`.
- Confirm share-extension files first land in App Group `Incoming Audio`, then move into the app import store.
- Confirm duplicate filenames become `Name 2.mp3`, `Name 3.mp3`, etc.
- Confirm the extension does not appear for unrelated text-only shares.

### Later Research

- File Provider extension: only needed if the app should appear as a full Files app storage location.
- Audio metadata extraction: `AVAsset` / `AVMetadataItem` for title, artist, duration, artwork, BPM, ISRC.
- Background import queue: useful if imported files can be large or require waveform/analysis jobs.

## Dynamic Island, Notch-Style Controls, And Haptics

Goal: support the real Dynamic Island for an ongoing music/audio activity, and separately support a custom in-app top capsule that can expand on press/hold with haptic feedback.

Important distinction:

- Real Dynamic Island: system-owned. You use ActivityKit + WidgetKit Live Activities. The user can touch and hold the island; iOS shows the expanded presentation you define. You cannot freely control the notch, intercept the system gesture, or draw arbitrary always-on UI there.
- In-app notch-style control: app-owned. You can draw a top capsule under/around the safe area, add a long press gesture, haptics, and show a mini container with features.

### Official Sources

- [Apple HIG: Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities)
- [Apple Developer: Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Apple Developer: Creating custom views for Live Activities](https://developer.apple.com/documentation/ActivityKit/creating-custom-views-for-live-activities)
- [Apple Developer: DynamicIsland](https://developer.apple.com/documentation/widgetkit/dynamicisland)
- [Apple HIG: Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- [Apple Developer: SensoryFeedback](https://developer.apple.com/documentation/swiftui/sensoryfeedback)
- [Apple Developer: UINotificationFeedbackGenerator](https://developer.apple.com/documentation/uikit/uinotificationfeedbackgenerator)
- [Apple Developer: Core Haptics](https://developer.apple.com/documentation/corehaptics)

### Design Specs And Constraints

Dynamic Island presentations:

| Presentation | Trigger / use |
| --- | --- |
| Compact | One active Live Activity; split into leading and trailing content around the TrueDepth camera |
| Minimal | Multiple Live Activities; tiny attached/detached presentation |
| Expanded | User touches and holds the compact/minimal Dynamic Island |
| Lock Screen | Banner/card at bottom of Lock Screen; should align with expanded presentation |

Apple guidance:

- Support compact, minimal, expanded, and Lock Screen presentations.
- Keep compact content essential, narrow, and snug around the TrueDepth camera.
- Expanded layout should feel like a predictable enlargement of compact/minimal content.
- Dynamic Island presentations use a black opaque background.
- Use consistent margins and concentric rounded placement. `ContainerRelativeShape` helps match the outer shape.
- Keep interactivity simple. If adding buttons or toggles to a Live Activity, use them only for essential actions directly tied to the activity, usually one primary control. CarPlay can display Live Activity content but deactivates interactive elements.
- Do not add in-app elements that draw attention to the Dynamic Island.
- Do not use Live Activities for ads or promotions.
- Avoid sensitive information because Live Activities are visible in public contexts.
- Start Live Activities only for ongoing tasks with clear beginning/end, and make them easy to stop.
- End the Live Activity when the task ends.

Known dimensions from Apple HIG:

| Device class | Compact/minimal width | Expanded width |
| --- | ---: | ---: |
| Pro Max / Plus / Air class Dynamic Island iPhones | `250 pt` | `408 pt` |
| Pro / standard Dynamic Island iPhones | `230 pt` | `371 pt` |

Other size guidance:

- Dynamic Island corner radius: `44 pt`
- Compact leading/trailing sample size on `430 x 932`: about `62.33 x 36.67 pt`
- Compact leading/trailing sample size on `393 x 852`: about `52.33 x 36.67 pt`
- Minimal sample size: about `36.67-45 x 36.67 pt`
- Expanded height range: `84-160 pt`
- Lock Screen height range: `84-160 pt`
- Lock Screen standard margin: `14 pt`

Treat these as design targets, not hardcoded layout math. Use SwiftUI layout, truncation, and previews because Apple says actual size can vary or change.

### Target Setup

Requirements:

- Main app target
- Widget extension target with Live Activity support
- `ActivityKit`
- `WidgetKit`
- `SwiftUI`
- iOS 16.1+ for Live Activities / Dynamic Island APIs
- iOS 17+ for SwiftUI `sensoryFeedback`

Main app `Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

Optional, if frequent updates are truly needed:

```xml
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

### Live Activity Attributes

Put this type in code shared by the app target and widget extension target.

```swift
import ActivityKit
import Foundation

struct PlaybackActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var artist: String
        var elapsed: TimeInterval
        var duration: TimeInterval
        var isPlaying: Bool
    }

    var trackID: String
    var artworkName: String?
}
```

### Dynamic Island Widget

Add this in the widget extension target.

```swift
import ActivityKit
import SwiftUI
import WidgetKit

struct PlaybackLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PlaybackActivityAttributes.self) { context in
            PlaybackLockScreenView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ArtworkDot(name: context.attributes.artworkName)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    PlaybackStatePill(isPlaying: context.state.isPlaying)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.title)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                        Text(context.state.artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    PlaybackExpandedControls(context: context)
                }
                .contentMargins(.top, 8)
            } compactLeading: {
                ArtworkDot(name: context.attributes.artworkName)
            } compactTrailing: {
                Text(context.state.isPlaying ? "Live" : "Pause")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(context.state.isPlaying ? .green : .secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(context.state.isPlaying ? .green : .secondary)
            }
            .widgetURL(URL(string: "myapp://track/\(context.attributes.trackID)"))
            .keylineTint(.green)
            .contentMargins(.all, 6, for: .compactLeading)
            .contentMargins(.all, 6, for: .compactTrailing)
            .contentMargins(.all, 8, for: .expanded)
        }
    }
}

private struct PlaybackLockScreenView: View {
    let context: ActivityViewContext<PlaybackActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            ArtworkDot(name: context.attributes.artworkName)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                Text(context.state.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            PlaybackStatePill(isPlaying: context.state.isPlaying)
        }
        .padding(14)
    }
}

private struct PlaybackExpandedControls: View {
    let context: ActivityViewContext<PlaybackActivityAttributes>

    var body: some View {
        HStack(spacing: 10) {
            Link(destination: URL(string: "myapp://player/queue")!) {
                Label("Queue", systemImage: "list.bullet")
            }

            Link(destination: URL(string: "myapp://track/\(context.attributes.trackID)/save")!) {
                Label("Save", systemImage: "plus.circle")
            }

            Link(destination: URL(string: "myapp://player")!) {
                Label(context.state.isPlaying ? "Pause" : "Play",
                      systemImage: context.state.isPlaying ? "pause.fill" : "play.fill")
            }
        }
        .font(.caption.weight(.semibold))
        .labelStyle(.iconOnly)
    }
}

private struct ArtworkDot: View {
    let name: String?

    var body: some View {
        ZStack {
            if let name {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.green)
            }
        }
        .clipShape(ContainerRelativeShape())
    }
}

private struct PlaybackStatePill: View {
    let isPlaying: Bool

    var body: some View {
        Image(systemName: isPlaying ? "waveform" : "pause.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(isPlaying ? .green : .secondary)
            .frame(width: 34, height: 24)
            .background(.white.opacity(0.12), in: Capsule())
    }
}
```

### Start, Update, End Live Activity

Put this in the main app target.

```swift
import ActivityKit
import Foundation

@MainActor
final class PlaybackActivityController {
    private var activity: Activity<PlaybackActivityAttributes>?

    func start(trackID: String, title: String, artist: String, duration: TimeInterval) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = PlaybackActivityAttributes(
            trackID: trackID,
            artworkName: nil
        )
        let state = PlaybackActivityAttributes.ContentState(
            title: title,
            artist: artist,
            elapsed: 0,
            duration: duration,
            isPlaying: true
        )
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            assertionFailure("Failed to start Live Activity: \(error)")
        }
    }

    func update(title: String, artist: String, elapsed: TimeInterval, duration: TimeInterval, isPlaying: Bool) async {
        guard let activity else {
            return
        }

        let state = PlaybackActivityAttributes.ContentState(
            title: title,
            artist: artist,
            elapsed: elapsed,
            duration: duration,
            isPlaying: isPlaying
        )

        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end() async {
        guard let activity else {
            return
        }

        await activity.end(nil, dismissalPolicy: .immediate)
        self.activity = nil
    }
}
```

### Deep Link Routes From The Island

Handle the URLs set with `widgetURL` / `Link`.

```swift
import SwiftUI

@main
struct MusicApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "myapp", let host = url.host else {
            return
        }

        let components = Array(url.pathComponents.dropFirst())

        switch host {
        case "track":
            let trackID = components.first
            // Open track detail or save flow.
            _ = trackID
        case "player":
            // Open player or queue.
            break
        default:
            break
        }
    }
}
```

### Haptic Feedback Rules

Apple guidance:

- Use system-provided haptic patterns for their intended meanings.
- Keep a clear cause/effect relationship.
- Match haptic intensity to animation intensity.
- Avoid frequent or decorative haptics.
- Make custom haptics optional.
- Standard controls already play haptics in many cases.

Recommended mapping for this app:

| Moment | Feedback |
| --- | --- |
| Press/hold begins on custom capsule | light impact |
| Capsule expands | medium impact or SwiftUI `.impact(weight: .medium)` |
| Save/import succeeds | success |
| Import or playback warning | warning |
| Import failed | error |
| Scrub/step through discrete values | selection |

SwiftUI iOS 17+:

```swift
import SwiftUI

struct SaveButton: View {
    @State private var saveCount = 0

    var body: some View {
        Button {
            saveTrack()
            saveCount += 1
        } label: {
            Label("Save", systemImage: "plus.circle")
        }
        .sensoryFeedback(.success, trigger: saveCount)
    }

    private func saveTrack() {
        // Save current track.
    }
}
```

UIKit fallback:

```swift
import UIKit

enum Haptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
```

Core Haptics support check for custom patterns:

```swift
import CoreHaptics

func deviceSupportsCustomHaptics() -> Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
}
```

### Custom In-App Notch Capsule

Use this if the app should have its own press-and-hold top control. This is not the system Dynamic Island.

```swift
import SwiftUI

struct NotchCapsuleControl: View {
    @State private var isExpanded = false
    @State private var hapticTrigger = 0

    var body: some View {
        VStack(spacing: 0) {
            capsule
                .padding(.top, 8)
                .gesture(
                    LongPressGesture(minimumDuration: 0.28)
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                isExpanded.toggle()
                            }
                            hapticTrigger += 1
                        }
                )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
    }

    private var capsule: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)

                Text("Playing")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 28)

            if isExpanded {
                HStack(spacing: 12) {
                    Button {
                        Haptics.selection()
                    } label: {
                        Image(systemName: "backward.fill")
                    }

                    Button {
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: "playpause.fill")
                    }

                    Button {
                        Haptics.success()
                    } label: {
                        Image(systemName: "plus.circle")
                    }

                    Button {
                        Haptics.selection()
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
                .buttonStyle(.plain)
                .font(.headline)
                .frame(height: 34)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, isExpanded ? 12 : 4)
        .frame(width: isExpanded ? 260 : 154)
        .background(.black.opacity(0.92), in: RoundedRectangle(cornerRadius: isExpanded ? 28 : 18, style: .continuous))
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Playback controls")
    }
}
```

Design notes for the in-app capsule:

- Keep it below the safe area so it does not fight system status items.
- Avoid mimicking the real Dynamic Island too literally; make it feel like a player control.
- Keep collapsed width stable and content short.
- Use haptics only at mode changes and important actions.
- Respect Reduce Motion if adding larger transitions.

### Testing Checklist

- Preview compact, minimal, expanded, and Lock Screen Live Activity states in Xcode.
- Test on a Dynamic Island device, not only Simulator.
- Start a Live Activity, lock device, verify Lock Screen.
- Long-press Dynamic Island, verify expanded layout and links.
- Run multiple Live Activities, verify minimal presentation.
- Verify text truncates cleanly at `230 pt` compact width and `371 pt` expanded width.
- Verify Always-On display contrast if using custom Lock Screen colors.
- Verify haptics on a physical iPhone; Simulator will not prove tactile quality.
- Verify haptics can be disabled in app settings if custom haptics become frequent.
