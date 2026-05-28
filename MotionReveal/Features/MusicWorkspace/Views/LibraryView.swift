import SwiftUI

enum WorkspaceCoordinateSpace {
    static let name = "music-workspace"
}

private struct SleeveSourceFrameReader: View {
    @Binding var frame: CGRect?
    var onFrameChange: ((CGRect) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let currentFrame = proxy.frame(in: .named(WorkspaceCoordinateSpace.name))

            Color.clear
                .onAppear {
                    frame = currentFrame
                    onFrameChange?(currentFrame)
                }
                .onChange(of: currentFrame) { _, newFrame in
                    frame = newFrame
                    onFrameChange?(newFrame)
                }
        }
    }
}

struct LibraryScreen: View {
    let projects: [MusicProject]
    let openProject: (MusicProject, CGRect?) -> Void
    let recordLeadSourceRect: (CGRect?) -> Void
    let openMenu: (MusicProject) -> Void
    let renameProject: (MusicProject) -> Void
    let changeProjectCover: (MusicProject) -> Void
    let openSettings: () -> Void
    let createProject: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                WorkspaceTopBar(
                    eyebrow: "Studio shelf",
                    title: "Sleeve rack",
                    leadingAction: nil,
                    trailingButtons: projects.isEmpty ? [] : [
                        WorkspaceIconAction(systemName: "magnifyingglass", label: "Search") {},
                        WorkspaceIconAction(systemName: "gearshape", label: "Settings", action: openSettings)
                    ]
                )
                .padding(.top, 14)

                if projects.isEmpty {
                    EmptyLibraryState(createProject: createProject)
                } else {
                    ProjectIconGrid(
                        projects: projects,
                        openProject: openProject,
                        openMenu: openMenu,
                        renameProject: renameProject,
                        changeProjectCover: changeProjectCover
                    )
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 136)
        }
        .accessibilityIdentifier("library-screen")
    }
}

private struct ProjectIconGrid: View {
    let projects: [MusicProject]
    let openProject: (MusicProject, CGRect?) -> Void
    let openMenu: (MusicProject) -> Void
    let renameProject: (MusicProject) -> Void
    let changeProjectCover: (MusicProject) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
            ForEach(projects) { project in
                ProjectIconTile(
                    project: project,
                    openProject: { sourceRect in
                        openProject(project, sourceRect)
                    },
                    openMenu: {
                        openMenu(project)
                    },
                    renameProject: {
                        renameProject(project)
                    },
                    changeProjectCover: {
                        changeProjectCover(project)
                    }
                )
            }
        }
        .accessibilityIdentifier("project-icon-grid")
    }
}

private struct ProjectIconTile: View {
    let project: MusicProject
    let openProject: (CGRect?) -> Void
    let openMenu: () -> Void
    let renameProject: () -> Void
    let changeProjectCover: () -> Void
    @State private var sourceFrame: CGRect?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                openProject(sourceFrame)
            } label: {
                MotionSleeveArtworkView(
                    artwork: project.sleeve,
                    motionArtwork: project.displayedCoverMotionArtwork,
                    playbackPolicy: .animated
                )
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.26), radius: 18, x: 0, y: 10)
                    .background(SleeveSourceFrameReader(frame: $sourceFrame))
            }
            .buttonStyle(StudioSleevePressButtonStyle())
            .contextMenu {
                Button("Rename", systemImage: "pencil", action: renameProject)
                Button("Change cover", systemImage: "photo", action: changeProjectCover)
            }
            .accessibilityLabel("Open \(project.title)")
            .accessibilityHint("Long press for rename and cover options.")

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title)
                        .font(StudioType.deckTitle)
                        .foregroundStyle(Color.studioText)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        if project.state == .pinned {
                            Image(systemName: "pin.fill")
                        } else if project.state == .locked {
                            Image(systemName: "lock.fill")
                        }

                        Text(project.creator)
                            .lineLimit(1)
                    }
                    .font(StudioType.metadata)
                    .foregroundStyle(Color.studioMuted)
                }

                Spacer(minLength: 4)

                Button(action: openMenu) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 34, height: 34)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(project.title) actions")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("project-icon-\(project.id.uuidString)")
    }
}

private struct EmptyLibraryState: View {
    let createProject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SleeveArtworkView(artwork: .blank)
                .frame(width: 168, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Start with one sleeve")
                    .font(StudioType.deckTitle)
                    .foregroundStyle(Color.studioText)

                Text("Create a private project, then import the first bounce, voice memo, or rough mix.")
                    .font(StudioType.metadata)
                    .foregroundStyle(Color.studioMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: createProject) {
                Label("Create first sleeve", systemImage: "plus")
                    .font(StudioType.control)
                    .foregroundStyle(Color.studioBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background {
                        StudioPrimaryButtonBackground(isEnabled: true)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("empty-create-project")
        }
        .padding(22)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("empty-library-state")
    }
}

private struct StudioSleevePressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.976 : 1)
            .rotation3DEffect(
                .degrees(configuration.isPressed && !reduceMotion ? 2.4 : 0),
                axis: (x: 1, y: -0.35, z: 0),
                perspective: 0.58
            )
            .brightness(configuration.isPressed ? -0.025 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
    }
}


private struct SleeveDeckView: View {
    let projects: [MusicProject]
    let openProject: (MusicProject, CGRect?) -> Void
    let recordLeadSourceRect: (CGRect?) -> Void
    let openMenu: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.118, green: 0.105, blue: 0.083),
                            Color.studioBackground.opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.055), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.32), radius: 28, x: 0, y: 18)

            IridescentPool()
                .opacity(0.22)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .allowsHitTesting(false)

            ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                DeckSleeveButton(
                    project: project,
                    depth: index,
                    openProject: { sourceRect in
                        openProject(project, sourceRect)
                    },
                    recordSourceFrame: index == 0 ? recordLeadSourceRect : nil,
                    openMenu: openMenu
                )
                .zIndex(Double(projects.count - index))
            }

            if let leadProject = projects.first {
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(leadProject.title)
                            .font(StudioType.deckTitle)
                            .foregroundStyle(Color.studioText)
                            .lineLimit(1)

                        Text(leadProject.metadata)
                            .font(StudioType.metadataSmall)
                            .foregroundStyle(Color.studioMuted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 10)

                    Button(action: openMenu) {
                        MenuIconGlyph(systemName: "ellipsis")
                            .frame(width: WorkspaceIconMetrics.standaloneActionSize, height: WorkspaceIconMetrics.standaloneActionSize)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .accessibilityLabel("\(leadProject.title) actions")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 68)
            }

            DeckMeter()
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
        }
        .frame(height: 362)
        .accessibilityIdentifier("sleeve-deck")
    }
}

private struct DeckSleeveButton: View {
    let project: MusicProject
    let depth: Int
    let openProject: (CGRect?) -> Void
    let recordSourceFrame: ((CGRect?) -> Void)?
    let openMenu: () -> Void
    @State private var sourceFrame: CGRect?

    var body: some View {
        Button {
            openProject(sourceFrame)
        } label: {
            ZStack(alignment: .trailing) {
                MotionSleeveArtworkView(
                    artwork: project.sleeve,
                    motionArtwork: project.displayedCoverMotionArtwork,
                    playbackPolicy: .animated
                )
                    .frame(width: sleeveSize, height: sleeveSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(depth == 0 ? 0.16 : 0.08), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(depth == 0 ? 0.36 : 0.22), radius: depth == 0 ? 24 : 14, x: 0, y: depth == 0 ? 16 : 9)
                    .background(
                        SleeveSourceFrameReader(frame: $sourceFrame) { sourceRect in
                            recordSourceFrame?(sourceRect)
                        }
                    )

                if project.state != .folder {
                    DiscEdge()
                        .frame(width: depth == 0 ? 54 : 38, height: depth == 0 ? 54 : 38)
                        .offset(x: depth == 0 ? 22 : 16, y: depth == 0 ? -38 : -25)
                        .opacity(depth == 0 ? 1 : 0.72)
                }
            }
        }
        .buttonStyle(.plain)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .offset(x: xOffset, y: yOffset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, leadingPadding)
        .padding(.top, topPadding)
        .accessibilityLabel("Open \(project.title)")
    }

    private var sleeveSize: CGFloat {
        switch depth {
        case 0: return 190
        case 1: return 144
        default: return 128
        }
    }

    private var cornerRadius: CGFloat { depth == 0 ? 30 : 24 }
    private var leadingPadding: CGFloat { depth == 0 ? 24 : depth == 1 ? 154 : 52 }
    private var topPadding: CGFloat { depth == 0 ? 36 : depth == 1 ? 58 : 84 }
    private var xOffset: CGFloat { depth == 0 ? 0 : depth == 1 ? 50 : 162 }
    private var yOffset: CGFloat { depth == 0 ? 0 : depth == 1 ? -2 : 2 }
    private var rotation: Double { depth == 0 ? -5 : depth == 1 ? 7 : -9 }
    private var scale: CGFloat { depth == 0 ? 1 : depth == 1 ? 0.94 : 0.86 }
}

private struct DeckMeter: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array([CGFloat].waveformBars.prefix(42).enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(index == 20 ? Color.studioGold : Color.studioText.opacity(index < 20 ? 0.42 : 0.16))
                    .frame(width: index == 20 ? 3 : 2, height: max(6, 34 * height))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(0.92)
    }
}

private struct ProjectSpineList: View {
    let projects: [MusicProject]
    let openProject: (MusicProject, CGRect?) -> Void
    let openMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("RACK")
                    .font(StudioType.eyebrow)
                    .foregroundStyle(Color.studioMuted)

                Spacer()

                Text("\(projects.count) sleeves")
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(Color.studioMuted)
            }
            .padding(.horizontal, 2)

            ForEach(projects) { project in
                ProjectSpineRow(
                    project: project,
                    openProject: { sourceRect in
                        openProject(project, sourceRect)
                    },
                    openMenu: openMenu
                )
            }
        }
        .accessibilityIdentifier("project-spines")
    }
}

private struct ProjectSpineRow: View {
    let project: MusicProject
    let openProject: (CGRect?) -> Void
    let openMenu: () -> Void
    @State private var sourceFrame: CGRect?

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(spineStyle)
                .frame(width: 4, height: 54)
                .shadow(color: spineGlow, radius: 8, x: 0, y: 0)

            Button {
                openProject(sourceFrame)
            } label: {
                HStack(spacing: 12) {
                    MotionSleeveArtworkView(
                        artwork: project.sleeve,
                        motionArtwork: project.displayedCoverMotionArtwork,
                        playbackPolicy: .animated
                    )
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                        .background(SleeveSourceFrameReader(frame: $sourceFrame))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(StudioType.rowTitle)
                            .foregroundStyle(Color.studioText)
                            .lineLimit(1)

                        Text(project.metadata)
                            .font(StudioType.metadataSmall)
                            .foregroundStyle(Color.studioMuted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(project.title)")

            Button(action: openMenu) {
                MenuIconGlyph(systemName: "ellipsis")
                    .frame(width: WorkspaceIconMetrics.standaloneActionSize, height: WorkspaceIconMetrics.standaloneActionSize)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .accessibilityLabel("\(project.title) actions")
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.055))
                .frame(height: 1)
                .padding(.leading, 62)
        }
    }

    private var spineStyle: LinearGradient {
        switch project.state {
        case .folder:
            return LinearGradient(colors: [.studioMint, .studioBlue.opacity(0.82)], startPoint: .top, endPoint: .bottom)
        case .locked:
            return LinearGradient(colors: [.studioLavender, .studioBlue], startPoint: .top, endPoint: .bottom)
        case .fresh:
            return LinearGradient(colors: [.studioGold, .studioRose], startPoint: .top, endPoint: .bottom)
        case .pinned:
            return LinearGradient(colors: [.studioGold, .studioMint.opacity(0.92)], startPoint: .top, endPoint: .bottom)
        case .regular:
            return LinearGradient(colors: [.studioRose, .studioGold.opacity(0.86)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var spineGlow: Color {
        switch project.state {
        case .folder:
            return .studioMint.opacity(0.20)
        case .locked:
            return .studioLavender.opacity(0.20)
        case .fresh, .pinned:
            return .studioGold.opacity(0.20)
        case .regular:
            return .studioRose.opacity(0.18)
        }
    }
}

private struct SleeveRow: View {
    let project: MusicProject
    let openProject: () -> Void
    let openMenu: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: openProject) {
                ZStack(alignment: .trailing) {
                    MotionSleeveArtworkView(
                        artwork: project.sleeve,
                        motionArtwork: project.displayedCoverMotionArtwork,
                        playbackPolicy: .animated
                    )
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 19, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }

                    if project.state != .folder {
                        DiscEdge()
                            .frame(width: 24, height: 70)
                            .offset(x: 12)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(project.title)")

            VStack(alignment: .leading, spacing: 6) {
                Text(project.title)
                    .font(StudioType.rowTitle)
                    .foregroundStyle(Color.studioText)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    if project.state == .pinned {
                        Image(systemName: "pin.fill")
                            .font(StudioType.metadataSmall)
                    } else if project.state == .locked {
                        Image(systemName: "lock.fill")
                            .font(StudioType.metadataSmall)
                    }

                    Text(project.state == .folder ? project.creator : project.creator)
                        .lineLimit(1)
                }
                .font(StudioType.metadata)
                .foregroundStyle(Color.studioMuted)
            }

            Spacer(minLength: 10)

            Button(action: openMenu) {
                MenuIconGlyph(systemName: "ellipsis")
                    .frame(width: WorkspaceIconMetrics.standaloneActionSize, height: WorkspaceIconMetrics.standaloneActionSize)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .accessibilityLabel("\(project.title) actions")
        }
        .padding(12)
        .background(Color.studioPanel.opacity(project.state == .fresh ? 0.98 : 0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(project.state == .fresh ? Color.studioGold.opacity(0.40) : Color.white.opacity(0.055), lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            if project.state == .fresh {
                IridescentSweep()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .allowsHitTesting(false)
            }
        }
        .accessibilityIdentifier("sleeve-row-\(project.id.uuidString)")
    }
}
