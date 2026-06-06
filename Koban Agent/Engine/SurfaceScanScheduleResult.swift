enum SurfaceScanScheduleResult: Equatable {
    case started
    case coalesced(coalescedTriggerCount: Int)
}
