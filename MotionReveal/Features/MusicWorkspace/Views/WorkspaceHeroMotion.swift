import SwiftUI

enum WorkspaceHeroMotion {
    static func nowPlayingArtworkID(_ trackID: UUID) -> String {
        "now-playing-artwork-\(trackID.uuidString)"
    }
}

extension View {
    @ViewBuilder
    func workspaceHeroMatched(
        id: String,
        in namespace: Namespace.ID,
        isEnabled: Bool,
        properties: MatchedGeometryProperties = .frame,
        anchor: UnitPoint = .center
    ) -> some View {
        if isEnabled {
            matchedGeometryEffect(id: id, in: namespace, properties: properties, anchor: anchor)
        } else {
            self
        }
    }
}
