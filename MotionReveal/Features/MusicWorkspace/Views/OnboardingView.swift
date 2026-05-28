import SwiftUI

struct StudioOnboardingView: View {
    let finish: () -> Void
    @State private var currentPage = 0

    private let pages = StudioOnboardingPage.allCases

    var body: some View {
        ZStack {
            Color.studioBackground
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 28)

                StudioBrandLockup(caption: "private album workspace")

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                        VStack(spacing: 22) {
                            TopPullPreview(page: page)

                            Text(page.title)
                                .font(StudioType.screenTitle)
                                .foregroundStyle(Color.studioText)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.82)

                            Text(page.body)
                                .font(StudioType.metadata)
                                .foregroundStyle(Color.studioMuted)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: 12) {
                                ForEach(page.steps, id: \.title) { step in
                                    OnboardingStep(systemName: step.systemName, title: step.title)
                                }
                            }
                        }
                        .tag(index)
                        .padding(.horizontal, 2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                .frame(maxWidth: .infinity)

                Button(action: primaryAction) {
                    Text(currentPage == pages.count - 1 ? "Start" : "Continue")
                        .font(StudioType.control)
                        .foregroundStyle(Color.studioBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            StudioPrimaryButtonBackground(isEnabled: true)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("finish-onboarding")

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 28)
        }
        .accessibilityIdentifier("studio-onboarding")
    }

    private func primaryAction() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                currentPage += 1
            }
        } else {
            finish()
        }
    }
}

private struct TopPullPreview: View {
    let page: StudioOnboardingPage

    var body: some View {
        VStack(spacing: 11) {
            VStack(spacing: 4) {
                StudioGlowSweep {
                    Capsule()
                        .frame(width: 94, height: 2)
                }
                .blur(radius: 0.5)

                Image(systemName: page.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.studioGold.opacity(0.74))

                StudioIslandLogoMark()
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.studioGold.opacity(0.26), radius: 12, x: 0, y: 6)
            }
        }
        .padding(.top, 8)
    }
}

private enum StudioOnboardingPage: CaseIterable, Hashable {
    case shelf
    case container
    case ritual

    var icon: String {
        switch self {
        case .shelf:
            return "square.stack.3d.up.fill"
        case .container:
            return "chevron.down"
        case .ritual:
            return "opticaldisc.fill"
        }
    }

    var title: String {
        switch self {
        case .shelf:
            return "Build a private shelf for unfinished music."
        case .container:
            return "Keep every song's working files in one hidden drawer."
        case .ritual:
            return "New projects begin with the disc."
        }
    }

    var body: String {
        switch self {
        case .shelf:
            return "Projects stay album-shaped, private, and easy to scan."
        case .container:
            return "Add a song, then hold and pull from the top edge to reveal the files, notes, and markers attached to it."
        case .ritual:
            return "When you create a project, tap the blank iridescent CD to send it into the player."
        }
    }

    var steps: [StudioOnboardingStepModel] {
        switch self {
        case .shelf:
            return [
                .init(systemName: "square.grid.2x2.fill", title: "Albums appear as icon covers"),
                .init(systemName: "photo", title: "Long-press a cover to change artwork"),
                .init(systemName: "pencil", title: "Rename projects whenever the idea changes")
            ]
        case .container:
            return [
                .init(systemName: "waveform", title: "Waveforms scrub while playing"),
                .init(systemName: "flag", title: "Markers stay user-named"),
                .init(systemName: "paperclip", title: "Attach stems, sessions, lyrics, refs, and any file")
            ]
        case .ritual:
            return [
                .init(systemName: "gyroscope", title: "The CD reacts to device tilt"),
                .init(systemName: "sparkles", title: "Motion artwork can be imported later"),
                .init(systemName: "dot.radiowaves.left.and.right", title: "The player can continue through Dynamic Island")
            ]
        }
    }
}

private struct StudioOnboardingStepModel: Hashable {
    let systemName: String
    let title: String
}

private struct OnboardingStep: View {
    let systemName: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.studioGold)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.06), in: Circle())

            Text(title)
                .font(StudioType.metadata)
                .foregroundStyle(Color.studioText)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}
