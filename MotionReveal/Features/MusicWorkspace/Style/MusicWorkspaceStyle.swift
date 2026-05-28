import SwiftUI

enum StudioType {
    static let screenTitle: Font = semibold(size: 34, relativeTo: .largeTitle)
    static let projectTitle: Font = semibold(size: 34, relativeTo: .largeTitle)
    static let deckTitle: Font = semibold(size: 22, relativeTo: .title2)
    static let rowTitle: Font = medium(size: 17, relativeTo: .headline)
    static let eyebrow: Font = medium(size: 12, relativeTo: .footnote)
    static let metadata: Font = regular(size: 15, relativeTo: .subheadline)
    static let metadataSmall: Font = regular(size: 12, relativeTo: .caption)
    static let control: Font = semibold(size: 17, relativeTo: .headline)
    static let marker: Font = medium(size: 12, relativeTo: .caption)

    static func regular(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func medium(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func semibold(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}
