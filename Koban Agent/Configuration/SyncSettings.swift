// MARK: - SyncSettings

struct SyncSettings: Codable, Hashable {
    var enabled: Bool
    var protocolName: String
    var endpoint: String?
    var enrollmentToken: String?
    var sensorToken: String?
    var tenantID: String?
    var deviceID: String?
    var maxBatchBytes: Int
    var maxBatchEvents: Int
    var checkInIntervalSeconds: Int
    var retryBaseSeconds: Int
    var retryMaxSeconds: Int
    var outboxMaxBytes: Int

    private enum CodingKeys: String, CodingKey {
        case enabled
        case protocolName = "protocol"
        case endpoint
        case enrollmentToken
        case sensorToken
        case tenantID
        case deviceID
        case maxBatchBytes
        case maxBatchEvents
        case checkInIntervalSeconds
        case retryBaseSeconds
        case retryMaxSeconds
        case outboxMaxBytes
    }

    init(
        enabled: Bool,
        protocolName: String,
        endpoint: String?,
        enrollmentToken: String?,
        sensorToken: String?,
        tenantID: String?,
        deviceID: String?,
        maxBatchBytes: Int,
        maxBatchEvents: Int,
        checkInIntervalSeconds: Int,
        retryBaseSeconds: Int,
        retryMaxSeconds: Int,
        outboxMaxBytes: Int
    ) {
        self.enabled = enabled
        self.protocolName = protocolName
        self.endpoint = endpoint
        self.enrollmentToken = enrollmentToken
        self.sensorToken = sensorToken
        self.tenantID = tenantID
        self.deviceID = deviceID
        self.maxBatchBytes = maxBatchBytes
        self.maxBatchEvents = maxBatchEvents
        self.checkInIntervalSeconds = checkInIntervalSeconds
        self.retryBaseSeconds = retryBaseSeconds
        self.retryMaxSeconds = retryMaxSeconds
        self.outboxMaxBytes = outboxMaxBytes
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.sync
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        protocolName = try container.decodeIfPresent(
            String.self,
            forKey: .protocolName
        ) ?? defaults.protocolName
        endpoint = try container.decodeIfPresent(String.self, forKey: .endpoint) ?? defaults.endpoint
        enrollmentToken = try container.decodeIfPresent(
            String.self,
            forKey: .enrollmentToken
        ) ?? defaults.enrollmentToken
        sensorToken = try container.decodeIfPresent(String.self, forKey: .sensorToken) ?? defaults.sensorToken
        tenantID = try container.decodeIfPresent(String.self, forKey: .tenantID) ?? defaults.tenantID
        deviceID = try container.decodeIfPresent(String.self, forKey: .deviceID) ?? defaults.deviceID
        maxBatchBytes = try container.decodeIfPresent(
            Int.self,
            forKey: .maxBatchBytes
        ) ?? defaults.maxBatchBytes
        maxBatchEvents = try container.decodeIfPresent(
            Int.self,
            forKey: .maxBatchEvents
        ) ?? defaults.maxBatchEvents
        checkInIntervalSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .checkInIntervalSeconds
        ) ?? defaults.checkInIntervalSeconds
        retryBaseSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .retryBaseSeconds
        ) ?? defaults.retryBaseSeconds
        retryMaxSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .retryMaxSeconds
        ) ?? defaults.retryMaxSeconds
        outboxMaxBytes = try container.decodeIfPresent(
            Int.self,
            forKey: .outboxMaxBytes
        ) ?? defaults.outboxMaxBytes
    }
}
