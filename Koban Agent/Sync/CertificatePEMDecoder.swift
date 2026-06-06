import Foundation

enum CertificatePEMDecoder {
    static func certificateDER(from data: Data) -> Data? {
        guard let pem = String(data: data, encoding: .utf8) else { return data }
        guard let beginRange = pem.range(of: SensorProtocolConstants.certificatePEMBegin),
              let endRange = pem.range(of: SensorProtocolConstants.certificatePEMEnd)
        else {
            return data
        }
        let body = pem[beginRange.upperBound ..< endRange.lowerBound]
            .filter { $0.isWhitespace == false }
        return Data(base64Encoded: String(body))
    }
}
