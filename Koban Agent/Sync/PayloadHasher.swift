import CryptoKit
import Foundation

// MARK: - PayloadHasher

enum PayloadHasher {
    static func sha256Hex(_ payload: Data) -> String {
        SHA256.hash(data: payload)
            .map { byte in
                leftPadded(
                    String(
                        byte,
                        radix: SensorProtocolConstants.payloadHashRadix
                    ),
                    to: SensorProtocolConstants.payloadHashByteWidth,
                    with: "0"
                )
            }
            .joined()
    }

    private static func leftPadded(_ value: String, to width: Int, with character: Character) -> String {
        guard value.count < width else { return value }
        return String(repeating: String(character), count: width - value.count) + value
    }
}
