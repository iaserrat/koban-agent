import Foundation
import Testing
@testable import Koban_Agent

// MARK: - PublicKeyPEMEncoderTests

struct PublicKeyPEMEncoderTests {
    private static let p256UncompressedPublicKeyLength = 65
    private static let p256UncompressedPublicKeyPrefix: UInt8 = 0x04
    private static let publicKeyByte: UInt8 = 0x7A

    @Test
    func encodesX963P256PublicKeyAsSubjectPublicKeyInfoPEM() throws {
        let x963PublicKey = Data(
            [Self.p256UncompressedPublicKeyPrefix]
                + Array(repeating: Self.publicKeyByte, count: Self.p256UncompressedPublicKeyLength - 1)
        )

        let pemData = try PublicKeyPEMEncoder.encode(x963PublicKey: x963PublicKey)
        let pem = try #require(String(data: pemData, encoding: .utf8))
        let lines = pem.components(separatedBy: SensorProtocolConstants.newline)

        #expect(lines.first == SensorProtocolConstants.publicKeyPEMBegin)
        #expect(lines.last == SensorProtocolConstants.publicKeyPEMEnd)
        #expect(lines.dropFirst().dropLast().allSatisfy { $0.count <= SensorProtocolConstants.pemLineLength })

        let body = lines.dropFirst().dropLast().joined()
        let der = try #require(Data(base64Encoded: body))
        let prefix =
            try #require(Data(base64Encoded: SensorProtocolConstants.p256SubjectPublicKeyInfoPrefixBase64))

        #expect(der == prefix + x963PublicKey)
    }
}
