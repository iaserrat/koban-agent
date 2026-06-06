import Foundation
import Testing
@testable import Koban_Agent

// MARK: - CertificatePEMDecoderTests

struct CertificatePEMDecoderTests {
    private static let certificateDER = Data([0x30, 0x03, 0x02, 0x01, 0x05])
    private static let certificateBase64 = certificateDER.base64EncodedString()

    @Test
    func stripsPEMArmorAndWhitespace() throws {
        let pem = """
        \(SensorProtocolConstants.certificatePEMBegin)
        \(Self.certificateBase64)
        \(SensorProtocolConstants.certificatePEMEnd)
        """

        let decoded = try #require(CertificatePEMDecoder.certificateDER(from: Data(pem.utf8)))

        #expect(decoded == Self.certificateDER)
    }

    @Test
    func keepsDERCertificateDataUnchanged() throws {
        let decoded = try #require(CertificatePEMDecoder.certificateDER(from: Self.certificateDER))

        #expect(decoded == Self.certificateDER)
    }
}
