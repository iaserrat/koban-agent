import Foundation

enum SensorEventPayloadEncoder {
    static func inventoryItemPayload(_ item: InventoryItem) -> Data {
        var payload = ProtobufWireEncoder()
        payload.appendUInt32(
            field: SensorEventPayloadFields.payloadVersion,
            value: UInt32(SensorProtocolConstants.schemaVersion)
        )
        payload.appendMessage(field: SensorEventPayloadFields.inventoryItem, value: inventoryItem(item))
        return payload.data
    }

    static func findingPayload(_ finding: Finding) -> Data {
        var payload = ProtobufWireEncoder()
        payload.appendUInt32(
            field: SensorEventPayloadFields.payloadVersion,
            value: UInt32(SensorProtocolConstants.schemaVersion)
        )
        payload.appendMessage(field: SensorEventPayloadFields.finding, value: findingMessage(finding))
        return payload.data
    }

    private static func inventoryItem(_ item: InventoryItem) -> Data {
        var payload = ProtobufWireEncoder()
        payload.appendString(field: InventoryItemPayloadFields.itemID, value: item.id)
        payload.appendString(field: InventoryItemPayloadFields.surface, value: item.surface.rawValue)
        payload.appendString(field: InventoryItemPayloadFields.kind, value: item.kind.rawValue)
        payload.appendString(field: InventoryItemPayloadFields.name, value: item.name)
        payload.appendString(field: InventoryItemPayloadFields.version, value: item.version)
        payload.appendString(field: InventoryItemPayloadFields.path, value: item.path)
        payload.appendMessage(
            field: InventoryItemPayloadFields.provenance,
            value: provenance(item.provenance)
        )
        return payload.data
    }

    private static func provenance(_ provenance: Provenance) -> Data {
        var payload = ProtobufWireEncoder()
        payload.appendString(field: ProvenancePayloadFields.origin, value: provenance.origin)
        if let installedOnRequest = provenance.installedOnRequest {
            payload.appendBool(field: ProvenancePayloadFields.installedOnRequest, value: installedOnRequest)
        }
        payload.appendString(field: ProvenancePayloadFields.detail, value: provenance.detail)
        return payload.data
    }

    private static func findingMessage(_ finding: Finding) -> Data {
        var payload = ProtobufWireEncoder()
        payload.appendString(field: FindingPayloadFields.id, value: finding.id.uuidString)
        payload.appendString(field: FindingPayloadFields.surface, value: finding.surface.rawValue)
        payload.appendString(field: FindingPayloadFields.itemID, value: finding.itemID)
        payload.appendString(field: FindingPayloadFields.ruleID, value: finding.ruleID)
        payload.appendString(field: FindingPayloadFields.title, value: finding.title)
        payload.appendString(field: FindingPayloadFields.rationale, value: finding.rationale)
        payload.appendString(field: FindingPayloadFields.severity, value: finding.severity.rawValue)
        payload.appendString(field: FindingPayloadFields.itemName, value: finding.itemName)
        payload.appendMessage(field: FindingPayloadFields.evidence, value: evidence(finding.evidence))
        payload.appendString(
            field: FindingPayloadFields.observedAt,
            value: ProtocolTimestampFormatter.string(from: finding.timestamp)
        )
        return payload.data
    }

    private static func evidence(_ evidence: FindingEvidence) -> Data {
        var payload = ProtobufWireEncoder()
        payload.appendString(field: FindingEvidencePayloadFields.path, value: evidence.path)
        payload.appendString(field: FindingEvidencePayloadFields.detail, value: evidence.detail)
        payload.appendString(field: FindingEvidencePayloadFields.matchedField, value: evidence.matchedField)
        payload.appendString(field: FindingEvidencePayloadFields.matchedValue, value: evidence.matchedValue)
        return payload.data
    }
}
