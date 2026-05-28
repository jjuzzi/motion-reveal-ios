import SwiftUI

struct DynamicNotchRevealDemoView: View {
    @State private var flow = DynamicNotchRevealFlow()

    var body: some View {
        DynamicNotchRevealView(
            phase: flow.phase,
            showsResultCard: flow.showsResultCard,
            resultHasLanded: flow.resultHasLanded,
            openDetail: openDetail,
            closeDetail: closeDetail,
            reset: reset,
            context: context,
            focusContent: focusContent,
            resultCard: resultCard,
            detail: { namespace, close, reset in
                detail(namespace: namespace, close: close, reset: reset)
            }
        )
        .preferredColorScheme(.dark)
    }

    private func context() -> some View {
        ZStack {
            DemoBackdrop(phase: flow.phase)

            VStack(spacing: 0) {
                DemoHeader(phase: flow.phase)
                    .padding(.top, 18)

                Spacer(minLength: 24)

                DemoPlaceholderGrid(phase: flow.phase)
                    .frame(maxWidth: 346)
                    .frame(height: 430)

                Spacer(minLength: 18)

                DemoPrimaryControls(
                    phase: flow.phase,
                    expand: expand,
                    commit: commit,
                    reset: reset
                )
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 20)

            VStack {
                Spacer()
                DemoFocusControls(isVisible: flow.phase == .expanded, commit: commit)
                    .padding(.bottom, 112)
            }
        }
    }

    private func focusContent() -> some View {
        DemoBars(color: .white.opacity(0.86), scale: 1)
    }

    private func resultCard(namespace: Namespace.ID, mode: DynamicNotchResultMode) -> some View {
        DemoResultCard(
            item: flow.selectedItem ?? .placeholder,
            namespace: namespace,
            mode: mode
        )
    }

    private func detail(
        namespace: Namespace.ID,
        close: @escaping () -> Void,
        reset: @escaping () -> Void
    ) -> some View {
        DemoDetailOverlay(
            item: flow.selectedItem ?? .placeholder,
            namespace: namespace,
            close: close,
            reset: reset
        )
    }

    private func expand() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            flow.expand()
        }
    }

    private func commit() {
        guard flow.phase == .expanded else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
            flow.commit()
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(620))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                flow.settleResult()
            }
        }
    }

    private func openDetail() {
        guard flow.resultHasLanded else { return }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            flow.openDetail()
        }
    }

    private func closeDetail() {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
            flow.settleResult()
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            flow.reset()
        }
    }
}

private struct DemoBackdrop: View {
    let phase: DynamicNotchRevealPhase

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.25, blue: 0.20)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(phase == .detail ? 0.80 : 0.24),
                    Color(red: 0.10, green: 0.45, blue: 0.44).opacity(phase == .expanded ? 0.48 : 0.18),
                    Color(red: 0.95, green: 0.76, blue: 0.28).opacity(phase == .landed ? 0.30 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

private struct DemoHeader: View {
    let phase: DynamicNotchRevealPhase

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("notch")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                Text("motion")
                    .font(.system(size: 29, weight: .black, design: .rounded))
            }
            .lineLimit(1)
            .foregroundStyle(.white)

            Spacer()

            Text(label)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.black.opacity(0.74))
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Color(red: 0.95, green: 0.76, blue: 0.28), in: Capsule())
        }
        .opacity(phase == .expanded ? 0.28 : 1)
    }

    private var label: String {
        switch phase {
        case .idle:
            return "IDLE"
        case .expanded:
            return "OPEN"
        case .ejecting:
            return "EJECT"
        case .landed:
            return "LAND"
        case .detail:
            return "DETAIL"
        }
    }
}

private struct DemoPlaceholderGrid: View {
    let phase: DynamicNotchRevealPhase

    private let colors = [
        [Color(red: 0.78, green: 0.92, blue: 0.86), Color(red: 0.95, green: 0.76, blue: 0.28)],
        [Color(red: 0.92, green: 0.21, blue: 0.18), Color(red: 0.95, green: 0.76, blue: 0.28)],
        [Color(red: 0.22, green: 0.36, blue: 0.88), Color(red: 0.78, green: 0.92, blue: 0.86)],
        [Color(red: 0.95, green: 0.76, blue: 0.28), Color(red: 0.92, green: 0.21, blue: 0.18)],
        [Color(red: 0.78, green: 0.92, blue: 0.86), Color(red: 0.22, green: 0.36, blue: 0.88)],
        [Color(red: 0.92, green: 0.21, blue: 0.18), Color(red: 0.78, green: 0.92, blue: 0.86)]
    ]

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, colors in
                DemoPlaceholderTile(colors: colors)
            }
        }
        .opacity(phase == .expanded ? 0 : 1)
        .offset(y: phase == .expanded ? 220 : 0)
        .scaleEffect(phase == .detail ? 0.92 : 1)
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: phase)
    }
}

private struct DemoPlaceholderTile: View {
    let colors: [Color]

    var body: some View {
        VStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(height: 128)
                .overlay {
                    DemoBars(color: .black.opacity(0.46), scale: 0.72)
                        .padding(.horizontal, 16)
                }

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(.black.opacity(0.12))
                .frame(width: 62, height: 5)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 6)
    }
}

private struct DemoFocusControls: View {
    let isVisible: Bool
    let commit: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            Circle()
                .fill(Color.white.opacity(0.48))
                .frame(width: 34, height: 34)

            Button(action: commit) {
                Circle()
                    .fill(Color(red: 0.95, green: 0.76, blue: 0.28))
                    .frame(width: 74, height: 74)
                    .overlay(Circle().stroke(.black.opacity(0.32), lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dynamic-notch-commit")

            Circle()
                .stroke(.black.opacity(0.46), lineWidth: 2)
                .frame(width: 34, height: 34)
        }
        .padding(.horizontal, 28)
        .frame(height: 100)
        .background(.white.opacity(0.18), in: Capsule())
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.82)
        .allowsHitTesting(isVisible)
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: isVisible)
    }
}

private struct DemoPrimaryControls: View {
    let phase: DynamicNotchRevealPhase
    let expand: () -> Void
    let commit: () -> Void
    let reset: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if phase == .expanded {
                Button(action: reset) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.16), in: Circle())
                .foregroundStyle(.white)
                .accessibilityLabel("Close dynamic notch")

                Spacer()
            }

            Button(action: primaryAction) {
                Label(primaryTitle, systemImage: primaryIcon)
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: phase == .expanded ? 170 : .infinity)
                    .frame(height: 54)
            }
            .buttonStyle(.plain)
            .background(primaryBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(primaryForeground)
            .disabled(phase == .ejecting)
            .opacity(phase == .ejecting ? 0.45 : 1)
            .accessibilityIdentifier("dynamic-notch-primary-action")
        }
    }

    private var primaryTitle: String {
        switch phase {
        case .idle:
            return "Run Motion"
        case .expanded:
            return "Commit"
        case .ejecting:
            return "Ejecting"
        case .landed:
            return "Replay"
        case .detail:
            return "Reset"
        }
    }

    private var primaryIcon: String {
        switch phase {
        case .idle:
            return "play.fill"
        case .expanded:
            return "circle.inset.filled"
        case .ejecting:
            return "rectangle.portrait.and.arrow.forward"
        case .landed, .detail:
            return "arrow.counterclockwise"
        }
    }

    private var primaryBackground: Color {
        phase == .idle || phase == .expanded ? Color(red: 0.95, green: 0.76, blue: 0.28) : .white.opacity(0.14)
    }

    private var primaryForeground: Color {
        phase == .idle || phase == .expanded ? .black : .white
    }

    private func primaryAction() {
        switch phase {
        case .idle:
            expand()
        case .expanded:
            commit()
        case .landed, .detail:
            reset()
        case .ejecting:
            break
        }
    }
}

private struct DemoResultCard: View {
    let item: DynamicNotchRevealItem
    let namespace: Namespace.ID
    let mode: DynamicNotchResultMode

    var body: some View {
        VStack(alignment: .leading, spacing: mode == .expanded ? 18 : 12) {
            RoundedRectangle(cornerRadius: mode == .expanded ? 20 : 14, style: .continuous)
                .fill(cardGradient)
                .frame(height: mode == .expanded ? 280 : 176)
                .overlay {
                    DemoBars(color: .black.opacity(0.58), scale: mode == .expanded ? 1.18 : 0.92)
                        .padding(.horizontal, mode == .expanded ? 28 : 18)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: mode == .expanded ? 32 : 23, weight: .black, design: .rounded))
                    .foregroundStyle(.black)

                Text(item.subtitle)
                    .font(mode == .expanded ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.58))
            }

            if mode == .expanded {
                Text("Reusable placeholder. Replace this card with the real app content later.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.black.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(mode == .expanded ? 22 : 14)
        .frame(width: mode == .expanded ? 336 : 208)
        .background(.white, in: RoundedRectangle(cornerRadius: mode == .expanded ? 30 : 16, style: .continuous))
        .matchedGeometryEffect(id: "dynamic-notch-result-card", in: namespace)
    }

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.78, green: 0.92, blue: 0.86),
                Color(red: 0.95, green: 0.75, blue: 0.28),
                Color(red: 0.9, green: 0.22, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct DemoDetailOverlay: View {
    let item: DynamicNotchRevealItem
    let namespace: Namespace.ID
    let close: () -> Void
    let reset: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.58))
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            VStack(spacing: 18) {
                HStack {
                    DemoCircleButton(systemName: "xmark", action: close, label: "Close detail")

                    Spacer()

                    DemoCircleButton(systemName: "arrow.counterclockwise", action: reset, label: "Reset")
                }
                .padding(.horizontal, 2)

                DemoResultCard(item: item, namespace: namespace, mode: .expanded)
                    .shadow(color: .black.opacity(0.36), radius: 30, x: 0, y: 18)
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct DemoCircleButton: View {
    let systemName: String
    let action: () -> Void
    let label: String

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.14), in: Circle())
        .accessibilityLabel(label)
    }
}

private struct DemoBars: View {
    let color: Color
    let scale: CGFloat

    private let bars: [CGFloat] = [0.28, 0.64, 0.42, 0.86, 0.52, 0.72, 0.36, 0.94, 0.48, 0.78, 0.32, 0.58]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, height in
                Capsule()
                    .fill(color)
                    .frame(width: 5 * scale, height: max(10, 58 * height * scale))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Dynamic Notch Reveal") {
    DynamicNotchRevealDemoView()
}
