import Foundation

struct HostIdentityProvider {
    var hostname: @Sendable () -> String
    var osVersion: @Sendable () -> String
    var hardwareModel: @Sendable () -> String

    static let live = Self(
        hostname: { Host.current().localizedName ?? ProcessInfo.processInfo.hostName },
        osVersion: { ProcessInfo.processInfo.operatingSystemVersionString },
        hardwareModel: { ProcessInfo.processInfo.machineHardwareName }
    )
}
