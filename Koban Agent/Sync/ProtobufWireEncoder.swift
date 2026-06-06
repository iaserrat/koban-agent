import Foundation

struct ProtobufWireEncoder {
    private(set) var data = Data()

    mutating func appendUInt32(field: Int, value: UInt32) {
        appendTag(field: field, wireType: SensorProtocolConstants.protobufWireVarint)
        appendVarint(UInt64(value))
    }

    mutating func appendBool(field: Int, value: Bool) {
        appendTag(field: field, wireType: SensorProtocolConstants.protobufWireVarint)
        appendVarint(value ? 1 : 0)
    }

    mutating func appendString(field: Int, value: String?) {
        guard let value, value.isEmpty == false else { return }
        appendData(field: field, value: Data(value.utf8))
    }

    mutating func appendMessage(field: Int, value: Data?) {
        guard let value, value.isEmpty == false else { return }
        appendData(field: field, value: value)
    }

    private mutating func appendData(field: Int, value: Data) {
        appendTag(field: field, wireType: SensorProtocolConstants.protobufWireLengthDelimited)
        appendVarint(UInt64(value.count))
        data.append(value)
    }

    private mutating func appendTag(field: Int, wireType: Int) {
        appendVarint(UInt64(field << SensorProtocolConstants.protobufFieldShift | wireType))
    }

    private mutating func appendVarint(_ value: UInt64) {
        var remaining = value
        while remaining >= SensorProtocolConstants.protobufContinuationThreshold {
            data.append(UInt8(
                remaining & SensorProtocolConstants.protobufValueMask |
                    SensorProtocolConstants.protobufContinuationFlag
            ))
            remaining >>= SensorProtocolConstants.protobufVarintShift
        }
        data.append(UInt8(remaining))
    }
}
