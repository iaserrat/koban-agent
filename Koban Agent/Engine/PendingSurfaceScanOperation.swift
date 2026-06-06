struct PendingSurfaceScanOperation {
    let run: @Sendable () async -> Void
    let discard: @Sendable () -> Void

    init(
        run: @escaping @Sendable () async -> Void,
        discard: @escaping @Sendable () -> Void = {}
    ) {
        self.run = run
        self.discard = discard
    }
}
