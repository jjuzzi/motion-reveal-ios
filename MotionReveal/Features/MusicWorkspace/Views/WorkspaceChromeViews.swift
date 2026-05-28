import SwiftUI

struct WorkspaceTopBar: View {
    let eyebrow: String?
    let title: String?
    let leadingAction: WorkspaceIconAction?
    let trailingButtons: [WorkspaceIconAction]

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if let leadingAction {
                WorkspaceIconButton(action: leadingAction)
            } else if eyebrow != nil || title != nil {
                VStack(alignment: .leading, spacing: 5) {
                    if let eyebrow {
                        Text(eyebrow.uppercased())
                            .font(StudioType.eyebrow)
                            .foregroundStyle(Color.studioMuted)
                    }

                    if let title {
                        Text(title)
                            .font(StudioType.screenTitle)
                            .foregroundStyle(Color.studioText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                }
            }

            Spacer()

            HStack(spacing: 10) {
                ForEach(trailingButtons) { button in
                    WorkspaceIconButton(action: button)
                }
            }
        }
        .frame(minHeight: 58)
    }
}

struct WorkspaceIconAction: Identifiable {
    let id = UUID()
    let systemName: String
    let label: String
    let action: () -> Void
}

struct WorkspaceIconMetrics: Equatable {
    static let minimumTouchTarget: CGFloat = 44
    static let chromeButtonSize: CGFloat = 46
    static let standaloneActionSize: CGFloat = minimumTouchTarget
}

struct WorkspaceIconButton: View {
    let action: WorkspaceIconAction

    var body: some View {
        Button(action: action.action) {
            MenuIconGlyph(systemName: action.systemName)
                .frame(width: WorkspaceIconMetrics.chromeButtonSize, height: WorkspaceIconMetrics.chromeButtonSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.label)
    }
}

struct MenuIconGlyph: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: systemName == "ellipsis" ? 15 : 17, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.studioText.opacity(0.90))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                StudioCircularBeamStroke()
            }
            .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
    }
}

private struct StudioCircularBeamStroke: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(baseGradient, lineWidth: 0.75)
                .opacity(0.72)

            Circle()
                .strokeBorder(chaseGradient, lineWidth: 0.65)
                .opacity(0.68)

            Circle()
                .strokeBorder(glowGradient, lineWidth: 1.15)
                .blur(radius: 0.85)
                .opacity(0.11)
        }
        .padding(2)
    }

    private var baseGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.10),
                Color.studioGold.opacity(0.28),
                Color.studioMint.opacity(0.18),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var chaseGradient: AngularGradient {
        AngularGradient(
            colors: [
                .clear,
                Color.studioGold.opacity(0.46),
                Color.studioMint.opacity(0.38),
                Color.studioRose.opacity(0.24),
                .clear
            ],
            center: .center,
            startAngle: .degrees(210),
            endAngle: .degrees(520)
        )
    }

    private var glowGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.studioGold.opacity(0.50),
                Color.studioMint.opacity(0.36),
                Color.studioRose.opacity(0.30)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
