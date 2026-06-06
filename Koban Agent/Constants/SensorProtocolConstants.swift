import Foundation

// MARK: - SensorProtocolConstants

enum SensorProtocolConstants {
    static let protocolName = "kobanSensorV1"
    static let schemaVersion = 1
    static let sensorVersion = "koban-agent"
    static let syncRoutePath = "api/sensor/v1/sync"
    static let enrollRoutePath = "api/sensor/v1/enroll"
    static let configRoutePath = "api/sensor/v1/config"
    static let checkInRoutePath = "api/sensor/v1/check-in"
    static let enrollmentStateFileName = "sync-state.json"
    static let sensorTokenHeader = "X-Koban-Sensor-Token"
    static let contentTypeHeader = "Content-Type"
    static let applicationJSONContentType = "application/json"
    static let httpMethodPOST = "POST"
    static let successfulHTTPStatusRange = 200 ..< 300
    static let pemLineLength = 64
    static let publicKeyPEMBegin = "-----BEGIN PUBLIC KEY-----"
    static let publicKeyPEMEnd = "-----END PUBLIC KEY-----"
    static let certificatePEMBegin = "-----BEGIN CERTIFICATE-----"
    static let certificatePEMEnd = "-----END CERTIFICATE-----"
    static let newline = "\n"
    static let p256SubjectPublicKeyInfoPrefixBase64 = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgA="
    static let keychainKeySizeBits = 256
    static let keychainPrivateKeyTag = "com.kobanhq.agent.sensor.identity.private-key"
    static let keychainPrivateKeyLabel = "Koban Sensor Identity"
    static let clientCertificateAuthenticationMethod = NSURLAuthenticationMethodClientCertificate
    static let findingEventKind = ChangeKind.modified
    static let payloadHashRadix = 16
    static let payloadHashByteWidth = 2
    static let protobufFieldShift = 3
    static let protobufWireVarint = 0
    static let protobufWireLengthDelimited = 2
    static let protobufContinuationThreshold: UInt64 = 0x80
    static let protobufValueMask: UInt64 = 0x7F
    static let protobufContinuationFlag: UInt64 = 0x80
    static let protobufVarintShift = 7
}

// MARK: - SensorEventPayloadFields

enum SensorEventPayloadFields {
    static let payloadVersion = 1
    static let inventoryItem = 2
    static let finding = 3
}

// MARK: - InventoryItemPayloadFields

enum InventoryItemPayloadFields {
    static let itemID = 1
    static let surface = 2
    static let kind = 3
    static let name = 4
    static let version = 5
    static let path = 6
    static let provenance = 7
}

// MARK: - ProvenancePayloadFields

enum ProvenancePayloadFields {
    static let origin = 1
    static let installedOnRequest = 2
    static let detail = 3
}

// MARK: - FindingPayloadFields

enum FindingPayloadFields {
    static let id = 1
    static let surface = 2
    static let itemID = 3
    static let ruleID = 4
    static let title = 5
    static let rationale = 6
    static let severity = 7
    static let itemName = 8
    static let evidence = 9
    static let observedAt = 10
}

// MARK: - FindingEvidencePayloadFields

enum FindingEvidencePayloadFields {
    static let path = 1
    static let detail = 2
    static let matchedField = 3
    static let matchedValue = 4
}
