import XCTest
@testable import MotionReveal

final class DynamicNotchRevealFlowTests: XCTestCase {
    func testRevealFlowMovesThroughExpectedPhases() {
        var flow = DynamicNotchRevealFlow()

        XCTAssertEqual(flow.phase, .idle)
        XCTAssertTrue(flow.canExpand)
        XCTAssertFalse(flow.showsResultCard)

        flow.expand()
        XCTAssertEqual(flow.phase, .expanded)
        XCTAssertFalse(flow.canExpand)
        XCTAssertNil(flow.selectedItem)

        flow.commit()
        XCTAssertEqual(flow.phase, .ejecting)
        XCTAssertTrue(flow.showsResultCard)
        XCTAssertFalse(flow.resultHasLanded)

        flow.settleResult()
        XCTAssertEqual(flow.phase, .landed)
        XCTAssertTrue(flow.showsResultCard)
        XCTAssertTrue(flow.resultHasLanded)
        XCTAssertEqual(flow.selectedItem, .placeholder)

        flow.openDetail()
        XCTAssertEqual(flow.phase, .detail)
        XCTAssertTrue(flow.showsResultCard)

        flow.reset()
        XCTAssertEqual(flow.phase, .idle)
        XCTAssertNil(flow.selectedItem)
    }

    func testCommitDoesNotRunBeforeExpansion() {
        var flow = DynamicNotchRevealFlow()

        flow.commit()

        XCTAssertEqual(flow.phase, .idle)
        XCTAssertNil(flow.selectedItem)
    }

    func testDetailDoesNotOpenWithoutASelectedItem() {
        var flow = DynamicNotchRevealFlow()

        flow.openDetail()

        XCTAssertEqual(flow.phase, .idle)
    }

    func testResultDoesNotSettleWithoutASelectedItem() {
        var flow = DynamicNotchRevealFlow()

        flow.settleResult()

        XCTAssertEqual(flow.phase, .idle)
        XCTAssertFalse(flow.showsResultCard)
    }
}
