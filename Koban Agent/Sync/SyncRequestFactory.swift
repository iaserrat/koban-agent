import Foundation

struct SyncRequestFactory {
    func request(
        settings: SyncSettings,
        deviceID: String,
        events: [SyncOutboxEvent],
        lastAckedLocalSequence: Int64,
        backlog: SyncBacklog
    ) -> SyncRequest {
        SyncRequest(
            tenantID: settings.tenantID,
            deviceID: deviceID,
            sensorVersion: SensorProtocolConstants.sensorVersion,
            schemaVersion: SensorProtocolConstants.schemaVersion,
            lastAckedLocalSequence: lastAckedLocalSequence,
            events: events.map(eventRequest),
            health: SensorHealthRequest(
                syncBacklogEvents: backlog.eventCount,
                syncBacklogBytes: backlog.byteCount
            )
        )
    }

    private func eventRequest(from event: SyncOutboxEvent) -> SyncEventRequest {
        SyncEventRequest(
            eventID: event.id.uuidString,
            deviceID: event.deviceID,
            localSequence: event.localSequence,
            surface: event.surface,
            kind: event.kind,
            observedAt: ProtocolTimestampFormatter.string(from: event.observedAt),
            collectedAt: ProtocolTimestampFormatter.string(from: event.collectedAt),
            payloadHash: event.payloadHash,
            payload: event.payload
        )
    }
}
