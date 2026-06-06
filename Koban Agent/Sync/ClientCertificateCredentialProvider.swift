import Foundation

protocol ClientCertificateCredentialProvider {
    func credential(certificateData: Data) -> URLCredential?
}
