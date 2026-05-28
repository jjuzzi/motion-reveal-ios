import Foundation

enum DynamicNotchRevealPhase: String, CaseIterable, Equatable {
    case idle
    case expanded
    case ejecting
    case landed
    case detail
}

struct DynamicNotchRevealItem: Equatable, Identifiable {
    let id: UUID
    let title: String
    let subtitle: String

    static let placeholder = DynamicNotchRevealItem(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        title: "Result",
        subtitle: "Placeholder payload"
    )
}

struct DynamicNotchRevealFlow: Equatable {
    private(set) var phase: DynamicNotchRevealPhase = .idle
    private(set) var selectedItem: DynamicNotchRevealItem?

    var canExpand: Bool {
        phase == .idle || phase == .landed
    }

    var showsResultCard: Bool {
        phase == .ejecting || phase == .landed || phase == .detail
    }

    var resultHasLanded: Bool {
        phase == .landed || phase == .detail
    }

    mutating func expand() {
        guard canExpand else { return }
        phase = .expanded
    }

    mutating func commit(with item: DynamicNotchRevealItem = .placeholder) {
        guard phase == .expanded else { return }
        selectedItem = item
        phase = .ejecting
    }

    mutating func settleResult() {
        guard selectedItem != nil else { return }
        phase = .landed
    }

    mutating func openDetail() {
        guard selectedItem != nil else { return }
        phase = .detail
    }

    mutating func reset() {
        selectedItem = nil
        phase = .idle
    }
}
