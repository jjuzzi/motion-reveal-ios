import SwiftUI

enum DynamicNotchResultMode {
    case compact
    case expanded
}

struct DynamicNotchRevealView<Context: View, Focus: View, ResultCard: View, Detail: View>: View {
    let phase: DynamicNotchRevealPhase
    let showsResultCard: Bool
    let resultHasLanded: Bool
    let openDetail: () -> Void
    let closeDetail: () -> Void
    let reset: () -> Void
    let context: () -> Context
    let focusContent: () -> Focus
    let resultCard: (Namespace.ID, DynamicNotchResultMode) -> ResultCard
    let detail: (Namespace.ID, @escaping () -> Void, @escaping () -> Void) -> Detail

    @Namespace private var resultNamespace

    var body: some View {
        ZStack {
            context()
                .blur(radius: phase == .detail ? 10 : 0)
                .scaleEffect(phase == .detail ? 0.96 : 1)
                .animation(.spring(response: 0.55, dampingFraction: 0.86), value: phase)

            VStack {
                DynamicNotchPortal(phase: phase, focusContent: focusContent)
                    .padding(.top, 18)
                Spacer()
            }
            .zIndex(10)
            .animation(.spring(response: 0.55, dampingFraction: 0.84), value: phase)

            if showsResultCard, phase != .detail {
                Button(action: openDetail) {
                    resultCard(resultNamespace, .compact)
                }
                .buttonStyle(.plain)
                .offset(y: resultHasLanded ? 126 : -330)
                .rotationEffect(.degrees(resultHasLanded ? -4 : 0))
                .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 12)
                .zIndex(20)
                .disabled(!resultHasLanded)
                .accessibilityIdentifier("dynamic-notch-result-card")
                .animation(.spring(response: 0.7, dampingFraction: 0.72), value: resultHasLanded)
            }

            if phase == .detail {
                detail(resultNamespace, closeDetail, reset)
                    .transition(.opacity)
                    .zIndex(30)
            }
        }
    }
}

private struct DynamicNotchPortal<Focus: View>: View {
    let phase: DynamicNotchRevealPhase
    let focusContent: () -> Focus

    private var isExpanded: Bool {
        phase == .expanded
    }

    var body: some View {
        RoundedRectangle(cornerRadius: isExpanded ? 34 : 18, style: .continuous)
            .fill(.black)
            .frame(width: isExpanded ? 232 : 126, height: isExpanded ? 184 : 34)
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.09, green: 0.14, blue: 0.52),
                            Color(red: 0.08, green: 0.62, blue: 0.58),
                            Color(red: 0.95, green: 0.68, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .padding(16)
                    .opacity(isExpanded ? 1 : 0)

                    focusContent()
                        .padding(.horizontal, 26)
                        .opacity(isExpanded ? 1 : 0)
                        .scaleEffect(isExpanded ? 1 : 0.82)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(isExpanded ? 0.16 : 0), lineWidth: 1)
                        .padding(16)
                }
                .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 34 : 18, style: .continuous))
            }
            .shadow(color: .black.opacity(0.32), radius: 10, x: 0, y: 5)
            .accessibilityIdentifier("dynamic-notch-portal")
    }
}
