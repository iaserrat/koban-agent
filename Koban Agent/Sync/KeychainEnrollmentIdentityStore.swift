import Foundation
import Security

struct KeychainEnrollmentIdentityStore: EnrollmentIdentityStore {
    func publicKeyPEM() throws -> Data {
        let key = try privateKey()
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            throw EnrollmentIdentityError.publicKeyUnavailable
        }
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw EnrollmentIdentityError.publicKeyExportFailed
        }
        return try PublicKeyPEMEncoder.encode(x963PublicKey: publicKeyData)
    }

    func identity(certificateData: Data) -> SecIdentity? {
        guard let certificateDER = CertificatePEMDecoder.certificateDER(from: certificateData),
              let certificate = SecCertificateCreateWithData(nil, certificateDER as CFData)
        else {
            return nil
        }
        var identity: SecIdentity?
        let status = SecIdentityCreateWithCertificate(nil, certificate, &identity)
        guard status == errSecSuccess else { return nil }
        return identity
    }

    private func privateKey() throws -> SecKey {
        if let key = try existingPrivateKey() {
            return key
        }
        return try createPrivateKey()
    }

    private func existingPrivateKey() throws -> SecKey? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(privateKeyLookupQuery() as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw EnrollmentIdentityError.keyLookupFailed(status)
        }
        guard let item else {
            throw EnrollmentIdentityError.publicKeyUnavailable
        }
        return unsafeDowncast(item, to: SecKey.self)
    }

    private func createPrivateKey() throws -> SecKey {
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(privateKeyCreateAttributes() as CFDictionary, &error) else {
            throw EnrollmentIdentityError.keyCreationFailed
        }
        return key
    }

    private func privateKeyLookupQuery() -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keyTagData(),
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecReturnRef: true
        ]
    }

    private func privateKeyCreateAttributes() -> [CFString: Any] {
        [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: SensorProtocolConstants.keychainKeySizeBits,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: keyTagData(),
                kSecAttrLabel: SensorProtocolConstants.keychainPrivateKeyLabel,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
        ]
    }

    private func keyTagData() -> Data {
        Data(SensorProtocolConstants.keychainPrivateKeyTag.utf8)
    }
}
