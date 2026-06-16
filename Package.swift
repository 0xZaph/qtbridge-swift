// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport
import Foundation

// This is separated to be extracted via CMake
let swiftSyntaxVersion: Version = "600.0.0"

let useLocalQt = envVar("QTBRIDGE_USE_LOCAL_QT_PACKAGE", false)
let qtPackageName = useLocalQt ? "Qt" : "qtforswift"

#if os(Windows)
let packageCxxStandard: CXXLanguageStandard = .cxx20
#else
let packageCxxStandard: CXXLanguageStandard = .cxx17
#endif

let nonApplePlatforms: [Platform] = [.windows, .linux, .openbsd, .custom("freebsd"), .android, .wasi]

func buildSystemCxxFlags() -> [String] {
    struct Cache {
        static let flags: [String] = {
            let qtIncludes = getQtIncludePaths()
            if qtIncludes.isEmpty { return [] }
            var flags = qtIncludes.map { "-I\($0)" }
            if let swiftInclude = getSwiftBridgingIncludePath() {
                print("Swift bridging include path: \(swiftInclude)")
                flags.append("-I\(swiftInclude)")
            }
            return flags
        }()
    }
    return Cache.flags
}

func buildSystemSwiftFlags() -> [String] {
    struct Cache {
        static let flags: [String] = {
            let qtIncludes = getQtIncludePaths()
            if qtIncludes.isEmpty { return [] }
            var flags = qtIncludes.flatMap { ["-Xcc", "-I\($0)"] }
            if let swiftInclude = getSwiftBridgingIncludePath() {
                flags.append(contentsOf: ["-Xcc", "-I\(swiftInclude)"])
            }
            return flags
        }()
    }
    return Cache.flags
}

func buildSystemLinkerSettings() -> [LinkerSetting] {
    struct Cache {
        static let settings: [LinkerSetting] = {
            let libPath = getQtLibPath()
            if libPath.isEmpty { return [] }
            return [
                .unsafeFlags(["-L\(libPath)"], .when(platforms: nonApplePlatforms)),
                .linkedLibrary("Qt6Core", .when(platforms: nonApplePlatforms)),
                .linkedLibrary("Qt6Qml", .when(platforms: nonApplePlatforms)),
                .linkedLibrary("Qt6Gui", .when(platforms: nonApplePlatforms)),
                .linkedLibrary("Qt6Quick", .when(platforms: nonApplePlatforms)),
                .linkedLibrary("Qt6Test", .when(platforms: nonApplePlatforms)),
                .linkedLibrary("Qt6QuickTest", .when(platforms: nonApplePlatforms))
            ]
        }()
    }
    return Cache.settings
}

let package = Package(
    name: "QtBridge",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "QtBridge", targets: ["QtBridge"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: swiftSyntaxVersion),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
        useLocalQt ? .package(path: "../Qt")
                   : .package(url: "https://git.qt.io/qtbridge/qtforswift.git", branch: "master")
    ],
    targets: [
        .macro(
            name: "QtBridgeMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            exclude: ["CMakeLists.txt"]
        ),
        .target(
            name: "QtBridgeCpp",
            dependencies: [
                .product(name: "QtCore", package: qtPackageName, condition: .when(platforms: [.macOS])),
                .product(name: "QtCorePrivate", package: qtPackageName, condition: .when(platforms: [.macOS])),
                .product(name: "QtQml", package: qtPackageName, condition: .when(platforms: [.macOS])),
                .product(name: "QtGui", package: qtPackageName, condition: .when(platforms: [.macOS])),
                .product(name: "QtTest", package: qtPackageName, condition: .when(platforms: [.macOS]))
            ],
            exclude: ["CMakeLists.txt"],
            cxxSettings: [
                .unsafeFlags(buildSystemCxxFlags(), .when(platforms: nonApplePlatforms))
            ],
            swiftSettings: [
                .unsafeFlags(buildSystemSwiftFlags(), .when(platforms: nonApplePlatforms))
            ],
            linkerSettings: buildSystemLinkerSettings()
        ),
        .target(
            name: "_CQtEventLoop",
            dependencies: [
                .product(name: "QtCore", package: qtPackageName, condition: .when(platforms: [.macOS]))
            ],
            exclude: ["CMakeLists.txt"],
            cxxSettings: [
                .unsafeFlags(buildSystemCxxFlags(), .when(platforms: nonApplePlatforms))
            ],
            linkerSettings: buildSystemLinkerSettings()
        ),
        .target(
            name: "QtEventLoop",
            dependencies: ["_CQtEventLoop"],
            exclude: ["CMakeLists.txt"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .target(
            name: "QtBridge",
            dependencies: [
                "QtEventLoop",
                "QtBridgeCpp",
                "QtBridgeMacros",
                .product(name: "QtCore", package: qtPackageName, condition: .when(platforms: [.macOS])),
                .product(name: "QtQml", package: qtPackageName, condition: .when(platforms: [.macOS])),
                .product(name: "QtGui", package: qtPackageName, condition: .when(platforms: [.macOS])),
                .product(name: "QmlImports", package: qtPackageName, condition: .when(platforms: [.macOS]))
            ],
            exclude: ["CMakeLists.txt"],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .define("QT_IS_SYSTEM_PACKAGE", .when(platforms: nonApplePlatforms)),
                .define("QT_IS_CXX_20", .when(platforms: [.windows]))
            ]
        ),
        .testTarget(
            name: "QtBridgeXCTests",
            dependencies: [
                "QtBridge",
                "QtBridgeMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "QtQuickTests",
            dependencies: ["QtBridge"],
            resources: [.copy("Resources/qml")],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: packageCxxStandard
)

func envVar(_ name: String, _ def: Bool) -> Bool {
    guard let value = ProcessInfo.processInfo.environment[name]?.lowercased() else { return def }
    return ["1", "true", "yes", "on"].contains(value)
}

func runCommand(_ args: [String]) -> String? {
    let process = Process()
    #if os(Windows)
    let comspec = ProcessInfo.processInfo.environment["COMSPEC"] ?? "C:\\Windows\\System32\\cmd.exe"
    process.executableURL = URL(filePath: comspec)
    process.arguments = ["/c"] + args
    #else
    process.executableURL = URL(filePath: "/usr/bin/env")
    process.arguments = args
    #endif

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return nil
    }
}

func getQtIncludePaths() -> [String] {
    let env = ProcessInfo.processInfo.environment
    guard let base = env["QT_INSTALL_HEADERS"] ?? runCommand(["qtpaths", "--query", "QT_INSTALL_HEADERS"]) else {
        return []
    }

    guard let ver = env["QT_VERSION"] ?? runCommand(["qtpaths", "--query", "QT_VERSION"]) else {
        print("Warning: QT_VERSION not set and 'qtpaths' tool is missing. Falling back to base header include only.")
        return [base]
    }

    return [
        base,
        "\(base)/QtCore", "\(base)/QtCore/\(ver)", "\(base)/QtCore/\(ver)/QtCore",
        "\(base)/QtQml", "\(base)/QtQml/\(ver)", "\(base)/QtQml/\(ver)/QtQml",
        "\(base)/QtGui", "\(base)/QtGui/\(ver)", "\(base)/QtGui/\(ver)/QtGui"
    ]
}

func getQtLibPath() -> String {
    return ProcessInfo.processInfo.environment["QT_INSTALL_LIBS"] ?? runCommand(["qtpaths", "--query", "QT_INSTALL_LIBS"]) ?? ""
}

func getSwiftBridgingIncludePath() -> String? {
    guard let output = runCommand(["swiftc", "-print-target-info"]),
          let data = output.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let paths = json["paths"] as? [String: Any],
          let runtimeResourcePath = paths["runtimeResourcePath"] as? String else {
        return nil
    }

    let normalizedPath = runtimeResourcePath.replacingOccurrences(of: "\\", with: "/")
    guard let libRange = normalizedPath.range(of: "/lib/swift", options: .backwards) else {
        return nil
    }

    let basePath = String(runtimeResourcePath[..<libRange.lowerBound])
    let separator = runtimeResourcePath.contains("\\") ? "\\" : "/"
    return basePath + separator + "include"
}
