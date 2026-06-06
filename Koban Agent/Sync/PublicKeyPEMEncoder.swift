import Foundation

enum PublicKeyPEMEncoder {
    static func encode(x963PublicKey: Data) throws -> Data {
        guard let prefix = Data(base64Encoded: SensorProtocolConstants.p256SubjectPublicKeyInfoPrefixBase64)
        else {
            throw EnrollmentIdentityError.invalidPublicKeyPrefix
        }
        let der = prefix + x963PublicKey
        let base64 = der.base64EncodedString()
        var lines = [SensorProtocolConstants.publicKeyPEMBegin]
        var index = base64.startIndex
        while index < base64.endIndex {
            let next = base64.index(
                index,
                offsetBy: SensorProtocolConstants.pemLineLength,
                limitedBy: base64.endIndex
            ) ?? base64.endIndex
            lines.append(String(base64[index ..< next]))
            index = next
        }
        lines.append(SensorProtocolConstants.publicKeyPEMEnd)
        return Data(lines.joined(separator: SensorProtocolConstants.newline).utf8)
    }
}
