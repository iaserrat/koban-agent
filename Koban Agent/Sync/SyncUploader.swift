import Foundation

// MARK: - SyncUploader

struct SyncUploader {
    private let store: SyncOutboxStore
    private let client: SyncHTTPClient
    private let requestFactory: SyncRequestFactory
    private let stateStore: EnrollmentStateStore
    private let host: HostIdentityProvider

    init(
        store: SyncOutboxStore,
        client: SyncHTTPClient = SyncHTTPClient(),
        requestFactory: SyncRequestFactory = SyncRequestFactory(),
        stateStore: EnrollmentStateStore = EnrollmentStateStore(),
        host: HostIdentityProvider = .live
    ) {
        self.store = store
        self.client = client
        self.requestFactory = requestFactory
        self.stateStore = stateStore
        self.host = host
    }

    func uploadOnce(settings: SyncSettings, now: Date) async throws -> SyncUploadResult {
        guard settings.enabled, let tenantID = settings.tenantID, let deviceID = settings.deviceID else {
            return .empty
        }

        let pending = try store.pending(limit: settings.maxBatchEvents, now: now)
        let batch = batchWithinByteLimit(pending, maxBatchBytes: settings.maxBatchBytes)
        guard batch.isEmpty == false else {
            return try await checkIn(
                settings: settings,
                tenantID: tenantID,
                deviceID: deviceID
            )
        }

        let localSequences = batch.map(\.localSequence)
        try store.markInFlight(localSequences: localSequences, at: now)

        let request = try requestFactory.request(
            settings: settings,
            deviceID: deviceID,
            events: batch,
            lastAckedLocalSequence: store.lastAckedLocalSequence(deviceID: deviceID),
            backlog: store.backlog(deviceID: deviceID)
        )

        do {
            let response = try await client.upload(request, settings: settings)
            return try apply(response: response, to: batch, settings: settings, now: now)
        } catch {
            try retry(batch, settings: settings, now: now, retryAfterSeconds: 0)
            throw error
        }
    }
}

extension SyncUploader {
    private func checkIn(
        settings: SyncSettings,
        tenantID: String,
        deviceID: String
    ) async throws -> SyncUploadResult {
        let state = try stateStore.load()
        let response = try await client.checkIn(
            CheckInRequest(
                tenantID: tenantID,
                deviceID: deviceID,
                sensorVersion: SensorProtocolConstants.sensorVersion,
                osVersion: host.osVersion(),
                activeConfigGeneration: state?.configGeneration ?? "",
                health: health(deviceID: deviceID)
            ),
            settings: settings
        )
        if response.configUpdateAvailable == false, var state {
            state.configGeneration = response.configGeneration
            try stateStore.save(state)
        }
        return SyncUploadResult(
            uploadedEventCount: 0,
            acceptedEventCount: 0,
            rejectedEventCount: 0,
            retryEventCount: 0,
            configUpdateAvailable: response.configUpdateAvailable,
            fullResnapshotRequested: response.fullResnapshotRequested
        )
    }

    private func apply(
        response: SyncResponse,
        to batch: [SyncOutboxEvent],
        settings: SyncSettings,
        now: Date
    ) throws -> SyncUploadResult {
        if let deviceID = settings.deviceID {
            try store.markAcked(
                deviceID: deviceID,
                through: response.acceptedThroughLocalSequence,
                at: now
            )
        }
        try store.markAcked(
            localSequences: response.acceptedEvents.map(\.localSequence),
            at: now
        )
        try store.markPoison(
            localSequences: response.rejectedEvents.map(\.localSequence),
            at: now
        )

        let completedSequences = Set(
            batch
                .map(\.localSequence)
                .filter { $0 <= response.acceptedThroughLocalSequence }
        )
        .union(response.acceptedEvents.map(\.localSequence))
        .union(response.rejectedEvents.map(\.localSequence))

        let retryBatch = batch.filter { completedSequences.contains($0.localSequence) == false }
        try retry(
            retryBatch,
            settings: settings,
            now: now,
            retryAfterSeconds: response.retryAfterSeconds
        )

        return SyncUploadResult(
            uploadedEventCount: batch.count,
            acceptedEventCount: completedSequences.count - response.rejectedEvents.count,
            rejectedEventCount: response.rejectedEvents.count,
            retryEventCount: retryBatch.count,
            configUpdateAvailable: response.configUpdateAvailable,
            fullResnapshotRequested: response.fullResnapshotRequested
        )
    }

    private func health(deviceID: String) throws -> SensorHealthRequest {
        let backlog = try store.backlog(deviceID: deviceID)
        return SensorHealthRequest(
            syncBacklogEvents: backlog.eventCount,
            syncBacklogBytes: backlog.byteCount
        )
    }

    private func retry(
        _ batch: [SyncOutboxEvent],
        settings: SyncSettings,
        now: Date,
        retryAfterSeconds: UInt32
    ) throws {
        guard batch.isEmpty == false else { return }
        let nextAttemptAt = now.addingTimeInterval(
            TimeInterval(retryDelaySeconds(
                for: batch,
                settings: settings,
                retryAfterSeconds: retryAfterSeconds
            ))
        )
        try store.scheduleRetry(
            localSequences: batch.map(\.localSequence),
            nextAttemptAt: nextAttemptAt,
            at: now
        )
    }

    private func retryDelaySeconds(
        for batch: [SyncOutboxEvent],
        settings: SyncSettings,
        retryAfterSeconds: UInt32
    ) -> Int {
        if retryAfterSeconds > 0 {
            return min(Int(retryAfterSeconds), settings.retryMaxSeconds)
        }

        let highestAttemptCount = batch.map(\.attemptCount).max() ?? 0
        let multiplied = (0 ..< highestAttemptCount).reduce(settings.retryBaseSeconds) { seconds, _ in
            min(
                seconds * ConfigurationDefaults.syncRetryBackoffMultiplier,
                settings.retryMaxSeconds
            )
        }
        return min(multiplied, settings.retryMaxSeconds)
    }

    private func batchWithinByteLimit(
        _ events: [SyncOutboxEvent],
        maxBatchBytes: Int
    ) -> [SyncOutboxEvent] {
        var selected: [SyncOutboxEvent] = []
        var byteCount = 0
        for event in events {
            let nextByteCount = byteCount + event.payload.count
            guard selected.isEmpty || nextByteCount <= maxBatchBytes else {
                break
            }
            selected.append(event)
            byteCount = nextByteCount
        }
        return selected
    }
}
