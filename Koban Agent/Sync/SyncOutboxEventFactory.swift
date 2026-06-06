import Foundation

enum SyncOutboxEventFactory {
    static func inventoryEvent(
        metadata: SyncOutboxEventMetadata,
        item: InventoryItem
    ) -> SyncOutboxEvent {
        event(metadata: metadata, payload: SensorEventPayloadEncoder.inventoryItemPayload(item))
    }

    static func findingEvent(
        identity: SyncOutboxIdentity,
        finding: Finding,
        localSequence: Int64,
        collectedAt: Date
    ) -> SyncOutboxEvent {
        let payload = SensorEventPayloadEncoder.findingPayload(finding)
        return event(
            metadata: SyncOutboxEventMetadata(
                identity: identity,
                localSequence: localSequence,
                surface: finding.surface,
                kind: SensorProtocolConstants.findingEventKind,
                observedAt: finding.timestamp,
                collectedAt: collectedAt
            ),
            payload: payload
        )
    }

    private static func event(
        metadata: SyncOutboxEventMetadata,
        payload: Data
    ) -> SyncOutboxEvent {
        let createdAt = metadata.collectedAt
        return SyncOutboxEvent(
            id: UUID(),
            tenantID: metadata.identity.tenantID,
            deviceID: metadata.identity.deviceID,
            localSequence: metadata.localSequence,
            schemaVersion: SensorProtocolConstants.schemaVersion,
            surface: metadata.surface,
            kind: metadata.kind,
            observedAt: metadata.observedAt,
            collectedAt: metadata.collectedAt,
            payload: payload,
            payloadHash: PayloadHasher.sha256Hex(payload),
            state: .pending,
            attemptCount: 0,
            nextAttemptAt: nil,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
