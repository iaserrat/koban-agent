import Foundation

/// Builds package metadata collectors.
enum PackageCollectorFactory {
    static func javascriptCollectors(_ configuration: KobanConfiguration) -> [any SurfaceCollector] {
        guard configuration.javascript.enabled else { return [] }
        return [
            JavaScriptPackageCollector(
                discoverer: PackageCollectorPaths.javascriptDiscoverer(configuration)
            )
        ]
    }

    static func pythonCollectors(_ configuration: KobanConfiguration) -> [any SurfaceCollector] {
        guard configuration.python.enabled else { return [] }
        return [
            PythonPackageCollector(discoverer: PackageCollectorPaths.pythonDiscoverer(configuration))
        ]
    }
}
