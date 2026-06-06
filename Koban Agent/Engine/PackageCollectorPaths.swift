import Foundation

/// Builds project discoverers for package metadata collectors.
enum PackageCollectorPaths {
    static func javascriptDiscoverer(_ configuration: KobanConfiguration) -> ProjectFileDiscoverer {
        let settings = configuration.javascript
        return ProjectFileDiscoverer(
            roots: settings.projectRoots ?? configuration.watch.projectDiscovery.roots,
            includeFileNames: javascriptFileNames(settings),
            includeFileGlobs: [],
            excludeDirectoryNames: settings.excludeDirectories
                ?? configuration.watch.projectDiscovery.excludeDirectories,
            maxDepth: settings.maxDepth ?? configuration.watch.projectDiscovery.maxDepth
        )
    }

    static func pythonDiscoverer(_ configuration: KobanConfiguration) -> ProjectFileDiscoverer {
        let settings = configuration.python
        return ProjectFileDiscoverer(
            roots: settings.projectRoots ?? configuration.watch.projectDiscovery.roots,
            includeFileNames: pythonFileNames(settings),
            includeFileGlobs: settings.includeRequirements ? settings.requirementFileGlobs : [],
            excludeDirectoryNames: settings.excludeDirectories
                ?? configuration.watch.projectDiscovery.excludeDirectories,
            maxDepth: settings.maxDepth ?? configuration.watch.projectDiscovery.maxDepth
        )
    }

    private static func javascriptFileNames(_ settings: JavaScriptPackageSettings) -> [String] {
        settings.lockfileNames.filter { name in
            switch name {
            case PackageMetadataNames.packageLockName, PackageMetadataNames.npmShrinkwrapName:
                settings.includeNpm
            case PackageMetadataNames.pnpmLockName:
                settings.includePnpm
            case PackageMetadataNames.yarnLockName:
                settings.includeYarn
            case PackageMetadataNames.bunLockName:
                settings.includeBun
            default:
                false
            }
        }
    }

    private static func pythonFileNames(_ settings: PythonPackageSettings) -> [String] {
        var names: [String] = []
        if settings.includeUV {
            names.append(PackageMetadataNames.uvLockName)
        }
        if settings.includePyProject {
            names.append(PackageMetadataNames.pyprojectName)
        }
        if settings.includePylock {
            names.append(PackageMetadataNames.pylockName)
        }
        return names
    }
}
