import XCTest
@testable import ClickShiftCore

final class ZwiftAdvertisementTests: XCTestCase {
    func testRecognizesRightClickWithCompanyIdentifier() {
        XCTAssertEqual(
            ZwiftAdvertisement.clickSide(from: Data([0x4A, 0x09, 0x0A, 0x01])),
            .right
        )
    }

    func testRecognizesLeftClickWithCompanyIdentifier() {
        XCTAssertEqual(
            ZwiftAdvertisement.clickSide(from: Data([0x4A, 0x09, 0x0B, 0x01])),
            .left
        )
    }

    func testAcceptsPayloadOnlyData() {
        XCTAssertEqual(ZwiftAdvertisement.clickSide(from: Data([0x0A])), .right)
    }

    func testUnknownDataIsNotMistakenForRightClick() {
        XCTAssertEqual(ZwiftAdvertisement.clickSide(from: Data([0x4C, 0x00, 0x0A])), .unknown)
        XCTAssertEqual(ZwiftAdvertisement.clickSide(from: nil), .unknown)
    }
}
