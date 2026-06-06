enum MCPInventoryMapper {
    static func agentConfigItem(
        surface: MonitoredSurface,
        name: String,
        path: String,
        spec: MCPServerSpec
    ) -> AgentConfigItem? {
        guard let origin = spec.origin else { return nil }
        return AgentConfigItem(
            surface: surface,
            kind: .mcpServer,
            name: name,
            path: path,
            origin: origin,
            detail: spec.detail
        )
    }

    static func inventoryItem(
        surface: MonitoredSurface,
        name: String,
        path: String,
        spec: MCPServerSpec
    ) -> InventoryItem? {
        agentConfigItem(
            surface: surface,
            name: name,
            path: path,
            spec: spec
        ).map(AgentConfigInventoryMapper.inventoryItem)
    }
}
