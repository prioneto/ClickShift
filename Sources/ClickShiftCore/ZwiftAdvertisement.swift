import Foundation

public enum ZwiftClickSide: Equatable, Sendable {
    case left
    case right
    case unknown
}

public enum ZwiftAdvertisement {
    private static let zwiftCompanyIDLittleEndian: [UInt8] = [0x4A, 0x09]
    private static let rightSideType: UInt8 = 0x0A
    private static let leftSideType: UInt8 = 0x0B

    /// CoreBluetooth normally includes the little-endian company identifier at
    /// the beginning of manufacturer data. The payload-only form is accepted as
    /// a fallback for compatibility with other BLE stacks and captured fixtures.
    public static func clickSide(from manufacturerData: Data?) -> ZwiftClickSide {
        guard let manufacturerData, !manufacturerData.isEmpty else { return .unknown }
        let bytes = [UInt8](manufacturerData)

        let type: UInt8?
        if bytes.count >= 3 && Array(bytes.prefix(2)) == zwiftCompanyIDLittleEndian {
            type = bytes[2]
        } else if bytes[0] == rightSideType || bytes[0] == leftSideType {
            type = bytes[0]
        } else {
            type = nil
        }

        switch type {
        case rightSideType: return .right
        case leftSideType: return .left
        default: return .unknown
        }
    }
}
