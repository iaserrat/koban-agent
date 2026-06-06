import Foundation

extension ProcessInfo {
    var machineHardwareName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        var machine = systemInfo.machine
        let capacity = MemoryLayout.size(ofValue: machine)
        return withUnsafePointer(to: &machine) { pointer in
            pointer.withMemoryRebound(
                to: CChar.self,
                capacity: capacity
            ) {
                String(cString: $0)
            }
        }
    }
}
