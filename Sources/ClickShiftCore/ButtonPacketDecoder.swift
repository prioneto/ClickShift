import Foundation

public enum ClickButton: String, CaseIterable, Sendable {
    case left
    case up
    case right
    case down
    case a
    case b
    case y
    case z
    case minus
    case plus
}

/// Decodes the unencrypted controller-state packets used by current Zwift Click v2 firmware.
/// A cleared bit means the corresponding button is held.
public enum ButtonPacketDecoder {
    private static let buttonBits: [ClickButton: (byte: Int, bit: UInt8)] = [
        .left: (0, 0),
        .up: (0, 1),
        .right: (0, 2),
        .down: (0, 3),
        .a: (0, 4),
        .b: (0, 5),
        .y: (0, 6),
        .z: (1, 0),
        .minus: (1, 1),
        .plus: (1, 5),
    ]

    public static func decode(_ data: Data) -> Set<ClickButton>? {
        let bytes = [UInt8](data)
        guard bytes.count >= 7, bytes[0] == 0x23, bytes[1] == 0x08 else {
            return nil
        }

        var pressed = Set<ClickButton>()
        for (button, location) in buttonBits {
            let maskByte = bytes[2 + location.byte]
            if maskByte & (1 << location.bit) == 0 {
                pressed.insert(button)
            }
        }
        return pressed
    }
}
