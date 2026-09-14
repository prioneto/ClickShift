import XCTest
@testable import ClickShiftCore

final class ButtonPacketDecoderTests: XCTestCase {
    func testReleasedPacketHasNoButtons() {
        let packet = Data([0x23, 0x08, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F])
        XCTAssertEqual(ButtonPacketDecoder.decode(packet), [])
    }

    func testRightSideBButton() {
        let packet = Data([0x23, 0x08, 0xDF, 0xFF, 0xFF, 0xFF, 0x0F])
        XCTAssertEqual(ButtonPacketDecoder.decode(packet), [.b])
    }

    func testRightSidePlusButton() {
        let packet = Data([0x23, 0x08, 0xFF, 0xDF, 0xFF, 0xFF, 0x0F])
        XCTAssertEqual(ButtonPacketDecoder.decode(packet), [.plus])
    }

    func testBothShiftButtonsCanBeHeld() {
        let packet = Data([0x23, 0x08, 0xDF, 0xDF, 0xFF, 0xFF, 0x0F])
        XCTAssertEqual(ButtonPacketDecoder.decode(packet), [.b, .plus])
    }

    func testIgnoresUnrelatedPackets() {
        XCTAssertNil(ButtonPacketDecoder.decode(Data([0x19, 0x00])))
    }
}
